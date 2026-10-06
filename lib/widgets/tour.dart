import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_intro/flutter_intro.dart';

import '../core/brand.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// The [Intro] the tour's steps register with, above the navigator.
///
/// flutter_intro keeps the registered steps on the [Intro] widget itself, so
/// it's built once and [child] is swapped in below it instead.
class TourHost extends StatefulWidget {
  const TourHost({super.key, required this.child});

  final Widget child;

  @override
  State<TourHost> createState() => _TourHostState();
}

class _TourHostState extends State<TourHost> {
  late final _child = ValueNotifier(widget.child);

  // Built on first use, in build, where the MediaQuery can be read.
  late final Intro _intro = Intro(
    noAnimation: MediaQuery.disableAnimationsOf(context),
    maskColor: const Color.fromRGBO(0, 0, 0, .7),
    borderRadius: const BorderRadius.all(Radius.circular(12)),
    padding: const EdgeInsets.all(6),
    child: ValueListenableBuilder(valueListenable: _child, builder: (_, child, _) => child),
  );

  @override
  void didUpdateWidget(TourHost old) {
    super.didUpdateWidget(old);
    _child.value = widget.child;
  }

  @override
  void dispose() {
    _child.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _intro;
}

/// Highlights [child] as [step] of the tour [group], whose layout shows [steps].
///
/// flutter_intro keeps the first [TourTarget] of each step in a group, so
/// [steps] must not change without [group] changing too.
class TourTarget extends StatelessWidget {
  const TourTarget({super.key, required this.group, required this.step, required this.steps, required this.child});

  final String group;
  final TourStep step;
  final List<TourStep> steps;
  final Widget child;

  @override
  Widget build(BuildContext context) => IntroStepBuilder(
    group: group,
    order: step.index,
    overlayBuilder: (params) => _TourCard(step: step, steps: steps, params: params),
    getOverlayPosition: _position,
    builder: (_, key) => KeyedSubtree(key: key, child: child),
  );
}

/// Where a step's card goes: beside a target taller than half the screen (the
/// navigation rail), else below or above it, as wide as a phone allows.
OverlayPosition _position({required Size size, required Size screenSize, required Offset offset}) {
  const margin = 16.0, gap = 12.0;
  final width = math.min(screenSize.width - 2 * margin, 360.0);
  if (size.height > screenSize.height / 2 && offset.dx + size.width + gap + width <= screenSize.width) {
    return OverlayPosition(
      left: offset.dx + size.width + gap,
      top: offset.dy + gap,
      width: width,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
  final below = offset.dy + size.height / 2 < screenSize.height / 2;
  return OverlayPosition(
    left: (offset.dx + size.width / 2 - width / 2).clamp(margin, screenSize.width - margin - width),
    top: below ? offset.dy + size.height + gap : null,
    bottom: below ? null : screenSize.height - offset.dy + gap,
    width: width,
    crossAxisAlignment: CrossAxisAlignment.start,
  );
}

/// [step]'s text: the brand's, in the current language, else the built-in one.
String tourText(BuildContext context, TourStep step) {
  final l = context.l10n;
  final brand = BrandScope.of(context);
  return brand.tourText(step, Localizations.localeOf(context).languageCode) ??
      switch (step) {
        TourStep.welcome => l.tourWelcome(brand.appName),
        TourStep.navigation => l.tourNavigation,
        TourStep.theme => l.tourTheme,
        TourStep.settings => l.tourSettings,
        TourStep.signOut => l.tourSignOut,
      };
}

/// A step's card, next to what it highlights. Finishing or skipping the tour
/// marks it seen ([AppSettings.tourSeen]).
class _TourCard extends StatelessWidget {
  const _TourCard({required this.step, required this.steps, required this.params});

  final TourStep step;
  final List<TourStep> steps;
  final StepWidgetParams params;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final settings = SettingsScope.of(context);
    final last = params.onNext == null;
    void finish() {
      settings.tourSeen = true;
      params.onFinish();
    }

    return Material(
      color: p4.bg2,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p4.border2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.tourProgress(steps.indexOf(step) + 1, steps.length), style: p4.mono(size: 11, color: p4.muted)),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 4, 12),
              child: Text(tourText(context, step), style: p4.body(size: 15, color: p4.text)),
            ),
            // Stacks the buttons when they don't fit side by side (large text, narrow phones).
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 8,
              children: [
                if (!last) TextButton(onPressed: finish, child: Text(l.tourSkip)),
                if (params.onPrev != null) TextButton(onPressed: params.onPrev, child: Text(l.tourBack)),
                FilledButton(onPressed: last ? finish : params.onNext, child: Text(last ? l.tourDone : l.tourNext)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
