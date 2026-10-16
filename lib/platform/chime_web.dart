import 'package:web/web.dart' as web;

web.AudioContext? _context;

/// Two quick rising notes. Browsers only let a page make sound after someone
/// has interacted with it; signing in counts, and before that this is silent.
Future<void> playChime() async {
  try {
    final ctx = _context ??= web.AudioContext();
    final now = ctx.currentTime;
    for (final (i, hz) in const [880.0, 1318.5].indexed) {
      final start = now + i * 0.16;
      final osc = ctx.createOscillator()
        ..type = 'sine'
        ..frequency.value = hz;
      final gain = ctx.createGain();
      gain.gain
        ..setValueAtTime(0.0001, start)
        ..exponentialRampToValueAtTime(0.25, start + 0.02)
        ..exponentialRampToValueAtTime(0.0001, start + 0.32);
      osc
        ..connect(gain)
        ..start(start)
        ..stop(start + 0.34);
      gain.connect(ctx.destination);
    }
  } catch (_) {
    // No audio device, or the browser said no: the toast still shows.
  }
}
