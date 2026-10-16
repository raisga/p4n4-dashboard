import 'package:flutter/material.dart';

import '../api/vision.dart';
import '../core/brand.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// The vision HUD's own colour: it's drawn over video, whatever the theme.
/// People's boxes are in it, unless the brand picks theirs
/// ([VisionStyle.people]).
const hudColor = Color(0xFF00E5FF);

/// Each kind of object's colour, by its place in [VisionBundle.objects]
/// (e.g. outerwear, tops, dresses, bottoms, accessories), for the
/// kinds the brand gives no colour of their own ([VisionStyle.objects]). Bright
/// enough to read over video, and apart from the people's cyan and from the
/// red and accent of an alert.
const visionObjectColors = [
  Color(0xFFFF8A3D), // orange
  Color(0xFF9BE564), // lime
  Color(0xFFFF6FB5), // pink
  Color(0xFFB79BFF), // violet
  Color(0xFFFFD84D), // yellow
  Color(0xFF5EEAD4), // teal
  Color(0xFFF5F5F4), // white
];

Color visionObjectColor(int kind) => visionObjectColors[kind % visionObjectColors.length];

/// The colour of an alert's [tone]: a risk in the theme's error red, an
/// opportunity in its accent (or blue, when the accent is a red too and the
/// two would read the same).
Color visionToneColor(P4Colors p4, VisionTone tone) {
  if (tone == VisionTone.review) return p4.err;
  final (a, e) = (HSVColor.fromColor(p4.accent), HSVColor.fromColor(p4.err));
  final apart = (a.hue - e.hue).abs();
  return (apart > 180 ? 360 - apart : apart) < 30 ? p4.blue : p4.accent;
}

/// The alert [scene] asks for on a camera covering [zones], or null.
VisionAlertRule? visionAlert(VisionBundle bundle, VisionScene scene, List<String> zones) {
  final b = scene.behavior;
  if (b == null) return null;
  return bundle.alertFor(b.behavior, b.zone != null ? [b.zone!] : zones);
}

/// What the vision model sees on one camera, drawn over its video: a box for
/// each person (with their track id and the detector's confidence when
/// [detailed]), a box for each object in its kind's colour (named when
/// [detailed], with a key to the colours), what the behaviour model says one
/// of them is doing, and,
/// when that asks for it, the alert: the person's box and the whole camera in
/// the alert's colour, pulsing, with its name.
///
/// [frame] is the video's frame size, for fitting the boxes the way the video
/// is fitted (contained, centred); without it, the scene's own.
class VisionOverlay extends StatelessWidget {
  const VisionOverlay({
    super.key,
    required this.scene,
    required this.bundle,
    this.zones = const [],
    this.frame,
    this.detailed = false,
    this.bottomInset = 0,
  });

  final VisionScene scene;
  final VisionBundle bundle;

  /// The zones the camera covers (see [VisionCamera.zones]).
  final List<String> zones;
  final Size? frame;

  /// One camera on its own: room for track tags and the people count.
  final bool detailed;

