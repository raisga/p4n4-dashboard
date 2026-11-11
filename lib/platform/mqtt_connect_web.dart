import '../drive/links.dart';

Future<MqttLink> connectMqtt({
  required String host,
  required int port,
  required String clientId,
  String user = '',
  String password = '',
  Duration timeout = const Duration(seconds: 8),
}) async => throw UnsupportedError('Browsers have no TCP sockets');
