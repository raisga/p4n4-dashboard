import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// [uri] in a borderless `<iframe>` filling its box. Give it a new key to
/// reload. The page must allow framing (Grafana: `GF_SECURITY_ALLOW_EMBEDDING`).
class HtmlIFrame extends StatelessWidget {
  const HtmlIFrame({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      (element as web.HTMLIFrameElement)
        ..src = uri.toString()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    },
  );
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
