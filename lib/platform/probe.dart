/// `probeHttp`: whether anything answers HTTP at a URL. The fallback when
/// p4n4-api can't report service status.
library;

export 'probe_io.dart' if (dart.library.js_interop) 'probe_web.dart';
