import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/vision.dart';
import '../core/feed_moments.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import 'video_view.dart';
import 'vision_overlay.dart';

/// A camera's clip held on a feed item's moment: the video paused where it
/// starts, with the vision overlay's boxes as they were then, and a button
/// that plays it again from [lead] seconds before to the moment's end, then
/// holds it again. Under it, the camera and when the moment played. When the
/// moment names the players it's about ([FeedMoment.focus]), a close-up of
/// them sits in a corner, framed in the alert's red, and follows them through
/// the replay.
class MomentView extends StatefulWidget {
  const MomentView({super.key, required this.moment, this.active = true, this.lead = 4});

  final FeedMoment moment;

  /// When false playback is paused (e.g. the tab is hidden).
  final bool active;

  /// Seconds of build-up a replay starts with.
  final double lead;

  @override
  State<MomentView> createState() => _MomentViewState();
}

class _MomentViewState extends State<MomentView> {
  P4Colors get p4 => context.p4;

  var _replays = 0;
  var _replaying = false;

  /// The close-up's last crop, and when (seconds into the clip): it's held a
  /// moment while the players it follows blink out of the detector's sight.
  Rect? _crop;
  double _cropAt = 0;
  static const _holdCrop = 1.0;

  Rect? _closeup(Rect? crop, double at) {
    if (crop != null) {
      _crop = crop;
      _cropAt = at;
      return crop;
    }
    return (at - _cropAt).abs() <= _holdCrop ? _crop : null;
  }

