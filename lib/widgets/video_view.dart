import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../platform/html_view.dart';
import '../platform/video_clock.dart';

/// video_player plays on Android, iOS and macOS. On web the browser plays the
/// file in a `<video>` instead; Linux and Windows open it in the browser.
bool get videoPlayerSupported =>
    !kIsWeb && const {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS}.contains(defaultTargetPlatform);

/// Where playback is: seconds into the file, and the frame's size once known.
typedef VideoPlayback = ({double seconds, Size? size});

/// Whose footage a camera plays ([Camera.credit]), small in the corner of
/// its picture, [bottom] above its foot (a grid tile's name bar).
class VideoCredit extends StatelessWidget {
  const VideoCredit(this.text, {super.key, this.bottom = 0});

  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) => Positioned(
    right: 8,
    bottom: bottom + 8,
    child: IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: Colors.black54,
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: context.p4.body(size: 10.5, color: P4Colors.dark.text),
          ),
        ),
      ),
    ),
  );
}

/// A video held on one moment: paused [at] seconds into the file. Each bump of
/// [replay] plays it again from [from] to [to], then holds it at [at] again.
typedef VideoHold = ({double at, double from, double to, int replay});

/// A video-file camera (MP4, WebM, HLS): played muted and on a loop, paused
/// while not [active]. The counterpart of `MjpegView` for recorded or demo
/// footage.
class VideoView extends StatefulWidget {
  const VideoView({
    super.key,
    required this.uri,
    this.active = true,
    this.overlay,
    this.syncTo,
    this.hold,
    this.onReplayed,
    this.chrome = true,
  });

  final Uri uri;

  /// When false playback is paused (e.g. the tab is hidden).
  final bool active;

  /// Drawn over the video in step with it, rebuilt every frame while it plays
  /// (the vision overlay's boxes follow the people in the clip).
  final Widget Function(BuildContext context, VideoPlayback playback)? overlay;

  /// Where playback should be, in seconds into the file, when the clip runs
  /// on a clock of its own ([RecordedVision], whose alerts go on while the
  /// video is paused or hidden): playback jumps there whenever it's more than
  /// [VideoViewState.drift] away.
  final double? Function()? syncTo;

  /// Holds playback on a moment instead (an alert's, opened from its toast or
  /// the feed); [syncTo] doesn't apply while it's held.
  final VideoHold? hold;

  /// A replay of [hold] has reached its end, and the video holds again.
  final VoidCallback? onReplayed;

  /// Its badge, spinner and errors; false for a copy shown inside another
  /// (a held moment's close-up), which is the picture alone.
  final bool chrome;

  @override
  State<VideoView> createState() => VideoViewState();
}

