import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Connects to [uri]. The stream carries each text message, and ends when the
/// socket closes; cancelling the subscription closes it.
Future<Stream<String>> connectTextSocket(Uri uri, {Duration timeout = const Duration(seconds: 8)}) {
  final socket = web.WebSocket(uri.toString());
  final opened = Completer<Stream<String>>();
  final out = StreamController<String>(onCancel: () => socket.close());
  socket
    ..onopen = ((web.Event _) => opened.isCompleted ? null : opened.complete(out.stream)).toJS
    ..onmessage = ((web.MessageEvent e) {
      if (e.data case final JSString text) out.add(text.toDart);
    }).toJS
    // Browsers say nothing about why; the close that follows ends the stream.
    ..onerror = ((web.Event _) {
      if (!opened.isCompleted) opened.completeError(StateError('Could not connect to $uri'));
    }).toJS
    ..onclose = ((web.CloseEvent _) {
      if (!opened.isCompleted) opened.completeError(StateError('Could not connect to $uri'));
      out.close();
    }).toJS;
  return opened.future.timeout(
    timeout,
    onTimeout: () {
      socket.close();
      throw TimeoutException('No answer from $uri', timeout);
    },
  );
}