  /// Space to leave at the bottom (the grid's caption bar).
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final lang = context.l10n.localeName;
    final alert = visionAlert(bundle, scene, zones);
    final tone = alert == null ? null : visionToneColor(p4, alert.tone);
    final behavior = scene.behavior;
    final frame = this.frame ?? scene.frame;
    final style = BrandScope.maybeOf(context)?.vision ?? VisionStyle.standard;
    final people = style.people ?? hudColor;
    Color objectColor(int kind) => style.objects[bundle.objects.elementAtOrNull(kind)?.id] ?? visionObjectColor(kind);
    final objects = style.showObjects ? scene.objects : const <VisionObject>[];
    final tags = detailed && style.showTags;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final view = Offset.zero & box.biggest;
          final video = frame == null || frame.isEmpty
              ? view
              : Alignment.center.inscribe(applyBoxFit(BoxFit.contain, frame, view.size).destination, view);
          Rect place(Rect r) => Rect.fromLTRB(
            video.left + r.left * video.width,
            video.top + r.top * video.height,
            video.left + r.right * video.width,
            video.top + r.bottom * video.height,
          );
          final focus = alert == null ? null : behavior!.track;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HudPainter(
                    boxes: [for (final b in scene.boxes) (place(b.rect), b.track == focus)],
                    objects: [for (final o in objects) (place(o.rect), objectColor(o.kind))],
                    people: people,
                    view: view,
                    reticle: detailed ? 22 : 14,
                    tone: tone,
                  ),
                ),
              ),
              if (tags)
                for (final (at, tag) in _placeTags(context, [
                  for (final b in scene.boxes)
                    (
                      place(b.rect).topLeft,
                      _Tag(
                        [
                          '#${b.track} · ${(b.confidence * 100).round()}%',
                          if (behavior != null && behavior.track == b.track)
                            bundle.behaviorLabel(behavior.behavior, lang),
                        ].join(' · '),
                        color: b.track == focus ? tone! : people,
                      ),
                    ),
                  for (final o in [...objects]..sort((a, b) => b.confidence.compareTo(a.confidence)))
                    (
                      place(o.rect).topLeft,
                      _Tag(
                        '${bundle.objectLabel(o.kind, lang)} ${(o.confidence * 100).round()}%',
                        color: objectColor(o.kind),
                        small: true,
                      ),
                    ),
                ]))
                  Positioned(left: at.dx, top: at.dy, child: tag),
              if (detailed && style.showKey && style.showObjects && bundle.objects.isNotEmpty)
                Positioned(
                  // Below the video's own label ("Video · MP4")
                  top: 34,
                  left: 10,
                  child: _Key([
                    (context.l10n.visionPerson, people),
                    for (final (i, _) in bundle.objects.indexed) (bundle.objectLabel(i, lang), objectColor(i)),
                  ]),
                ),
              if (tone != null) Positioned.fill(child: _AlertRing(color: tone)),
              if (alert != null)
                Positioned(
                  top: 10,
                  right: 10,
                  left: detailed ? null : 10,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _Flag(
                      code: alert.code,
                      title: alert.titleIn(lang),
                      color: tone!,
                      review: alert.tone == VisionTone.review,
                    ),
                  ),
                ),
              if (behavior != null || detailed)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: bottomInset + 8,
                  child: _Strip(
                    behavior: behavior == null ? null : bundle.behaviorLabel(behavior.behavior, lang),
                    zone: bundle.zoneLabel(behavior?.zone ?? zones.firstOrNull, lang),
                    people: detailed ? context.l10n.visionPeople(scene.boxes.length) : null,
                    color: tone,
                    hud: people,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// [tags] on the top edge of their boxes, in order, leaving out any that
/// would cover one already placed or run off the top: people's first, so
/// theirs always show.
List<(Offset, _Tag)> _placeTags(BuildContext context, List<(Offset, _Tag)> tags) {
  final placed = <Rect>[];
  final out = <(Offset, _Tag)>[];
  for (final (corner, tag) in tags) {
    final size = tag.measure(context);
    final rect = Offset(corner.dx, corner.dy - size.height - 1) & size;
    if (rect.top < 0 || placed.any((p) => p.overlaps(rect))) continue;
    placed.add(rect);
    out.add((rect.topLeft, tag));
  }
  return out;
}

class _HudPainter extends CustomPainter {
  _HudPainter({
    required this.boxes,
    required this.view,
    required this.reticle,
    this.objects = const [],
    this.people = hudColor,
    this.tone,
  });

  /// Each box in pixels, and whether it's the person the alert is about.
  final List<(Rect, bool)> boxes;

  /// Each object's box in pixels, and its kind's colour.
  final List<(Rect, Color)> objects;
  final Rect view;
  final double reticle;

  /// People's boxes and the corners' colour.
  final Color people;
  final Color? tone;

  @override
  void paint(Canvas canvas, Size size) {
    // Corner reticles: the HUD is on.
    final inset = reticle * 0.6;
    final r = Paint()
      ..color = people.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    _corners(canvas, view.deflate(inset), reticle, r);

    // Objects under the people, lighter: what someone holds stays theirs
    for (final (rect, color) in objects) {
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.08));
      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
      _corners(
        canvas,
        rect,
        5,
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    for (final (rect, focus) in boxes) {
      final color = focus ? tone! : people;
      if (focus) canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.14));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..color = color.withValues(alpha: focus ? 0.9 : 0.55)
          ..strokeWidth = focus ? 2 : 1
          ..style = PaintingStyle.stroke,
      );
      _corners(
        canvas,
        rect,
        focus ? 10 : 7,
        Paint()
          ..color = color
          ..strokeWidth = focus ? 2.5 : 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  /// An L at each corner of [r], [len] long.
  static void _corners(Canvas canvas, Rect r, double len, Paint paint) {
    final l = len.clamp(0.0, r.shortestSide / 2);
    final path = Path()
      ..moveTo(r.left, r.top + l)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left + l, r.top)
      ..moveTo(r.right - l, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + l)
      ..moveTo(r.left, r.bottom - l)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left + l, r.bottom)
      ..moveTo(r.right - l, r.bottom)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.right, r.bottom - l);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HudPainter old) =>
      old.view != view ||
      old.tone != tone ||
      old.people != people ||
      old.reticle != reticle ||
      !_sameBoxes(old.boxes, boxes) ||
      !_sameBoxes(old.objects, objects);

  static bool _sameBoxes<T>(List<(Rect, T)> a, List<(Rect, T)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// What a box is, on its top edge: a person's track id and confidence, or an
/// object's kind ([small]).
class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color, this.small = false});

  final String text;
  final Color color;
  final bool small;

  EdgeInsets get _padding => EdgeInsets.symmetric(horizontal: small ? 4 : 5, vertical: small ? 0 : 1);

  TextStyle _style(BuildContext context) =>
      context.p4.mono(size: small ? 9 : 10, color: _ink(color), spacing: 0.05, weight: FontWeight.w600);

  /// How big it draws, for keeping tags apart.
  Size measure(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _style(context)),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final size = _padding.inflateSize(painter.size);
    painter.dispose();
    return size;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: _padding,
    color: color,
    child: Text(text, style: _style(context)),
  );
}

