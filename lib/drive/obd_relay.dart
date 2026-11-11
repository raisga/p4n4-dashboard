import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../core/settings.dart';
import '../platform/tcp.dart' as tcp;
import 'drive_channel.dart';
import 'links.dart';

/// Where the OBD-II relay stands.
enum RelayStatus {
  off,

  /// This platform can't listen on a port (browsers).
  unsupported,

  /// No adapter chosen, or not one the relay understands.
  unset,

  /// Reaching the adapter.
  connecting,

  /// The adapter's connected; the stack hasn't come for it yet.
  waiting,

  /// The stack is reading the adapter.
  relaying,

  /// The adapter or the port can't be used, for [ObdRelay.error]; trying again.
  error,
}

/// An OBD-II adapter's address ([AppSettings.obdAdapter]).
sealed class AdapterAddress {
  const AdapterAddress();

  /// A paired Bluetooth adapter's MAC address, or a Wi-Fi one's `host:port`;
  /// null for anything else.
  static AdapterAddress? parse(String value) {
    final s = value.trim();
    if (RegExp(r'^[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}$').hasMatch(s)) {
      return BluetoothAdapter(s.replaceAll('-', ':').toUpperCase());
    }
    final uri = Uri.tryParse('tcp://$s');
    if (uri == null || uri.host.isEmpty || !uri.hasPort || uri.port < 1 || uri.port > 65535) return null;
    if (uri.path.isNotEmpty || uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) return null;
    return TcpAdapter(uri.host, uri.port);
  }
}

final class BluetoothAdapter extends AdapterAddress {
  const BluetoothAdapter(this.mac);

  final String mac;

  @override
  bool operator ==(Object other) => other is BluetoothAdapter && other.mac == mac;

  @override
  int get hashCode => mac.hashCode;

  @override
  String toString() => mac;
}

final class TcpAdapter extends AdapterAddress {
  const TcpAdapter(this.host, this.port);

  final String host;
  final int port;

  @override
  bool operator ==(Object other) => other is TcpAdapter && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);

  @override
  String toString() => '$host:$port';
}

/// Whether a client at [address] may read the adapter: this phone itself, or
/// a container on it (Docker's networks, 172.16.0.0/12). Never the rest of the
/// network: an OBD-II port does more than report.
bool relayAllowed(String address) {
  var a = address.toLowerCase();
  if (a == '::1') return true;
  if (a.startsWith('::ffff:')) a = a.substring(7);
  final octets = a.split('.').map(int.tryParse).toList();
  if (octets.length != 4 || octets.any((o) => o == null || o < 0 || o > 255)) return false;
  return octets[0] == 127 || (octets[0] == 172 && octets[1]! >= 16 && octets[1]! <= 31);
}

typedef AdapterConnector = Future<ByteLink> Function(AdapterAddress address);
typedef RelayBinder = Future<ByteServer> Function(int port);

/// Relays an OBD-II adapter to the stack, while [AppSettings.obdRelay] is on
/// and the app is open: it keeps a link to the adapter (Bluetooth, or Wi-Fi)
/// and listens on [AppSettings.obdRelayPort], where the stack's obd2 service
/// reads it (`socket://host.docker.internal:<port>`). One reader at a time:
/// the latest.
class ObdRelay extends ChangeNotifier {
  ObdRelay(this._settings, {AdapterConnector? connectAdapter, RelayBinder? bind, this._supported = !kIsWeb})
    : _connectAdapter = connectAdapter ?? _openAdapter,
      _bind = bind ?? tcp.bindRelay {
    _settings.addListener(_sync);
    _sync();
  }

  static Future<ByteLink> _openAdapter(AdapterAddress address) => switch (address) {
    BluetoothAdapter(:final mac) => DriveChannel.openSerial(mac),
    TcpAdapter(:final host, :final port) => tcp.connectTcp(host, port),
  };

  final AppSettings _settings;
  final AdapterConnector _connectAdapter;
  final RelayBinder _bind;
  final bool _supported;

  RelayStatus get status {
    final run = _run;
    if (!_settings.obdRelay) return RelayStatus.off;
    if (!_supported) return RelayStatus.unsupported;
    if (run == null) return RelayStatus.off;
    if (run.address == null) return RelayStatus.unset;
    if (run.error != null) return RelayStatus.error;
    if (run.adapter == null) return RelayStatus.connecting;
    return run.client == null ? RelayStatus.waiting : RelayStatus.relaying;
  }

  /// What's wrong, while [status] is [RelayStatus.error].
  String? get error => _run?.error;

  /// The adapter's name, while connected.
  String? get adapterName => _run?.adapter?.peer;

  /// Who's reading the adapter, while [RelayStatus.relaying].
  String? get reader => _run?.client?.peer;

  /// The last client turned away for not being on this phone.
  String? get turnedAway => _turnedAway;
  String? _turnedAway;

  /// Bytes sent to the adapter, and received from it, since the relay started.
  int get bytesUp => _up;
  int get bytesDown => _down;
  int _up = 0, _down = 0;

  ({bool on, String adapter, int port})? _key;
  _Run? _run;

  // The last run, winding down: the next one waits for it, to take its port and adapter.
  Future<void> _last = Future.value();
  Timer? _tick;
  bool _disposed = false;

