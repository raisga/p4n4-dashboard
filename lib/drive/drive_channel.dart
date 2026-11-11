import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'links.dart';

/// A paired Bluetooth device: an OBD-II adapter, hopefully.
typedef BondedDevice = ({String name, String address});

/// This app's own Android code (android/…/DrivePlugin.kt): the screen kept
/// on, free storage, and a Bluetooth serial link to an OBD-II adapter. Other
/// platforms have none of it: calls there do nothing.
abstract final class DriveChannel {
  static const _methods = MethodChannel('p4n4/drive');
  static const _serial = EventChannel('p4n4/drive/serial');

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    if (!supported) return null;
    try {
      return await _methods.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> keepScreenOn(bool on) => _call<bool>('keepScreenOn', on);

  /// The bytes free on the storage holding [path]; null if unknown.
  static Future<int?> freeBytes(String path) => _call<int>('freeBytes', path);

  /// Whether this phone has Bluetooth, it's on, and the app may use it.
  static Future<({bool available, bool enabled, bool permitted})> serialState() async {
    final state = await _call<Map<Object?, Object?>>('serialState') ?? const {};
    return (
      available: state['available'] == true,
      enabled: state['enabled'] == true,
      permitted: state['permitted'] == true,
    );
  }

  /// Asks for the Bluetooth permission (Android 12+); true if granted.
  static Future<bool> requestPermission() async => await _call<bool>('requestPermission') ?? false;

  static Future<List<BondedDevice>> bondedDevices() async => [
    for (final d in await _call<List<Object?>>('bondedDevices') ?? const [])
      if (d case {'name': final String name, 'address': final String address}) (name: name, address: address),
  ];

  /// Ends a Bluetooth connect still under way.
  static Future<void> cancelSerial() => _call<void>('disconnect');

  /// One stream for every link: a native listen per link would race the
  /// last one's cancel.
  static final _events = _serial.receiveBroadcastStream();

  /// Connects to the adapter at [address]. Throws a [PlatformException] when
  /// it can't (code `permission`, `disabled`, `connect`, …). One link at a
  /// time: opening another closes this one.
  static Future<ByteLink> openSerial(String address) async {
    if (!supported) throw PlatformException(code: 'unavailable', message: 'Bluetooth links need Android');
    final link = _SerialLink(address);
    try {
      final answer = await _methods.invokeMapMethod<String, Object?>('connect', address) ?? const {};
      link._attach(answer['name'] as String? ?? address, answer['link'] as int? ?? -1);
      return link;
    } catch (_) {
      await link._detach();
      rethrow;
    }
  }
}

class _SerialLink implements ByteLink {
  _SerialLink(this.peer) {
    _events = DriveChannel._events.listen((e) {
      if (e is Uint8List) {
        if (!_input.isClosed) _input.add(e);
      } else if (e case {'link': final int id}) {
        if (_id == null) {
          _closedEarly.add(id);
        } else if (id == _id) {
          unawaited(_detach());
        }
      }
    }, onError: (Object _) => unawaited(_detach()));
  }

  @override
  String peer;

  int? _id;

  /// Links that closed before connect answered: this one, maybe.
  final _closedEarly = <int>{};
  late final StreamSubscription<Object?> _events;
  final _input = StreamController<Uint8List>();

  void _attach(String name, int id) {
    peer = name;
    _id = id;
    if (_closedEarly.contains(id)) unawaited(_detach());
  }

  Future<void> _detach() async {
    await _events.cancel();
    if (!_input.isClosed) await _input.close();
  }

  @override
  Stream<Uint8List> get input => _input.stream;

  @override
  Future<void> write(Uint8List data) async {
    if (_input.isClosed) return;
    try {
      await DriveChannel._methods.invokeMethod<void>('write', data);
    } on PlatformException catch (e) {
      if (e.code == 'closed') await _detach();
    }
  }

  @override
  Future<void> close() async {
    if (_input.isClosed) return;
    await _detach();
    await DriveChannel._call<void>('disconnect');
  }
}

/// Keeps the screen on while anything [hold]s it: the dashcam recording, the
/// Map tab in front.
class KeepAwake {
  int _holds = 0;

  void hold() {
    if (_holds++ == 0) unawaited(DriveChannel.keepScreenOn(true));
  }

  void release() {
    if (_holds == 0) return;
    if (--_holds == 0) unawaited(DriveChannel.keepScreenOn(false));
  }
}
