import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import 'common.dart';

/// A project's own Markdown (the Home tab's `HOME.md`) in a [Panel], styled
/// with the brand's theme. Links open in the browser, except two kinds:
/// `tab:<name>` ones (`[Activity](tab:feed)`) open one of [tabs] with
/// [onTab], and `ask:` ones (`[Is any unit on warning?](ask:)`) ask the
/// assistant their text with [onAsk]. Those two show as chips, with the tab's
/// icon or the assistant's. Such a link with nowhere to go (a tab that isn't
/// there, or no [onAsk]) is shown as plain text. Images need absolute URLs,
/// since the file's directory isn't served.
///
/// Section headings (`###`) get an accent marker, tables a header band and
/// rules between rows only, and a blockquote reads as a callout.
class MarkdownPanel extends StatelessWidget {
  const MarkdownPanel(this.markdown, {super.key, this.tabs = const {}, this.onTab, this.onAsk});

  final String markdown;

  /// Names of the tabs `tab:` links can open (`DashTab.name`).
  final Set<String> tabs;
  final ValueChanged<String>? onTab;
  final ValueChanged<String>? onAsk;

  static final _appLink = RegExp(r'\[([^\]]*)\]\((?:tab:([a-z]+)|ask:)\)');

  /// The tabs' outlined icons, as in the navigation (main.dart `_dests`).
  static const _tabIcons = {
    'feed': Icons.dynamic_feed_outlined,
    'agent': Icons.forum_outlined,
    'grafana': Icons.show_chart_outlined,
    'video': Icons.videocam_outlined,
    'edge': Icons.memory_outlined,
    'services': Icons.apps_outlined,
  };

  /// [markdown] with `tab:` and `ask:` links that can't be followed reduced to their text.
  String get _data =>
      markdown.replaceAllMapped(_appLink, (m) => (m[2] == null ? onAsk != null : tabs.contains(m[2])) ? m[0]! : m[1]!);

  void _open(String text, String? href) {
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
  }

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Panel(
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        // A faint wash of the brand's accent behind the title
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, -0.2),
            colors: [
              p4.accent.withValues(alpha: p4.isDark ? 0.07 : 0.05),
              p4.accent.withValues(alpha: 0),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
          // SelectionArea rather than MarkdownBody.selectable, which can't hold the chips
          child: SelectionArea(
            child: LayoutBuilder(builder: (context, box) => _body(context, narrow: box.maxWidth < _narrow)),
          ),
        ),
      ),
    );
  }

  /// Below this width (a phone), tables keep columns wide enough to read and scroll sideways.
  static const _narrow = 560.0;

  Widget _body(BuildContext context, {required bool narrow}) {
    final p4 = context.p4;
    final body = p4.body(size: 15);
    final code = p4.mono(size: 13, color: p4.text);
    final rule = BorderSide(color: p4.border);
    return MarkdownBody(
      data: _data,
      builders: {'a': _LinkBuilder(_open, _tabIcons), 'h3': _SectionBuilder()},
      bulletBuilder: (b) => b.style == BulletStyle.orderedList
          ? Text(
              '${b.index + 1}.',
              style: body.copyWith(color: p4.accent2, fontWeight: FontWeight.w700),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: b.nestLevel == 0 ? BoxShape.circle : BoxShape.rectangle,
                  color: b.nestLevel == 0 ? p4.accent2 : p4.muted,
                ),
              ),
            ),
      styleSheet: MarkdownStyleSheet(
        p: body,
        h1: p4.display(size: 26, weight: FontWeight.w800, spacing: -0.7),
        h2: p4.display(size: 22, weight: FontWeight.w800, spacing: -0.5),
        h3: p4.display(size: 16),
        h4: p4.display(size: 15),
        h5: p4.display(size: 14),
        h6: p4.display(size: 13, color: p4.muted),
        a: body.copyWith(color: p4.blue, decoration: TextDecoration.underline, decorationColor: p4.blue),
        em: body.copyWith(fontStyle: FontStyle.italic),
        strong: body.copyWith(fontWeight: FontWeight.w700, color: p4.heading),
        del: body.copyWith(decoration: TextDecoration.lineThrough),
        listBullet: body,
        listIndent: 22,
        listBulletPadding: const EdgeInsets.only(right: 6),
        tableHead: p4.body(size: 12.5, weight: FontWeight.w700, color: p4.muted),
        tableHeadAlign: TextAlign.left,
        tableBody: p4.body(size: 14),
        tableBorder: TableBorder(top: rule, bottom: rule, left: rule, right: rule, horizontalInside: rule),
        tableColumnWidth: narrow ? const FixedColumnWidth(190) : const FlexColumnWidth(),
        tableScrollbarThumbVisibility: narrow,
        tableHeadCellsDecoration: BoxDecoration(color: p4.bg3),
        tableCellsPadding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 14, vertical: 10),
        tableHeadCellsPadding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 14, vertical: 9),
        tableVerticalAlignment: TableCellVerticalAlignment.middle,
        code: code.copyWith(backgroundColor: p4.bg3),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(color: p4.bg3, borderRadius: BorderRadius.circular(8)),
        blockquote: body.copyWith(color: p4.heading),
        blockquotePadding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
        // Flutter can't round a border drawn on one side only, hence square corners
        blockquoteDecoration: BoxDecoration(
          color: p4.accent.withValues(alpha: p4.isDark ? 0.08 : 0.05),
          border: Border(left: BorderSide(color: p4.accent, width: 3)),
        ),
        horizontalRuleDecoration: BoxDecoration(border: Border(top: rule)),
        h1Padding: const EdgeInsets.only(bottom: 2),
        h2Padding: const EdgeInsets.only(bottom: 2),
        h3Padding: const EdgeInsets.only(top: 14),
        blockSpacing: 14,
      ),
    );
  }
}

