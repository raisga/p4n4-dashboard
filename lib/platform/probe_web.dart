import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// A `no-cors` fetch resolves with an opaque response whenever the server
/// answers, and rejects when nothing does. That's all a probe needs, and it
/// works on services that send no CORS headers.
Future<bool> probeHttp(Uri uri) async {
  try {
    await web.window
        .fetch(uri.toString().toJS, web.RequestInit(mode: 'no-cors', cache: 'no-store'))
        .toDart
        .timeout(const Duration(seconds: 3));
    return true;
  } catch (_) {
    return false;
  }
}
