import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:http/http.dart' as http;

import '../core/settings.dart';
import 'project.dart' show ApiWatcher;

/// Whether an alert asks a person to check something (a risk) or to attend
/// someone (an opportunity, someone looking for help).
enum VisionTone { info, review }

/// What the Video tab draws over the cameras, from p4n4-api
/// (`GET /api/v1/project/vision`, the file `.p4n4.json` `dashboard.vision`
/// names): each camera's recorded boxes and behaviours, the words for them,
/// and the rules that turn a behaviour into an alert. See README.md, "Vision
/// overlay".
class VisionBundle {
  const VisionBundle({
    this.behaviors = const {},
    this.zones = const {},
    this.alerts = const [],
    this.cameras = const {},
    this.objects = const [],
    this.live,
  });

  /// Lenient, like the project manifest: what doesn't parse is left out.
  factory VisionBundle.fromJson(Map<String, dynamic> j) => VisionBundle(
    behaviors: _labelMap(j['behaviors']),
    zones: _labelMap(j['zones']),
    alerts: [
      if (j['alerts'] case final List list)
        for (final r in list.whereType<Map>()) ?VisionAlertRule.fromJson(r.cast()),
    ],
    cameras: {
      if (j['cameras'] case final Map cams)
        for (final MapEntry(:key, :value) in cams.entries)
          if (key is String && value is Map) key: VisionCamera.fromJson(value.cast()),
    },
    objects: [
      if (j['objects'] case final List list)
        for (final o in list)
          if (o case {'id': final String id})
            (id: id, labels: o['label'] is Map ? _strings(o['label'] as Map) : const {}),
    ],
    live: switch (j['live']) {
      final Map m => VisionLive.fromJson(m.cast()),
      _ => null,
    },
  );

  /// Behaviour class → language code → label.
  final Map<String, Map<String, String>> behaviors;

  /// Zone id → language code → label.
  final Map<String, Map<String, String>> zones;

  /// The first that fits a behaviour wins, so the specific ones come first.
  final List<VisionAlertRule> alerts;
  final Map<String, VisionCamera> cameras;

  /// The kinds of object a recording's [VisionObject]s are, in order (their
  /// [VisionObject.kind] is an index here), such as a store's garment categories.
  /// Their order also picks their colour on the overlay.
  final List<({String id, Map<String, String> labels})> objects;

  /// Camera [id]'s vision, also for a brand's demo camera, which plays that
  /// camera's clip under the id `demo-<id>` ([Brand.demoCamerasOn]).
  VisionCamera? camera(String id) => cameras[id] ?? (id.startsWith(_demo) ? cameras[id.substring(_demo.length)] : null);

  static const _demo = 'demo-';

  /// Where detections stream live, if anywhere.
  final VisionLive? live;

  String behaviorLabel(String behavior, String lang) =>
      _pick(behaviors[behavior], lang) ?? behavior.replaceAll('_', ' ');

  String? zoneLabel(String? zone, String lang) => zone == null ? null : _pick(zones[zone], lang) ?? zone;

  String objectLabel(int kind, String lang) => switch (objects.elementAtOrNull(kind)) {
    final o? => _pick(o.labels, lang) ?? o.id.replaceAll('_', ' '),
    null => '#$kind',
  };

  /// The alert [behavior] asks for in [zones] (the verdict's zone, or every
  /// zone the camera covers), or null.
  VisionAlertRule? alertFor(String behavior, Iterable<String> zones) {
    for (final rule in alerts) {
      if (!rule.behaviors.contains(behavior)) continue;
      if (rule.zones case final only? when !zones.any(only.contains)) continue;
      return rule;
    }
    return null;
  }

  static Map<String, Map<String, String>> _labelMap(Object? raw) => {
    if (raw case final Map m)
      for (final MapEntry(:key, :value) in m.entries)
        if (key is String && value is Map) key: _strings(value),
  };
}

/// [labels] in [lang] (a locale name such as `es` or `pt_BR`), else English,
/// else Spanish (the vocabulary's own), else whichever there is.
String? _pick(Map<String, String>? labels, String lang) {
  if (labels == null || labels.isEmpty) return null;
  final code = lang.split(RegExp('[_-]')).first.toLowerCase();
  return labels[code] ?? labels['en'] ?? labels['es'] ?? labels.values.first;
}

