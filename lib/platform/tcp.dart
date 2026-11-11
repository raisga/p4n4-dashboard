/// `bindRelay` and `connectTcp`: TCP sockets for the OBD-II relay, from
/// dart:io. Browsers have none, so there both throw [UnsupportedError].
library;

export 'tcp_io.dart' if (dart.library.js_interop) 'tcp_web.dart';
