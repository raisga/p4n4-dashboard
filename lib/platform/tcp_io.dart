import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../drive/links.dart';

/// Listens on [port] on every interface; the relay checks who connects.
Future<ByteServer> bindRelay(int port) async => _Server(await ServerSocket.bind(InternetAddress.anyIPv4, port));

/// Connects to [host]:[port].
Future<ByteLink> connectTcp(String host, int port, {Duration timeout = const Duration(seconds: 8)}) async =>
    _Link(await Socket.connect(host, port, timeout: timeout));

class _Server implements ByteServer {
  _Server(this._socket);

  final ServerSocket _socket;

  @override
  int get port => _socket.port;

  @override
  late final Stream<ByteLink> clients = _socket.map(_Link.new);

  @override
  Future<void> close() => _socket.close();
}

class _Link implements ByteLink {
  _Link(this._socket) : peer = _addressOf(_socket) {
    try {
      _socket.setOption(SocketOption.tcpNoDelay, true);
    } on SocketException {
      // Closed already: [input] ends at once.
    }
    // A failed write surfaces here; [input] ending says the link is gone.
    unawaited(_socket.done.then<void>((_) {}, onError: (_) {}));
  }

  final Socket _socket;

  @override
  final String peer;

  @override
  late final Stream<Uint8List> input = _socket.handleError((Object _) {});

  @override
  Future<void> write(Uint8List data) async {
    try {
      _socket.add(data);
    } on StateError {
      // Closed: nothing to send it to.
    }
  }

  @override
  Future<void> close() async => _socket.destroy();

  static String _addressOf(Socket socket) {
    try {
      return socket.remoteAddress.address;
    } on SocketException {
      return '';
    }
  }
}
