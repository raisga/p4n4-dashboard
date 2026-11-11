/// The dashcam's files on this device: its folder, listing, moving and
/// deleting clips, their GPX sidecars, and a player for one. From dart:io;
/// browsers have no folders, so there they find nothing and throw on writes.
library;

export 'local_files_io.dart' if (dart.library.js_interop) 'local_files_web.dart';
