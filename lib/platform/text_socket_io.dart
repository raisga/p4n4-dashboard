import 'dart:async';
import 'dart:io';

/// Connects to [uri]. The stream carries each text message, and ends when the
/// socket closes; cancelling the subscription closes it.
Future<Stream<String>> connectTextSocket(Uri uri, {Duration timeout = const Duration(seconds: 8)}) async {
  final socket = await WebSocket.connect(uri.toString()).timeout(timeout);
  late final StreamController<String> out;
  out = StreamController<String>(
    onListen: () {
      socket.listen(
        (m) => m is String ? out.add(m) : null,
        onError: out.addError,
        onDone: out.close,
        cancelOnError: true,
      );
    },
    onCancel: () => socket.close(),
  );
  return out.stream;
}