  @override
  void didUpdateWidget(MomentView old) {
    super.didUpdateWidget(old);
    if (old.moment.start != widget.moment.start || old.moment.camera.id != widget.moment.camera.id) {
      _replaying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = widget.moment;
    final s = SettingsScope.of(context);
    // An admin can turn the overlay off for a view (Settings → Views).
    final bundle = s.prefsFor(SessionScope.of(context).role ?? Role.normie).overlay ? s.vision : null;
    final vc = bundle?.camera(m.camera.id);
    final recording = vc?.recording;
    final uri = m.camera.uri;
    final VideoHold hold = (at: m.start, from: math.max(0, m.start - widget.lead), to: m.end, replay: _replays);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: uri == null
              ? Center(
                  child: Text(l.cameraInvalidUrl(m.camera.name), style: p4.body(color: p4.err)),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoView(
                      uri: uri,
                      active: widget.active,
                      hold: hold,
                      onReplayed: () => setState(() => _replaying = false),
                      overlay: recording == null
                          ? null
                          : (context, playback) {
                              final scene = recording.sceneAt(playback.seconds);
                              final frame = playback.size ?? recording.frame;
                              final drawn = VisionOverlay(
                                scene: scene,
                                bundle: bundle!,
                                kinds: recording.kinds,
                                zones: vc?.zones ?? const [],
                                frame: frame,
                              );
                              if (!m.focused || frame == null) return drawn;
                              final crop = _closeup(
                                momentCrop(scene.boxes, m.focus, frame, objects: scene.objects, kinds: m.focusKinds),
                                playback.seconds,
                              );
                              return LayoutBuilder(
                                builder: (context, box) {
                                  // The picture's height as shown (contained in the view)
                                  final shownHeight = math.min(
                                    box.maxHeight,
                                    box.maxWidth * frame.height / frame.width,
                                  );
                                  final width = shownHeight * closeupHeight * closeupAspect;
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      drawn,
                                      // Top left, under the video's label: the bottom holds the behaviour,
                                      // the credits, and on footage like the archive's, its own credit
                                      Positioned(
                                        left: 10,
                                        top: 36,
                                        child: _Closeup(
                                          uri: uri,
                                          hold: hold,
                                          active: widget.active,
                                          crop: crop,
                                          frame: frame,
                                          width: width,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                    ),
                    if (m.camera.credit case final credit?) VideoCredit(credit),
                  ],
                ),
        ),
        Container(
          color: p4.bg2,
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Icon(_replaying ? Icons.play_arrow : Icons.pause, size: 18, color: p4.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    m.camera.name,
                    context.formats.clock(m.seen.toLocal(), seconds: true),
                    _replaying ? l.momentReplaying : l.momentHeld,
                  ].join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: p4.body(size: 13, color: p4.muted),
                ),
              ),
              TextButton.icon(
                onPressed: uri == null
                    ? null
                    : () => setState(() {
                        _replays++;
                        _replaying = true;
                      }),
                icon: const Icon(Icons.replay, size: 18),
                label: Text(l.momentReplay),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The part of the frame a close-up of the [focus] tracks shows, as a share of
/// it (0-1): their boxes among [boxes] (and those of [objects] of the [kinds]
/// it's about, such as the ball), with room around them, widened to
/// [aspect] (in pixels of a [frame]-sized picture) and kept inside the frame.
/// Never closer than [_closest] of the frame's height (a far player isn't blown
/// up past what the picture holds). Null when none of them is on screen, or
/// when they're already big in the frame (a close-up would show them no closer).
@visibleForTesting
Rect? momentCrop(
  List<VisionBox> boxes,
  List<int> focus,
  Size frame, {
  List<VisionObject> objects = const [],
  List<int> kinds = const [],
  double aspect = closeupAspect,
}) {
  final rects = [
    for (final b in boxes)
      if (focus.contains(b.track)) b.rect,
    for (final o in objects)
      if (kinds.contains(o.kind)) o.rect,
  ];
  if (rects.isEmpty || frame.isEmpty) return null;
  final union = rects.reduce((a, b) => a.expandToInclude(b));
  var px = Rect.fromLTRB(
    union.left * frame.width,
    union.top * frame.height,
    union.right * frame.width,
    union.bottom * frame.height,
  );
  px = px.inflate(0.25 * math.max(px.width, px.height));
  var h = math.max(px.height, _closest * frame.height);
  var w = math.max(px.width, h * aspect);
  h = math.max(h, w / aspect);
  if (h > _tallest * frame.height || w > frame.width) return null;
  final left = (px.center.dx - w / 2).clamp(0.0, frame.width - w);
  final top = (px.center.dy - h / 2).clamp(0.0, frame.height - h);
  return Rect.fromLTWH(left / frame.width, top / frame.height, w / frame.width, h / frame.height);
}

/// The close-up's shape (standing players), and its height as a share of the picture's.
const closeupAspect = 4 / 3, closeupHeight = 0.38;

/// A crop this share of the frame's height at least (about twice as close as the picture), and at most (as close).
const _closest = 0.18, _tallest = closeupHeight * 1.15;

/// A close-up of [crop] (a share of the [frame]), [width] wide at [closeupAspect]: a
/// second copy of the clip, held and replayed with the first ([hold]), drawn
/// scaled and cut to the crop (a video can't be read back for its pixels on
/// web). It stays, unseen, while the players are off screen, so it keeps in step.
class _Closeup extends StatelessWidget {
  const _Closeup({
    required this.uri,
    required this.hold,
    required this.active,
    required this.crop,
    required this.frame,
    required this.width,
  });

  final Uri uri;
  final VideoHold hold;
  final bool active;
  final Rect? crop;
  final Size frame;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final height = width / closeupAspect;
    final shown = crop ?? const Rect.fromLTWH(0, 0, 1, 1);
    // The whole picture at the scale that makes the crop fill the close-up
    final scale = width / (shown.width * frame.width);
    final (fullW, fullH) = (frame.width * scale, frame.height * scale);
    return IgnorePointer(
      child: Opacity(
        opacity: crop == null ? 0 : 1,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: p4.err, width: 2)),
          child: ClipRect(
            child: SizedBox(
              width: width,
              height: height,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: fullW,
                maxWidth: fullW,
                minHeight: fullH,
                maxHeight: fullH,
                child: Transform.translate(
                  offset: Offset(-shown.left * fullW, -shown.top * fullH),
                  child: VideoView(uri: uri, active: active, hold: hold, chrome: false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
