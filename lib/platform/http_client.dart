/// `newHttpClient()`: the platform's own HTTP client (dart:io or the browser's
/// fetch/XHR). `http.Client()` can't be used to build the app-wide client in
/// `http.runWithClient`, because inside that zone it returns the zone's client.
library;

export 'http_client_io.dart' if (dart.library.js_interop) 'http_client_web.dart';