class VideoViewState extends State<VideoView> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  Object? _error;

  /// Web: bumped to recreate the `<video>`, which reloads it.
  int _load = 0;
  bool _playing = false;

  /// Playing [VideoView.hold] again, until it reaches its end.
  bool _replaying = false;

  /// Whether the file should be playing now.
  bool get _wantsPlay => widget.active && (widget.hold == null || _replaying);

  /// Web: reads the `<video>`'s own position.
  VideoClock? _clock;

  /// Where playback is, for [VideoView.overlay]; null until it's known.
  final _playback = ValueNotifier<VideoPlayback?>(null);
  late final _ticker = createTicker(_tick);

  /// The player reports its position every few hundred ms; between reports,
  /// playback has moved on by the time since the last one.
  final _sinceReport = Stopwatch();
  Duration? _reported;

  /// Off from [VideoView.syncTo] by more than this many seconds, playback jumps.
  static const drift = 0.75;

  /// Since the last jump: the player takes a moment to report where it landed.
  final _sinceSeek = Stopwatch();

  P4Colors get p4 => context.p4;

  @override
  void initState() {
    super.initState();
    if (videoPlayerSupported) _open();
    _follow();
  }

  @override
  void didUpdateWidget(VideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      reconnect();
    } else {
      _holdChanged(oldWidget.hold);
      if (oldWidget.active != widget.active || oldWidget.hold != widget.hold) _applyPlay();
    }
    _follow();
  }

  /// Held on a new moment: there, paused. The same moment's [VideoHold.replay]
  /// bumped: from its start, playing. Let go: back to playing.
  void _holdChanged(VideoHold? old) {
    final hold = widget.hold;
    if (hold == old) return;
    final same = old != null && hold != null && (old.at, old.from, old.to) == (hold.at, hold.from, hold.to);
    _replaying = same && hold.replay != old.replay;
    if (hold != null) _seek(_replaying ? hold.from : hold.at);
  }

  /// Plays or pauses the player as [_wantsPlay] says (web: the `<video>` follows its `playing`).
  void _applyPlay() {
    final c = _controller;
    if (c != null && c.value.isInitialized) _wantsPlay ? c.play() : c.pause();
  }

  void _seek(double seconds) {
    if (kIsWeb) {
      _clock?.seek(seconds);
    } else {
      _controller?.seekTo(Duration(microseconds: (seconds * 1e6).round()));
    }
    _sinceSeek
      ..reset()
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _playback.dispose();
    _close();
    super.dispose();
  }

  /// Ticks only while there's something to keep in step and the video plays.
  void _follow() {
    final follow = (widget.overlay != null || widget.syncTo != null || widget.hold != null) && widget.active;
    if (follow && !_ticker.isActive) {
      _ticker.start();
    } else if (!follow && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration _) {
    if (kIsWeb) {
      final clock = _clock;
      if (clock == null || !_playing) return;
      _playback.value = (seconds: clock.seconds, size: clock.size);
      if (widget.hold case final hold?) return _held(hold, clock.seconds);
      _sync(clock.seconds, clock.duration, clock.seek);
      return;
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final v = c.value;
    if (v.position != _reported) {
      _reported = v.position;
      _sinceReport
        ..reset()
        ..start();
    }
    final ahead = v.isPlaying ? _sinceReport.elapsedMicroseconds * v.playbackSpeed : 0;
    final seconds = (v.position.inMicroseconds + ahead) / 1e6;
    _playback.value = (seconds: seconds, size: v.size.isEmpty ? null : v.size);
    if (widget.hold case final hold?) return _held(hold, seconds);
    if (v.isPlaying) {
      _sync(seconds, v.duration.inMicroseconds / 1e6, (s) => c.seekTo(Duration(microseconds: (s * 1e6).round())));
    }
  }

  /// Jumps to [VideoView.syncTo] when playback, [at] seconds into a file
  /// [length] long, has drifted from it; across the loop's seam, the short way.
  void _sync(double at, double? length, void Function(double seconds) seek) {
    final want = widget.syncTo?.call();
    if (want == null || length == null || length <= 0) return;
    if (_sinceSeek.isRunning && _sinceSeek.elapsed < const Duration(seconds: 2)) return;
    final off = (want - at) % length;
    if (math.min(off, length - off) <= drift) return;
    seek(want % length);
    _sinceSeek
      ..reset()
      ..start();
  }

  /// Keeps a held video on its moment, and ends a replay at the moment's end
  /// (or if it went round the loop's seam).
  void _held(VideoHold hold, double at) {
    if (_sinceSeek.isRunning && _sinceSeek.elapsed < const Duration(milliseconds: 500)) return;
    if (_replaying) {
      if (at >= hold.from - drift && at < hold.to) return;
      setState(() => _replaying = false);
      _applyPlay();
      _seek(hold.at);
      widget.onReplayed?.call();
    } else if ((at - hold.at).abs() > 0.25) {
      _seek(hold.at);
    }
  }

  /// Loads the file again from the start.
  void reconnect() {
    _playback.value = null;
    if (kIsWeb) {
      setState(() {
        _load++;
        _playing = false;
        _clock = null;
        _error = null;
      });
    } else if (videoPlayerSupported) {
      _close();
      _open();
    }
  }

  void _close() {
    _controller?.dispose();
    _controller = null;
  }

  Future<void> _open() async {
    final c = _controller = VideoPlayerController.networkUrl(
      widget.uri,
      // Muted anyway: don't interrupt the device's own audio.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    setState(() => _error = null);
    try {
      await c.initialize();
      if (_controller != c) return;
      await c.setVolume(0);
      await c.setLooping(true);
      if (_wantsPlay) {
        await c.play();
      } else if (widget.hold case final hold?) {
        _seek(hold.at);
      }
    } catch (e) {
      if (_controller != c) return;
      _close();
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (kIsWeb)
          HtmlVideo(
            key: ValueKey(_load),
            uri: widget.uri,
            playing: _wantsPlay,
            onPlaying: _shown,
            // A held video shows its frame without playing.
            onLoaded: _shown,
            onError: () => setState(() => _error = l.cameraUnavailable),
            onClock: (clock) {
              _clock = clock;
              if (widget.hold case final hold?) _seek(hold.at);
            },
          )
        else if (!videoPlayerSupported)
          _message(
            l.videoUnsupported(defaultTargetPlatform.name),
            OutlinedButton(
              onPressed: () => launchUrl(widget.uri, mode: LaunchMode.externalApplication),
              child: Text(l.openInBrowser),
            ),
          )
        else if (c != null)
          ValueListenableBuilder(
            valueListenable: c,
            builder: (context, v, _) => Stack(
              fit: StackFit.expand,
              children: [
                if (v.isInitialized)
                  Center(
                    child: AspectRatio(aspectRatio: v.aspectRatio, child: VideoPlayer(c)),
                  )
                else if (widget.chrome)
                  Center(child: CircularProgressIndicator(color: p4.accent)),
                if (!widget.chrome)
                  const SizedBox.shrink()
                else if (v.hasError)
                  _failed(v.errorDescription ?? l.cameraUnavailable)
                else if (v.isInitialized)
                  _badge(),
              ],
            ),
          ),
        if (widget.overlay case final overlay?)
          ValueListenableBuilder(
            valueListenable: _playback,
            builder: (context, playback, _) => playback == null ? const SizedBox.shrink() : overlay(context, playback),
          ),
        if (widget.chrome && kIsWeb && widget.active && !_playing && _error == null)
          Center(child: CircularProgressIndicator(color: p4.accent)),
        if (!widget.chrome)
          const SizedBox.shrink()
        else if (_error != null)
          _failed('$_error')
        else if (kIsWeb && _playing)
          _badge(),
      ],
    );
  }

  void _shown() => setState(() {
    _playing = true;
    _error = null;
  });

  Widget _failed(String error) => _message(
    error,
    OutlinedButton(onPressed: reconnect, child: Text(context.l10n.retry)),
    icon: Icons.videocam_off_outlined,
  );

  Widget _message(String text, Widget action, {IconData icon = Icons.ondemand_video_outlined}) => Center(
    child: Container(
      padding: const EdgeInsets.all(16),
      color: p4.bg.withValues(alpha: 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: p4.err),
          const SizedBox(height: 8),
          Text(
            text,
            style: p4.mono(size: 11, color: p4.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          action,
        ],
      ),
    ),
  );

  /// "Video · MP4", where `MjpegView` shows "Live · MJPEG".
  Widget _badge() => Positioned(
    left: 12,
    top: 12,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black54,
      child: Text(
        '${context.l10n.cameraVideo} · ${widget.uri.path.split('.').last.toUpperCase()}',
        style: p4.mono(size: 10, color: P4Colors.dark.text),
      ),
    ),
  );
}
