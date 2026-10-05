import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../platform/html_view.dart';

/// video_player plays on Android, iOS and macOS. On web the browser plays the
/// file in a `<video>` instead; Linux and Windows open it in the browser.
bool get videoPlayerSupported =>
    !kIsWeb && const {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS}.contains(defaultTargetPlatform);

/// A video-file camera (MP4, WebM, HLS): played muted and on a loop, paused
/// while not [active]. The counterpart of `MjpegView` for recorded or demo
/// footage.
class VideoView extends StatefulWidget {
  const VideoView({super.key, required this.uri, this.active = true});

  final Uri uri;

  /// When false playback is paused (e.g. the tab is hidden).
  final bool active;

  @override
  State<VideoView> createState() => VideoViewState();
}

class VideoViewState extends State<VideoView> {
  VideoPlayerController? _controller;
  Object? _error;

  /// Web: bumped to recreate the `<video>`, which reloads it.
  int _load = 0;
  bool _playing = false;

  P4Colors get p4 => context.p4;

  @override
  void initState() {
    super.initState();
    if (videoPlayerSupported) _open();
  }

  @override
  void didUpdateWidget(VideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      reconnect();
    } else if (oldWidget.active != widget.active) {
      final c = _controller;
      if (c != null && c.value.isInitialized) widget.active ? c.play() : c.pause();
    }
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  /// Loads the file again from the start.
  void reconnect() {
    if (kIsWeb) {
      setState(() {
        _load++;
        _playing = false;
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
      if (widget.active) await c.play();
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
            playing: widget.active,
            onPlaying: () => setState(() {
              _playing = true;
              _error = null;
            }),
            onError: () => setState(() => _error = l.cameraUnavailable),
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
                else
                  Center(child: CircularProgressIndicator(color: p4.accent)),
                if (v.hasError) _failed(v.errorDescription ?? l.cameraUnavailable) else if (v.isInitialized) _badge(),
              ],
            ),
          ),
        if (kIsWeb && widget.active && !_playing && _error == null)
          Center(child: CircularProgressIndicator(color: p4.accent)),
        if (_error != null) _failed('$_error') else if (kIsWeb && _playing) _badge(),
      ],
    );
  }

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
