import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'frame_load.dart';
import 'video_clock.dart';

/// [uri] in a borderless `<iframe>` filling its box. Give it a new key to
/// reload. The page must allow framing (Grafana: `GF_SECURITY_ALLOW_EMBEDDING`;
/// pages served through the dashboard's proxy are same-origin).
///
/// [title] names the frame for screen readers. Moving keyboard focus onto the
/// view (Tab from the toolbar) moves it into the page; Shift+Tab from the
/// page's first control leaves it again.
class HtmlIFrame extends StatefulWidget {
  const HtmlIFrame({super.key, required this.uri, this.title, this.onLoad, this.onPage});

  final Uri uri;
  final String? title;

  /// Each time a page loads in the frame (see [FrameLoad]).
  final ValueChanged<FrameLoad>? onLoad;

  /// Where each page that loads is, after [onLoad], when it can be read (same
  /// origin, http or https).
  final ValueChanged<Uri>? onPage;

  @override
  State<HtmlIFrame> createState() => _HtmlIFrameState();
}

class _HtmlIFrameState extends State<HtmlIFrame> {
  web.HTMLIFrameElement? _frame;

  void _loaded() {
    final frame = _frame;
    if (frame == null) return;
    final load = frameLoadOf(frame, widget.uri);
    widget.onLoad?.call(load);
    if (framePageOf(frame) case final at?) widget.onPage?.call(at);
  }

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (focused) {
      if (focused) _frame?.focus();
    },
    child: Semantics(
      container: true,
      label: widget.title,
      child: HtmlElementView.fromTagName(
        tagName: 'iframe',
        onElementCreated: (element) {
          final frame = _frame = element as web.HTMLIFrameElement;
          frame
            ..title = widget.title ?? ''
            ..tabIndex = 0
            ..onload = ((web.Event _) => _loaded()).toJS
            ..src = widget.uri.toString()
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';
        },
      ),
    ),
  );
}

/// What [frame]'s load event says about the page at [uri] in it. Only a
/// same-origin page can be read; one the browser refused to frame leaves its
/// (unreadable) error page behind, which from another origin looks the same
/// as any page.
FrameLoad frameLoadOf(web.HTMLIFrameElement frame, Uri uri) {
  if (frame.contentDocument != null) return FrameLoad.shown;
  final sameOrigin = (uri.isScheme('http') || uri.isScheme('https')) && uri.origin == web.window.location.origin;
  return sameOrigin ? FrameLoad.blocked : FrameLoad.opaque;
}

/// Where the page in [frame] is, when it can be read: same origin, http or
/// https (not the `about:blank` a new frame starts with).
Uri? framePageOf(web.HTMLIFrameElement frame) {
  if (frame.contentDocument == null) return null;
  final at = Uri.tryParse(frame.contentWindow?.location.href ?? '');
  return at != null && (at.isScheme('http') || at.isScheme('https')) ? at : null;
}

/// [uri] in an `<img>` scaled to fit. Browsers render MJPEG
/// (`multipart/x-mixed-replace`) streams in an `<img>` natively, without the
/// CORS headers a `fetch` would need. Changing [uri] swaps `src` in place, so
/// re-polled snapshots don't flicker. Setting it to an empty URI closes the
/// connection.
class HtmlImage extends StatefulWidget {
  const HtmlImage({super.key, required this.uri, this.onLoad, this.onError});

  final Uri uri;

  /// Each time an image (or a stream's first frame) loads.
  final VoidCallback? onLoad;
  final VoidCallback? onError;

  @override
  State<HtmlImage> createState() => _HtmlImageState();
}

class _HtmlImageState extends State<HtmlImage> {
  web.HTMLImageElement? _img;

  @override
  void didUpdateWidget(HtmlImage old) {
    super.didUpdateWidget(old);
    if (old.uri != widget.uri) _img?.src = widget.uri.toString();
  }

  @override
  void dispose() {
    // Removing the element alone doesn't always close a multipart stream.
    _img?.src = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'img',
    onElementCreated: (element) {
      final img = _img = element as web.HTMLImageElement;
      img
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..onload = ((web.Event _) => widget.onLoad?.call()).toJS
        ..onerror = ((web.Event _) => widget.onError?.call()).toJS
        ..src = widget.uri.toString();
    },
  );
}

/// [uri] in a muted, looping `<video>` scaled to fit (an MP4 or WebM file, or
/// HLS where the browser plays it). Like an `<img>`, it needs no CORS headers.
/// [playing] pauses and resumes it in place; give it a new key to reload.
class HtmlVideo extends StatefulWidget {
  const HtmlVideo({super.key, required this.uri, this.playing = true, this.onPlaying, this.onError, this.onClock});

  final Uri uri;
  final bool playing;

  /// Each time playback starts or resumes.
  final VoidCallback? onPlaying;
  final VoidCallback? onError;

  /// Once the `<video>` exists: reads where it is, for drawing over it.
  final ValueChanged<VideoClock>? onClock;

  @override
  State<HtmlVideo> createState() => _HtmlVideoState();
}

class _HtmlVideoState extends State<HtmlVideo> {
  web.HTMLVideoElement? _video;

  void _play(web.HTMLVideoElement video) {
    // play() rejects when a pause() interrupts it; nothing to report.
    widget.playing ? video.play().toDart.ignore() : video.pause();
  }

  @override
  void didUpdateWidget(HtmlVideo old) {
    super.didUpdateWidget(old);
    final video = _video;
    if (video == null) return;
    if (old.uri != widget.uri) video.src = widget.uri.toString();
    if (old.uri != widget.uri || old.playing != widget.playing) _play(video);
  }

  @override
  void dispose() {
    // Stop downloading: removing the element alone can leave it buffering.
    _video
      ?..pause()
      ..removeAttribute('src')
      ..load();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'video',
    onElementCreated: (element) {
      final video = _video = element as web.HTMLVideoElement;
      video
        ..muted = true
        ..loop = true
        ..playsInline = true
        ..autoplay = widget.playing
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..onplaying = ((web.Event _) => widget.onPlaying?.call()).toJS
        ..onerror = ((web.Event _) => widget.onError?.call()).toJS
        ..src = widget.uri.toString();
      widget.onClock?.call(_ElementClock(video));
    },
  );
}

class _ElementClock implements VideoClock {
  _ElementClock(this.video);

  final web.HTMLVideoElement video;

  @override
  double get seconds => video.currentTime;

  // NaN until the metadata has loaded, Infinity for a live stream.
  @override
  double? get duration => video.duration.isFinite && video.duration > 0 ? video.duration : null;

  @override
  void seek(double seconds) => video.currentTime = seconds;

  @override
  Size? get size => video.videoWidth > 0 && video.videoHeight > 0
      ? Size(video.videoWidth.toDouble(), video.videoHeight.toDouble())
      : null;
}