Map<String, String> _strings(Map m) => {
  for (final MapEntry(:key, :value) in m.entries)
    if (key is String && value is String) key: value,
};

class VisionAlertRule {
  const VisionAlertRule({
    required this.code,
    required this.behaviors,
    required this.title,
    this.tone = VisionTone.info,
    this.zones,
    this.suggestion = const {},
  });

  static VisionAlertRule? fromJson(Map<String, dynamic> j) {
    final (code, behaviors, title) = (j['code'], j['behaviors'], j['title']);
    if (code is! String || behaviors is! List || title is! Map) return null;
    return VisionAlertRule(
      code: code,
      tone: j['tone'] == 'review' ? VisionTone.review : VisionTone.info,
      behaviors: {...behaviors.whereType<String>()},
      zones: switch (j['zones']) {
        final List z => {...z.whereType<String>()},
        _ => null,
      },
      title: _strings(title),
      suggestion: j['suggestion'] is Map ? _strings(j['suggestion'] as Map) : const {},
    );
  }

  final String code;
  final VisionTone tone;
  final Set<String> behaviors;

  /// Null: any zone.
  final Set<String>? zones;
  final Map<String, String> title;
  final Map<String, String> suggestion;

  String titleIn(String lang) => _pick(title, lang) ?? code;

  String? suggestionIn(String lang) => _pick(suggestion, lang);
}

/// The live stream's address, resolved against the connected host like the
/// manifest's cameras.
class VisionLive {
  const VisionLive({this.url, this.port, this.path = '/'});

  factory VisionLive.fromJson(Map<String, dynamic> j) =>
      VisionLive(url: j['url'] as String?, port: (j['port'] as num?)?.toInt(), path: (j['path'] as String?) ?? '/');

  final String? url;
  final int? port;
  final String path;

  /// Null when there's neither a ws(s) URL nor a port.
  Uri? on(String host) {
    if (url case final u?) {
      final uri = Uri.tryParse(u);
      return uri != null && (uri.scheme == 'ws' || uri.scheme == 'wss') && uri.host.isNotEmpty ? uri : null;
    }
    if (port case final p? when p > 0 && p < 65536) return Uri.tryParse('ws://$host:$p$path');
    return null;
  }
}

class VisionCamera {
  const VisionCamera({this.zones = const [], this.recording});

  factory VisionCamera.fromJson(Map<String, dynamic> j) => VisionCamera(
    zones: [...?(j['zones'] as List?)?.whereType<String>()],
    recording: switch (j['recording']) {
      final Map m => VisionRecording.fromJson(m.cast()),
      _ => null,
    },
  );

  /// The zones this camera covers: what a rule with zones checks a behaviour
  /// against when the behaviour doesn't name its own.
  final List<String> zones;

  /// A video-file camera's boxes and behaviours, by the second of the clip.
  final VisionRecording? recording;
}

/// One person on screen: a box normalised to the frame (0..1).
class VisionBox {
  const VisionBox(this.track, this.rect, this.confidence);

  final int track;
  final Rect rect;
  final double confidence;
}

/// Something other than a person the detector found (a garment, a bag): a
/// box normalised to the frame, and its [kind], an index into
/// [VisionBundle.objects]. Objects aren't tracked, so they carry no id.
class VisionObject {
  const VisionObject(this.kind, this.rect, this.confidence);

  final int kind;
  final Rect rect;
  final double confidence;
}

/// What the model said someone was doing.
class VisionBehavior {
  const VisionBehavior({required this.track, required this.behavior, required this.confidence, this.zone, this.key});

  final int track;
  final String behavior;
  final double confidence;

  /// The verdict's own zone; null for a recording (the camera's zones apply).
  final String? zone;

  /// This occurrence: the same window in the clip's next loop is a new one.
  final String? key;
}

