/// Browser elements shown inside the Flutter tree: an `<iframe>` (Grafana and
/// the other services' web apps, see `ServiceViewer`), an
/// `<img>` (camera streams, which browsers decode natively) and a `<video>`
/// (video-file cameras). Only usable on web; elsewhere the stubs throw, so
/// callers check `kIsWeb` first.
library;

export 'frame_load.dart';
export 'html_view_stub.dart' if (dart.library.js_interop) 'html_view_web.dart';