  void _sync() {
    final key = (on: _settings.obdRelay && _supported, adapter: _settings.obdAdapter, port: _settings.obdRelayPort);
    if (key == _key) return;
    final was = _key;
    _key = key;
    _run?.stop();
    _run = null;
    if (key.on) {
      final run = _run = _Run(this, AdapterAddress.parse(key.adapter), key.port);
      _up = _down = 0;
      _turnedAway = null;
      _last = _last.then((_) async {
        try {
          await run.start();
        } catch (_) {
          // Its loops catch what they expect; the next run must still start.
        }
      });
    }
    if (was != null) _changed();
  }

  void _changed({bool counts = false}) {
    if (_disposed) return;
    if (counts) {
      _tick ??= Timer(const Duration(seconds: 1), () {
        _tick = null;
        if (!_disposed) notifyListeners();
      });
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settings.removeListener(_sync);
    _run?.stop();
    _run = null;
    _tick?.cancel();
    super.dispose();
  }
}

/// One go of the relay, with one adapter and port; settings changing stop it.
class _Run {
  _Run(this._relay, this.address, this.port);

  final ObdRelay _relay;
  final AdapterAddress? address;
  final int port;

  final _stopped = Completer<void>();
  bool get stopped => _stopped.isCompleted;

  ByteLink? adapter;
  ByteLink? client;
  StreamSubscription<Uint8List>? _clientInput;
  String? _serverError, _adapterError;

  String? get error => _serverError ?? _adapterError;

  static const _first = Duration(seconds: 2);

  static Duration _next(Duration d) => d * 2 > const Duration(seconds: 30) ? const Duration(seconds: 30) : d * 2;

  void stop() {
    if (stopped) return;
    _stopped.complete();
    // A Bluetooth connect can take a while; this ends it.
    if (address is BluetoothAdapter && adapter == null) unawaited(DriveChannel.cancelSerial());
  }

  Future<void> start() async {
    final address = this.address;
    if (address == null || stopped) return;
    await Future.wait([_serve(), _hold(address)]);
  }

  /// Waits [d], or less if the run stops.
  Future<void> _sleep(Duration d) {
    final done = Completer<void>();
    final timer = Timer(d, () => done.isCompleted ? null : done.complete());
    _stopped.future.then((_) {
      timer.cancel();
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  /// Listens on [port], taking each client that may read the adapter.
  Future<void> _serve() async {
    var backoff = _first;
    while (!stopped) {
      try {
        final server = await _relay._bind(port);
        if (stopped) {
          await server.close();
          return;
        }
        _serverError = null;
        _relay._changed();
        final closed = Completer<void>();
        final clients = server.clients.listen(
          _accept,
          onError: (Object _) {},
          onDone: () => closed.isCompleted ? null : closed.complete(),
        );
        await Future.any([closed.future, _stopped.future]);
        await clients.cancel();
        await server.close();
        if (stopped) return;
        _serverError = 'Stopped listening on port $port';
      } catch (e) {
        _serverError = _describe(e);
      }
      _relay._changed();
      await _sleep(backoff);
      backoff = _next(backoff);
    }
  }

  void _accept(ByteLink c) {
    final adapter = this.adapter;
    final allowed = relayAllowed(c.peer);
    if (!allowed) {
      _relay._turnedAway = c.peer;
      _relay._changed();
    }
    if (stopped || adapter == null || !allowed) {
      unawaited(c.close());
      return;
    }
    _dropClient();
    client = c;
    _clientInput = c.input.listen(
      (data) {
        _relay._up += data.length;
        _relay._changed(counts: true);
        unawaited(adapter.write(data));
      },
      onError: (Object _) {},
      onDone: () {
        if (!identical(client, c)) return;
        _dropClient();
        _relay._changed();
      },
    );
    _relay._changed();
  }

  void _dropClient() {
    final c = client;
    if (c == null) return;
    client = null;
    unawaited(_clientInput?.cancel());
    _clientInput = null;
    unawaited(c.close());
  }

  /// Keeps a link to the adapter, reconnecting when it drops.
  Future<void> _hold(AdapterAddress address) async {
    var backoff = _first;
    while (!stopped) {
      ByteLink? link;
      try {
        link = await _relay._connectAdapter(address);
      } catch (e) {
        _adapterError = _describe(e);
      }
      if (link != null) {
        if (stopped) return link.close();
        adapter = link;
        _adapterError = null;
        backoff = _first;
        _relay._changed();
        final closed = Completer<void>();
        final input = link.input.listen(
          (data) {
            _relay._down += data.length;
            _relay._changed(counts: true);
            if (client case final c?) unawaited(c.write(data));
          },
          onError: (Object _) {},
          onDone: () => closed.isCompleted ? null : closed.complete(),
        );
        await Future.any([closed.future, _stopped.future]);
        await input.cancel();
        adapter = null;
        _dropClient();
        await link.close();
        if (stopped) return;
        _adapterError = 'The adapter went away';
      }
      _relay._changed();
      await _sleep(backoff);
      backoff = _next(backoff);
    }
  }

  static String _describe(Object e) => switch (e) {
    PlatformException(:final message?) => message,
    _ => switch ('$e') {
      final s when s.length > 160 => '${s.substring(0, 160)}…',
      final s => s,
    },
  };
}
