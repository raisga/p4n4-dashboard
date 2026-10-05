import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// A small label over a title, used to head sections of a page.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.tag, required this.title, this.tagColor, this.trailing});

  final String tag;
  final Widget title;
  final Color? tagColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag,
                style: p4.display(size: 13, color: tagColor ?? p4.accent, weight: FontWeight.w600, spacing: 0),
              ),
              const SizedBox(height: 6),
              DefaultTextStyle(style: p4.display(size: 20, spacing: -0.4), child: title),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// The top of a page: what it is, one line on what it's for, and actions.
/// On narrow screens wide actions (e.g. a labelled switch) go under the title.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: p4.display(size: 28, weight: FontWeight.w800, spacing: -0.8)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: p4.body(size: 15, color: p4.muted)),
        ],
      ],
    );
    if (trailing == null) return text;
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth < 520 && trailing is! IconButton && trailing is! RefreshButton
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 12), trailing!],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: text),
                const SizedBox(width: 12),
                trailing!,
              ],
            ),
    );
  }
}

/// A scrolling page: [children] in a centred column at most [maxWidth] wide.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 1100, this.onRefresh});

  final List<Widget> children;
  final double maxWidth;

  /// Pull to refresh, when set.
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ),
      ],
    );
    return onRefresh == null ? list : RefreshIndicator(color: context.p4.accent, onRefresh: onRefresh!, child: list);
  }
}

/// A refresh button that turns into a spinner while [busy].
class RefreshButton extends StatelessWidget {
  const RefreshButton({super.key, required this.busy, required this.onPressed, this.tooltip});

  final bool busy;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return IconButton(
      tooltip: tooltip ?? context.l10n.refreshStatus,
      onPressed: busy ? null : onPressed,
      icon: busy
          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent))
          : Icon(Icons.refresh, color: p4.muted),
    );
  }
}

/// Brand logo, or the text wordmark with its muted suffix.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final brand = BrandScope.of(context);
    if (brand.logo != null) return Image.asset(brand.logo!, height: size * 1.4, semanticLabel: brand.appName);
    return Text.rich(
      TextSpan(
        style: p4.mono(size: size, color: p4.accent, weight: FontWeight.w700, spacing: -0.05),
        children: [
          TextSpan(text: brand.wordmark),
          TextSpan(
            text: brand.wordmarkSuffix,
            style: p4.mono(size: size * 0.9, color: p4.muted, weight: FontWeight.w700, spacing: -0.05),
          ),
        ],
      ),
    );
  }
}

/// A rounded card. [accent] adds a coloured strip along the top, for cards
/// whose colour carries meaning (e.g. the status summary). A [Material], so
/// list tiles and ink inside it paint properly.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.accent});

  final Widget child;
  final EdgeInsets padding;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Material(
      color: p4.bg2,
      shape: Radii.cardShape.copyWith(side: BorderSide(color: p4.border)),
      clipBehavior: Clip.antiAlias,
      child: accent == null
          ? Padding(padding: padding, child: child)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, color: accent),
                Padding(padding: padding, child: child),
              ],
            ),
    );
  }
}

/// A small rounded label, tinted with [color].
class TagBadge extends StatelessWidget {
  const TagBadge(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final c = color ?? p4.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: p4.display(size: 12, color: c, weight: FontWeight.w600, spacing: 0),
      ),
    );
  }
}

enum Health { up, down, unknown, pending }

/// Coloured dot + label; never colour alone.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator(this.health, {super.key, this.label});

  final Health health;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final color = healthColor(p4, health);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label ?? context.l10n.healthName(health),
            overflow: TextOverflow.ellipsis,
            style: p4.display(size: 13, color: color, weight: FontWeight.w600, spacing: 0),
          ),
        ),
      ],
    );
  }
}

Color healthColor(P4Colors p4, Health health) => switch (health) {
  Health.up => p4.ok,
  Health.down => p4.err,
  Health.pending => p4.warn,
  Health.unknown => p4.muted,
};

/// How a device reading compares with what's normal, so people don't have to
/// know what 85% or 78°C means.
enum Level { normal, high, critical }

/// CPU or memory use, in percent.
Level usageLevel(double percent) => percent >= 90
    ? Level.critical
    : percent >= 75
    ? Level.high
    : Level.normal;

/// Board temperature, in °C. Raspberry Pis start throttling at 80°C.
Level temperatureLevel(double celsius) => celsius >= 80
    ? Level.critical
    : celsius >= 70
    ? Level.high
    : Level.normal;

Color levelColor(P4Colors p4, Level level) => switch (level) {
  Level.normal => p4.ok,
  Level.high => p4.warn,
  Level.critical => p4.err,
};

/// Centred empty, error or "nothing here yet" state with optional actions.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
    this.color,
    this.details,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  /// The icon's tint; the accent colour by default.
  final Color? color;

  /// Technical detail (a URL, the raw error) in small type under the message,
  /// for the people who can act on it.
  final String? details;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final c = color ?? p4.accent;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(icon, size: 30, color: c),
                ),
                const SizedBox(height: 18),
                Text(title, style: p4.display(size: 19), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: p4.body(size: 14, color: p4.muted),
                  textAlign: TextAlign.center,
                ),
                if (details != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(details!, style: p4.mono(size: 11, spacing: 0), textAlign: TextAlign.center),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: actions),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centred spinner with a line saying what's loading.
class LoadingState extends StatelessWidget {
  const LoadingState(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: p4.accent)),
            const SizedBox(height: 14),
            Text(
              message,
              style: p4.body(size: 14, color: p4.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Equal-width columns, at least [minWidth] wide (at most four).
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children, this.minWidth = 260, this.gap = 12});

  final List<Widget> children;
  final double minWidth;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cols = (c.maxWidth / minWidth).floor().clamp(1, 4);
      final w = (c.maxWidth - (cols - 1) * gap) / cols - 0.01;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final child in children) SizedBox(width: w, child: child)],
      );
    },
  );
}