/// Which colour is which: a dot and a name for each.
class _Key extends StatelessWidget {
  const _Key(this.entries);

  final List<(String, Color)> entries;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xCC05080A), borderRadius: BorderRadius.circular(7)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 3,
        children: [
          for (final (name, color) in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(border: Border.all(color: color, width: 1.5)),
                ),
                const SizedBox(width: 6),
                Text(name, style: p4.mono(size: 10, color: P4Colors.dark.text, spacing: 0)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Dark text on a light colour, light on a dark one.
Color _ink(Color background) => background.computeLuminance() > 0.4 ? const Color(0xFF04181C) : const Color(0xFFFFFFFF);

/// What's going on, at the bottom: the behaviour and the zone (and, on its
/// own, how many people are in view).
class _Strip extends StatelessWidget {
  const _Strip({this.behavior, this.zone, this.people, this.color, this.hud = hudColor});

  final String? behavior;
  final String? zone;
  final String? people;
  final Color? color;

  /// The people's colour, for the count and the border when there's no alert.
  final Color hud;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final light = P4Colors.dark;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xCC05080A),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: (color ?? hud).withValues(alpha: color == null ? 0.25 : 0.8)),
        ),
        child: Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (behavior != null)
              Text(
                behavior!,
                style: p4.body(size: 12, color: light.text, weight: FontWeight.w600),
              ),
            if (zone != null) Text(zone!, style: p4.mono(size: 10, color: light.muted, spacing: 0)),
            if (people != null) Text(people!, style: p4.mono(size: 10, color: hud, spacing: 0)),
          ],
        ),
      ),
    );
  }
}

/// The alert's name, in its colour, at the top of the camera.
class _Flag extends StatelessWidget {
  const _Flag({required this.code, required this.title, required this.color, required this.review});

  final String code;
  final String title;
  final Color color;
  final bool review;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(review ? Icons.report_outlined : Icons.person_search_outlined, size: 13, color: _ink(color)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$code · $title',
            overflow: TextOverflow.ellipsis,
            style: context.p4.mono(size: 10.5, color: _ink(color), weight: FontWeight.w700, spacing: 0.04),
          ),
        ),
      ],
    ),
  );
}

/// A border around the whole camera that breathes while the alert lasts
/// (steady when animations are off).
class _AlertRing extends StatefulWidget {
  const _AlertRing({required this.color});

  final Color color;

  @override
  State<_AlertRing> createState() => _AlertRingState();
}

class _AlertRingState extends State<_AlertRing> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (context, _) {
      final t = Curves.easeInOut.transform(_pulse.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.color.withValues(alpha: 0.55 + 0.45 * t),
            width: 2 + 1.5 * t,
          ),
        ),
      );
    },
  );
}
