import 'dart:typed_data';

/// Bytes both ways: an OBD-II adapter's link, or one of the relay's clients.
abstract class ByteLink {
  /// Who's at the other end: an IP address, or a Bluetooth adapter's name.
  String get peer;

  /// What arrives; done when the link closes.
  Stream<Uint8List> get input;

  Future<void> write(Uint8List data);

  Future<void> close();
}

/// A listening TCP socket ([bindRelay]): each client that connects.
abstract class ByteServer {
  int get port;

  Stream<ByteLink> get clients;

  Future<void> close();
}

/// A connection to an MQTT broker, to publish on ([connectMqtt]).
abstract class MqttLink {
  /// Sends [payload] on [topic] at QoS 0; false if the link is down.
  bool publish(String topic, String payload);

  /// Completes when the link drops, or is closed.
  Future<void> get done;

  void close();
}
