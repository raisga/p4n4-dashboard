import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';

/// An assistant's reply as selectable rich text: the bit of Markdown models
/// write (`**bold**`, `` `code` ``, `[label](url)`, `- bullets`, `# headings`)
/// and bare http(s) links, which open in the browser. Anything else stays as
/// written: a reply is never hidden because it didn't parse.
class RichMessage extends StatefulWidget {
  const RichMessage(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<RichMessage> createState() => _RichMessageState();
}

class _RichMessageState extends State<RichMessage> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final p4 = context.p4;
    final spans = <InlineSpan>[];
    final lines = widget.text.split('\n');
    for (final (i, raw) in lines.indexed) {
      var line = raw;
      var style = widget.style;
      final heading = RegExp(r'^#{1,6}\s+').firstMatch(line);
      final bullet = RegExp(r'^(\s*)[-*•]\s+').firstMatch(line);
      if (heading != null) {
        line = line.substring(heading.end);
        style = style.copyWith(fontWeight: FontWeight.w700);
      } else if (bullet != null) {
        spans.add(TextSpan(text: '${bullet.group(1)}• ', style: style));
        line = line.substring(bullet.end);
      }
      spans.addAll(_inline(line, style, p4));
      if (i < lines.length - 1) spans.add(TextSpan(text: '\n', style: style));
    }
    return SelectableText.rich(TextSpan(children: spans));
  }

  static final _token = RegExp(
    r'\*\*(.+?)\*\*'
    r'|`([^`]+)`'
    r'|\[([^\]]+)\]\((https?://[^\s)]+)\)'
    r'|(https?://[^\s<>()]+[^\s<>().,;:!?])',
  );

  List<InlineSpan> _inline(String text, TextStyle style, P4Colors p4) {
    final out = <InlineSpan>[];
    var at = 0;
    for (final m in _token.allMatches(text)) {
      if (m.start > at) out.add(TextSpan(text: text.substring(at, m.start), style: style));
      if (m.group(1) != null) {
        out.add(
          TextSpan(
            text: m.group(1),
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (m.group(2) != null) {
        out.add(
          TextSpan(
            text: m.group(2),
            style: p4.mono(size: (style.fontSize ?? 15) - 1, color: style.color),
          ),
        );
      } else {
        final url = m.group(4) ?? m.group(5)!;
        out.add(_link(m.group(3) ?? url, url, style, p4));
      }
      at = m.end;
    }
    if (at < text.length) out.add(TextSpan(text: text.substring(at), style: style));
    return out;
  }

  InlineSpan _link(String label, String url, TextStyle style, P4Colors p4) {
    final uri = Uri.tryParse(url);
    if (uri == null) return TextSpan(text: label, style: style);
    final recognizer = TapGestureRecognizer()..onTap = () => launchUrl(uri, mode: LaunchMode.externalApplication);
    _recognizers.add(recognizer);
    return TextSpan(
      text: label,
      style: style.copyWith(color: p4.blue, decoration: TextDecoration.underline, decorationColor: p4.blue),
      recognizer: recognizer,
      mouseCursor: SystemMouseCursors.click,
    );
  }
}
