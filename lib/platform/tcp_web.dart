import '../drive/links.dart';

Future<ByteServer> bindRelay(int port) async => throw UnsupportedError('Browsers have no TCP sockets');

Future<ByteLink> connectTcp(String host, int port, {Duration timeout = const Duration(seconds: 8)}) async =>
    throw UnsupportedError('Browsers have no TCP sockets');
