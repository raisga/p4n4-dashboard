/// `connectTextSocket`: a WebSocket that receives text messages, from dart:io
/// or the browser. Enough for the Video tab's live detections, without a
/// package for it.
library;

export 'text_socket_io.dart' if (dart.library.js_interop) 'text_socket_web.dart';
