import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../drive/links.dart';

/// Connects to the broker at [host]:[port] as [clientId] (MQTT 3.1.1), signed
/// in as [user] when there's one. Throws when it can't, or the broker says no.
Future<MqttLink> connectMqtt({
  required String host,
  required int port,
  required String clientId,
  String user = '',
  String password = '',
  Duration timeout = const Duration(seconds: 8),
}) async {
  final client = MqttServerClient.withPort(host, clientId, port, maxConnectionAttempts: 1)
    ..logging(on: false)
    ..setProtocolV311()
    ..keepAlivePeriod = 30
    // Pings unanswered this long: the link is gone (a tunnel, a dead spot).
    ..disconnectOnNoResponsePeriod = 10
    ..connectTimeoutPeriod = timeout.inMilliseconds;
  final done = Completer<void>();
  client.onDisconnected = () => done.isCompleted ? null : done.complete();
  try {
    await client.connect(user.isEmpty ? null : user, password.isEmpty ? null : password);
  } catch (_) {
    _disconnect(client);
    rethrow;
  }
  final status = client.connectionStatus;
  if (status?.state != MqttConnectionState.connected) {
    _disconnect(client);
    throw StateError('The broker said no (${status?.returnCode?.name ?? 'no answer'})');
  }
  return _Link(client, done.future);
}

void _disconnect(MqttServerClient client) {
  try {
    client.disconnect();
  } catch (_) {
    // Never connected.
  }
}

class _Link implements MqttLink {
  _Link(this._client, this.done);

  final MqttServerClient _client;

  @override
  final Future<void> done;

  @override
  bool publish(String topic, String payload) {
    if (_client.connectionStatus?.state != MqttConnectionState.connected) return false;
    try {
      _client.publishMessage(topic, MqttQos.atMostOnce, (MqttClientPayloadBuilder()..addUTF8String(payload)).payload!);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void close() => _disconnect(_client);
}
