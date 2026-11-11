import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/settings.dart';
import '../platform/mqtt_connect.dart' as mqtt;
import 'geo.dart';
import 'links.dart';
import 'location.dart';

/// Where publishing this phone's GPS stands.
enum PublishStatus { off, unsupported, connecting, connected, error }

typedef MqttConnector = Future<MqttLink> Function({
  required String host,
  required int port,
  required String clientId,
  String user,
  String password,
  Duration timeout,
});

/// Publishes this phone's GPS fixes to the connected deployment's MQTT
/// broker, at most once a second, while [AppSettings.gpsPublish] is on and
/// the app is open: `sensors/<driveDevice>/gps`, as [Fix.toPayload]. The
/// stack files them with the car's OBD-II readings.
class GpsPublisher extends ChangeNotifier {
  GpsPublisher(this._settings, this._location, {MqttConnector? connect, bool? supported})
    : _connect = connect ?? mqtt.connectMqtt,
      _supported = supported ?? LocationService.supported {
    _settings.addListener(_sync);
    _sync();
  }

  final AppSettings _settings;
  final LocationService _location;
  final MqttConnector _connect;
  final bool _supported;

  /// Fixes this close together are skipped.
  static const minInterval = Duration(milliseconds: 900);

  PublishStatus get status => _status;
  var _status = PublishStatus.off;

  /// Why the broker can't be reached, while [status] is [PublishStatus.error].
  String? get error => _error;
  String? _error;

  /// Fixes sent since the app opened.
  int get sent => _sent;
  int _sent = 0;

  String get topic => 'sensors/${_settings.driveDevice}/gps';

  // Different on each start, so two phones never kick each other off.
  final _clientId = 'p4n4-${_hex(4)}';

  static String _hex(int bytes) {
    final random = math.Random();
    return [for (var i = 0; i < bytes; i++) random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  ({String host, int port, String user, String password})? _config;
  int _generation = 0;
  MqttLink? _link;
  StreamSubscription<Fix>? _fixes;
  Timer? _retry;
  var _backoff = const Duration(seconds: 2);
  DateTime? _lastSent;
  bool _disposed = false;

  void _sync() {
    if (!_settings.gpsPublish) {
      _apply(null, PublishStatus.off);
    } else if (!_supported) {
      _apply(null, PublishStatus.unsupported);
    } else {
      _apply((
        host: _settings.host,
        port: _settings.mqttPort,
        user: _settings.mqttUser,
        password: _settings.mqttPassword,
      ), PublishStatus.connecting);
    }
  }

  void _apply(({String host, int port, String user, String password})? config, PublishStatus idle) {
    if (config == _config && (config != null || _status == idle)) return;
    _config = config;
    _generation++;
    _retry?.cancel();
    _link?.close();
    _link = null;
    _error = null;
    if (config == null) {
      if (_fixes != null) {
        _fixes!.cancel();
        _fixes = null;
        _location.release();
      }
      return _set(idle);
    }
    if (_fixes == null) {
      _location.acquire();
      _fixes = _location.fixes.listen(_onFix);
    }
    _backoff = const Duration(seconds: 2);
    unawaited(_open(_generation));
  }

  Future<void> _open(int generation) async {
    final config = _config!;
    _set(PublishStatus.connecting);
    try {
      final link = await _connect(
        host: config.host,
        port: config.port,
        clientId: _clientId,
        user: config.user,
        password: config.password,
        timeout: const Duration(seconds: 8),
      );
      if (generation != _generation) {
        link.close();
        return;
      }
      _link = link;
      _backoff = const Duration(seconds: 2);
      _error = null;
      _set(PublishStatus.connected);
      unawaited(
        link.done.then((_) {
          if (generation != _generation || !identical(link, _link)) return;
          _link = null;
          _retryLater(generation, 'The broker hung up');
        }),
      );
    } catch (e) {
      if (generation == _generation) _retryLater(generation, _describe(e));
    }
  }

  void _retryLater(int generation, String error) {
    _error = error;
    _set(PublishStatus.error, always: true);
    _retry = Timer(_backoff, () {
      if (generation == _generation) unawaited(_open(generation));
    });
    _backoff = _backoff * 2 > const Duration(seconds: 30) ? const Duration(seconds: 30) : _backoff * 2;
  }

  static String _describe(Object e) => switch ('$e') {
    final s when s.length > 160 => '${s.substring(0, 160)}…',
    final s => s,
  };

  void _onFix(Fix fix) {
    final link = _link;
    if (link == null) return;
    final now = DateTime.now();
    if (_lastSent case final last? when now.difference(last) < minInterval) return;
    if (!link.publish(topic, jsonEncode(fix.toPayload()))) return;
    _lastSent = now;
    _sent++;
    notifyListeners();
  }

  void _set(PublishStatus status, {bool always = false}) {
    if (_disposed || (status == _status && !always)) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settings.removeListener(_sync);
    _apply(null, PublishStatus.off);
    super.dispose();
  }
}