/// What's on screen at one instant: the boxes, and what the person the
/// behaviour is about is doing. [frame] is the boxes' frame size, when known,
/// for fitting them over a video whose own size isn't.
class VisionScene {
  const VisionScene({this.boxes = const [], this.objects = const [], this.behavior, this.frame});

  static const empty = VisionScene();

  /// The people.
  final List<VisionBox> boxes;

  /// Everything else the detector found.
  final List<VisionObject> objects;
  final VisionBehavior? behavior;
  final Size? frame;

  bool get isEmpty => boxes.isEmpty && objects.isEmpty && behavior == null;
}

/// A clip's boxes and behaviours, by the second, from the project's
/// measurements (e.g. an object detector's boxes and a behaviour model's
/// windows, run on the very clips the demo cameras play).
class VisionRecording {
  const VisionRecording({
    required this.duration,
    required this.samples,
    this.objects = const [],
    this.segments = const [],
    this.frame,
  });

  factory VisionRecording.fromJson(Map<String, dynamic> j) {
    final (w, h) = (j['width'], j['height']);
    return VisionRecording(
      duration: (j['duration'] as num).toDouble(),
      frame: w is num && h is num && w > 0 && h > 0 ? Size(w.toDouble(), h.toDouble()) : null,
      samples: [
        for (final s in (j['boxes'] as List?) ?? const [])
          if (s case [final num t, final List boxes])
            (
              t.toDouble(),
              [
                for (final b in boxes)
                  if (b case [final num id, final num x1, final num y1, final num x2, final num y2, final num c])
                    VisionBox(
                      id.toInt(),
                      Rect.fromLTRB(x1.toDouble(), y1.toDouble(), x2.toDouble(), y2.toDouble()),
                      c.toDouble(),
                    ),
              ],
            ),
      ],
      objects: [
        for (final s in (j['objects'] as List?) ?? const [])
          if (s case [final num t, final List found])
            (
              t.toDouble(),
              [
                for (final o in found)
                  if (o case [final num k, final num x1, final num y1, final num x2, final num y2, final num c])
                    VisionObject(
                      k.toInt(),
                      Rect.fromLTRB(x1.toDouble(), y1.toDouble(), x2.toDouble(), y2.toDouble()),
                      c.toDouble(),
                    ),
              ],
            ),
      ],
      segments: [
        for (final s in (j['behaviors'] as List?) ?? const [])
          if (s case [final num start, final num end, final num id, final String behavior, final num c])
            (
              start: start.toDouble(),
              end: end.toDouble(),
              track: id.toInt(),
              behavior: behavior,
              confidence: c.toDouble(),
            ),
      ],
    );
  }

  /// Seconds; the clip loops, and so do its boxes.
  final double duration;
  final Size? frame;

  /// `(t, boxes)`, in order of t.
  final List<(double, List<VisionBox>)> samples;

  /// `(t, objects)`, in order of t: sampled on their own clock, so a sample
  /// with none means the detector saw none then.
  final List<(double, List<VisionObject>)> objects;
  final List<({double start, double end, int track, String behavior, double confidence})> segments;

  /// A box the detector lost for a frame or two (someone turns, a rack hides
  /// them) is held over a gap this long, as the edge's tracker does. Past it
  /// nothing is made up: if the model saw no one, no one is drawn.
  static const coast = 0.4;

  /// What's on screen [seconds] into playback (any number of loops in).
  VisionScene sceneAt(double seconds) {
    if (duration <= 0) return VisionScene.empty;
    final at = seconds % duration;
    final pass = (seconds / duration).floor();
    return VisionScene(boxes: _boxesAt(at), objects: _objectsAt(at), behavior: _behaviorAt(at, pass), frame: frame);
  }

  /// [sceneAt]'s behaviour alone, without working out the boxes.
  VisionBehavior? behaviorAt(double seconds) =>
      duration <= 0 ? null : _behaviorAt(seconds % duration, (seconds / duration).floor());

