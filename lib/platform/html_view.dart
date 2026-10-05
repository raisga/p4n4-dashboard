/// Browser elements shown inside the Flutter tree: an `<iframe>` (Grafana), an
/// `<img>` (camera streams, which browsers decode natively) and a `<video>`
/// (video-file cameras). Only usable on web; elsewhere the stubs throw, so
/// callers check `kIsWeb` first.
library;

export 'html_view_stub.dart' if (dart.library.js_interop) 'html_view_web.dart';
