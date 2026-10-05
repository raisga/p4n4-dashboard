import 'package:flutter/widgets.dart';

/// Web only; see `html_view_web.dart`.
class HtmlIFrame extends StatelessWidget {
  const HtmlIFrame({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) => throw UnsupportedError('HtmlIFrame is web-only');
}

/// Web only; see `html_view_web.dart`.
class HtmlImage extends StatelessWidget {
  const HtmlImage({super.key, required this.uri, this.onLoad, this.onError});

  final Uri uri;
  final VoidCallback? onLoad;
  final VoidCallback? onError;

  @override
  Widget build(BuildContext context) => throw UnsupportedError('HtmlImage is web-only');
}

/// Web only; see `html_view_web.dart`.
class HtmlVideo extends StatelessWidget {
  const HtmlVideo({super.key, required this.uri, this.playing = true, this.onPlaying, this.onError});

  final Uri uri;
  final bool playing;
  final VoidCallback? onPlaying;
  final VoidCallback? onError;

  @override
  Widget build(BuildContext context) => throw UnsupportedError('HtmlVideo is web-only');
}