/// `###` headings: the text after a short accent bar.
class _SectionBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final p4 = context.p4;
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(color: p4.accent, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(element.textContent, style: preferredStyle)),
      ],
    );
  }
}

/// Links, inline: `tab:` and `ask:` ones as chips, the rest as underlined
/// text. Each is a [WidgetSpan] inside a [Text.rich], which the markdown
/// builder merges into its paragraph like any other text.
class _LinkBuilder extends MarkdownElementBuilder {
  _LinkBuilder(this.open, this.tabIcons);

  final void Function(String text, String? href) open;
  final Map<String, IconData> tabIcons;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final p4 = context.p4;
    final text = element.textContent;
    final href = element.attributes['href'];
    final uri = href == null ? null : Uri.tryParse(href);
    final Widget child = switch (uri?.scheme) {
      'tab' => _Chip(
        icon: tabIcons[uri!.path] ?? Icons.arrow_forward,
        label: text,
        color: p4.accent,
        fill: p4.accent.withValues(alpha: p4.isDark ? 0.10 : 0.06),
        onTap: () => open(text, href),
      ),
      'ask' => _Chip(
        icon: Icons.auto_awesome_outlined,
        label: text,
        color: p4.accent2,
        fill: p4.bg3,
        onTap: () => open(text, href),
      ),
      _ => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => open(text, href),
          child: Text(text, style: preferredStyle),
        ),
      ),
    };
    return Text.rich(
      WidgetSpan(
        alignment: uri?.scheme == 'tab' || uri?.scheme == 'ask'
            ? PlaceholderAlignment.middle
            : PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: child,
      ),
    );
  }
}

/// A rounded, tappable label with a leading icon: a `tab:` or `ask:` link.
/// One line, about as tall as the text around it: the markdown builder fixes
/// each paragraph's line height, so a taller chip would spill over the lines
/// next to it, outside its paragraph, where taps don't reach it. A label too
/// long for the line ends in an ellipsis, with the whole of it in a tooltip.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color, required this.fill, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final Color fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final shape = StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.35)));
    return Tooltip(
      message: label,
      child: Material(
        color: fill,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 1, 10, 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: p4.body(size: 14, weight: FontWeight.w600, color: p4.heading),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
