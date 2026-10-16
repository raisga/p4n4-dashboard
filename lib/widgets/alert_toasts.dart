import 'package:flutter/material.dart';

import '../api/vision.dart' show VisionTone;
import '../core/alerts.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import 'vision_overlay.dart' show visionToneColor;

/// The [center]'s alerts over every tab, top right (across the top on
/// phones). Tapping one opens what it's about ([onOpen]).
class AlertToasts extends StatelessWidget {
  const AlertToasts({super.key, required this.center, required this.onOpen});

  final AlertCenter center;
  final ValueChanged<AlertNotice> onOpen;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return ListenableBuilder(
      listenable: center,
      builder: (context, _) {
        final shown = center.shown;
        if (shown.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: wide ? Alignment.topRight : Alignment.topCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final n in shown)
                      Padding(
                        key: ValueKey(n.id),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _Toast(
                          notice: n,
                          onOpen: () {
                            center.dismiss(n.id);
                            onOpen(n);
                          },
                          onDismiss: () => center.dismiss(n.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.notice, required this.onOpen, required this.onDismiss});

  final AlertNotice notice;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final color = visionToneColor(p4, notice.tone);
    final review = notice.tone == VisionTone.review;
    final card = Material(
      color: p4.bg2,
      elevation: 6,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
                child: Icon(review ? Icons.report_outlined : Icons.person_search_outlined, color: color, size: 22),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 4, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            if (notice.code != null)
                              TextSpan(
                                text: '${notice.code}  ',
                                style: p4.mono(size: 12, color: color, weight: FontWeight.w700, spacing: 0),
                              ),
                            TextSpan(text: notice.title),
                          ],
                        ),
                        style: p4.display(size: 15, weight: FontWeight.w600, spacing: 0),
                      ),
                      if (notice.where != null) ...[
                        const SizedBox(height: 2),
                        Text(notice.where!, style: p4.mono(size: 11.5, color: p4.muted, spacing: 0)),
                      ],
                      if (notice.detail != null) ...[
                        const SizedBox(height: 6),
                        Text(notice.detail!, style: p4.body(size: 13)),
                      ],
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: l.alertDismiss,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 18, color: p4.muted),
                  onPressed: onDismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      child: !animate
          ? card
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(offset: Offset(0, -12 * (1 - t)), child: child),
              ),
              child: card,
            ),
    );
  }
}
