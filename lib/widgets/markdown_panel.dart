import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import 'common.dart';

/// A project's own Markdown (the Home tab's `HOME.md`) in a [Panel], styled
/// with the brand's theme. Links open in the browser, except two kinds:
/// `tab:<name>` ones (`[Activity](tab:feed)`) open one of [tabs] with
/// [onTab], and `ask:` ones (`[Is any unit on warning?](ask:)`) ask the
/// assistant their text with [onAsk]. Such a link with nowhere to go (a tab
/// that isn't there, or no [onAsk]) is shown as plain text. Images need
/// absolute URLs, since the file's directory isn't served.
class MarkdownPanel extends StatelessWidget {
  const MarkdownPanel(this.markdown, {super.key, this.tabs = const {}, this.onTab, this.onAsk});

  final String markdown;

  /// Names of the tabs `tab:` links can open (`DashTab.name`).
  final Set<String> tabs;
  final ValueChanged<String>? onTab;
  final ValueChanged<String>? onAsk;

  static final _appLink = RegExp(r'\[([^\]]*)\]\((?:tab:([a-z]+)|ask:)\)');

  /// [markdown] with `tab:` and `ask:` links that can't be followed reduced to their text.
  String get _data =>
      markdown.replaceAllMapped(_appLink, (m) => (m[2] == null ? onAsk != null : tabs.contains(m[2])) ? m[0]! : m[1]!);

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final body = p4.body(size: 15);
    final code = p4.mono(size: 13, color: p4.text);
    return Panel(
      padding: const EdgeInsets.all(24),
      child: MarkdownBody(
        data: _data,
        selectable: true,
        onTapLink: (text, href, _) {
          final uri = href == null ? null : Uri.tryParse(href);
          if (uri == null || !uri.hasScheme) return;
          switch (uri.scheme) {
            case 'tab':
              if (tabs.contains(uri.path)) onTab?.call(uri.path);
            case 'ask':
              if (text.trim().isNotEmpty) onAsk?.call(text.trim());
            default:
              launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        styleSheet: MarkdownStyleSheet(
          p: body,
          h1: p4.display(size: 24, weight: FontWeight.w800, spacing: -0.6),
          h2: p4.display(size: 20, weight: FontWeight.w800, spacing: -0.4),
          h3: p4.display(size: 17),
          h4: p4.display(size: 15),
          h5: p4.display(size: 14),
          h6: p4.display(size: 13, color: p4.muted),
          a: body.copyWith(color: p4.blue, decoration: TextDecoration.underline, decorationColor: p4.blue),
          em: body.copyWith(fontStyle: FontStyle.italic),
          strong: body.copyWith(fontWeight: FontWeight.w700),
          del: body.copyWith(decoration: TextDecoration.lineThrough),
          listBullet: body,
          tableHead: body.copyWith(fontWeight: FontWeight.w700),
          tableBody: body,
          tableBorder: TableBorder.all(color: p4.border),
          tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          code: code.copyWith(backgroundColor: p4.bg3),
          codeblockPadding: const EdgeInsets.all(12),
          codeblockDecoration: BoxDecoration(color: p4.bg3, borderRadius: BorderRadius.circular(8)),
          blockquote: body.copyWith(color: p4.muted),
          blockquotePadding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
          blockquoteDecoration: BoxDecoration(
            border: Border(left: BorderSide(color: p4.accent, width: 3)),
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(top: BorderSide(color: p4.border)),
          ),
          h1Padding: const EdgeInsets.only(bottom: 4),
          h2Padding: const EdgeInsets.only(top: 8, bottom: 2),
          h3Padding: const EdgeInsets.only(top: 6),
          blockSpacing: 12,
        ),
      ),
    );
  }
}