  List<VisionBox> _boxesAt(double at) {
    final idx = _lastAtOrBefore(at);
    if (idx < 0) return const [];
    final prev = samples[idx].$2.isNotEmpty ? samples[idx] : _nearestWithBoxes(idx, -1);
    if (prev == null || at - prev.$1 > coast) return const [];
    // Interpolate towards the next sample with people, so a box walks with
    // the person instead of jumping every few frames. Not across the loop's
    // seam: the person at the end isn't the one at the start.
    final next = _nearestWithBoxes(idx + 1, 1);
    final span = next == null ? 0.0 : next.$1 - prev.$1;
    final k = next != null && span > 0 && span <= coast * 2 ? math.min(1.0, (at - prev.$1) / span) : 0.0;
    final ahead = {for (final b in next?.$2 ?? const <VisionBox>[]) b.track: b};
    return [
      for (final b in prev.$2)
        switch (k > 0 ? ahead[b.track] : null) {
          final to? => VisionBox(b.track, Rect.lerp(b.rect, to.rect, k)!, b.confidence),
          null => b,
        },
    ];
  }

  /// The objects of the sample at or before [at], each walking towards its
  /// match in the next sample (the same kind, overlapping most), as people's
  /// boxes do. Held no longer than [coast] past their sample.
  List<VisionObject> _objectsAt(double at) {
    var idx = -1;
    for (var (lo, hi) = (0, objects.length - 1); lo <= hi;) {
      final mid = (lo + hi) >> 1;
      if (objects[mid].$1 <= at) {
        idx = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (idx < 0 || at - objects[idx].$1 > coast) return const [];
    final (t0, now) = objects[idx];
    final next = idx + 1 < objects.length ? objects[idx + 1] : null;
    final span = next == null ? 0.0 : next.$1 - t0;
    if (next == null || span <= 0 || span > coast * 2) return now;
    final k = math.min(1.0, (at - t0) / span);
    return [
      for (final o in now)
        switch (_match(o, next.$2)) {
          final to? => VisionObject(o.kind, Rect.lerp(o.rect, to.rect, k)!, o.confidence),
          null => o,
        },
    ];
  }

  /// The object of [o]'s kind in [among] that overlaps it most, if any overlaps
  /// it by a third (IoU), as a tracker matches between frames.
  static VisionObject? _match(VisionObject o, List<VisionObject> among) {
    VisionObject? best;
    var bestIou = 0.3;
    for (final c in among) {
      if (c.kind != o.kind) continue;
      final i = o.rect.intersect(c.rect);
      if (i.width <= 0 || i.height <= 0) continue;
      final inter = i.width * i.height;
      final iou = inter / (o.rect.width * o.rect.height + c.rect.width * c.rect.height - inter);
      if (iou > bestIou) (best, bestIou) = (c, iou);
    }
    return best;
  }

  VisionBehavior? _behaviorAt(double at, int pass) {
    for (final s in segments) {
      if (at >= s.start && at < s.end) {
        return VisionBehavior(track: s.track, behavior: s.behavior, confidence: s.confidence, key: '$pass|${s.start}');
      }
    }
    return null;
  }

  /// The last sample at or before [t], or -1.
  int _lastAtOrBefore(double t) {
    var (lo, hi, found) = (0, samples.length - 1, -1);
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (samples[mid].$1 <= t) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found;
  }

  (double, List<VisionBox>)? _nearestWithBoxes(int from, int step) {
    for (var i = from; i >= 0 && i < samples.length; i += step) {
      if (samples[i].$2.isNotEmpty) return samples[i];
    }
    return null;
  }
}

/// `GET /api/v1/project/vision`: null when the project has none (204, or 404
/// from a p4n4-api that predates it).
Future<VisionBundle?> fetchVision(Uri apiBase) async {
  final res = await http.get(apiBase.resolve('api/v1/project/vision')).timeout(const Duration(seconds: 10));
  return switch (res.statusCode) {
    200 => VisionBundle.fromJson((jsonDecode(utf8.decode(res.bodyBytes)) as Map).cast()),
    204 || 404 => null,
    final code => throw http.ClientException('HTTP $code', res.request?.url),
  };
}

/// Keeps [AppSettings.vision] in step with the connected deployment.
class VisionWatcher extends ApiWatcher<VisionBundle?> {
  VisionWatcher(super.settings, {super.fetch = fetchVision, super.retry}) : super(apply: (v) => settings.vision = v);
}
