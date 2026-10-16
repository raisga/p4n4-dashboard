/// `playChime`: a short two-note alert, drawn by the browser's Web Audio (no
/// sound file to ship) or the platform's alert sound in the apps.
library;

export 'chime_io.dart' if (dart.library.js_interop) 'chime_web.dart';
