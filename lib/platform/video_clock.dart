import 'dart:ui' show Size;

/// Where a playing video is, for drawing over it in step (the Video tab's
/// vision overlay), and moving it to keep it in step with a clock of its own.
abstract interface class VideoClock {
  /// Seconds into the file.
  double get seconds;

  /// The file's length in seconds, once known.
  double? get duration;

  /// The frame's own size, once known.
  Size? get size;

  /// Jumps to [seconds] into the file.
  void seek(double seconds);
}
