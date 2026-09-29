import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../core/theme.dart';

/// `// TAG` + title block used at the top of each section.
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
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '// ',
                      style: p4.mono(color: p4.muted, spacing: 0.15),
                    ),
                    TextSpan(
                      text: tag.toUpperCase(),
                      style: p4.mono(color: tagColor ?? p4.accent, spacing: 0.15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(style: p4.display(size: 18, spacing: -0.5), child: title),
            ],
          ),
        ),
        ?trailing,
      ],
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

/// `<platform>-<suffix>` wordmark, e.g. `p4n4-iot`.
class StackName extends StatelessWidget {
  const StackName(this.suffix, {super.key, this.size = 18});

  final String suffix;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Text.rich(
      TextSpan(
        style: p4.display(size: size, spacing: -0.5),
        children: [
          TextSpan(text: BrandScope.of(context).platform),
          TextSpan(
            text: '-$suffix',
            style: TextStyle(color: p4.accent),
          ),
        ],
      ),
    );
  }
}

/// Flat bordered panel matching the `.card` style.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.accent});

  final Widget child;
  final EdgeInsets padding;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p4.bg2,
        border: Border(
          top: BorderSide(color: accent ?? p4.border, width: accent == null ? 1 : 2),
          left: BorderSide(color: p4.border),
          right: BorderSide(color: p4.border),
          bottom: BorderSide(color: p4.border),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class TagBadge extends StatelessWidget {
  const TagBadge(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(border: Border.all(color: p4.border2)),
      child: Text(label.toUpperCase(), style: p4.mono(size: 10, color: color, spacing: 0.1)),
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
    final (color, text) = switch (health) {
      Health.up => (p4.ok, 'online'),
      Health.down => (p4.err, 'offline'),
      Health.pending => (p4.warn, 'checking'),
      Health.unknown => (p4.muted, 'unknown'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: health == Health.up ? [BoxShadow(color: color, blurRadius: 6)] : null,
          ),
        ),
        const SizedBox(width: 7),
        Text((label ?? text).toUpperCase(), style: p4.mono(color: color)),
      ],
    );
  }
}

/// Centered empty/error state with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: p4.accent),
              const SizedBox(height: 16),
              Text(title, style: p4.display(size: 17), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                textAlign: TextAlign.center,
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
