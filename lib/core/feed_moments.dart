import 'package:flutter/foundation.dart';

import '../api/camera.dart';

/// Where and when a feed item's moment last played: a measured clip's
/// behaviour that names the item (README, "Vision overlay"), [start] to [end]
/// seconds into [camera]'s clip, [seen] on this device's clock.
class FeedMoment {
  const FeedMoment({
    required this.item,
    required this.camera,
    required this.start,
    required this.end,
    required this.seen,
    this.focus = const [],
    this.focusKinds = const [],
  });

  final String item;
  final Camera camera;
  final double start;
  final double end;
  final DateTime seen;

  /// The tracks the moment is about, which its view zooms on ([VisionBehavior.focus]).
  final List<int> focus;

  /// The kinds of object it's about too, e.g. the ball ([VisionBehavior.focusKinds]).
  final List<int> focusKinds;

  /// Whether there's anything to zoom on.
  bool get focused => focus.isNotEmpty || focusKinds.isNotEmpty;
}

/// The feed items the cameras' clips are about, and when each last played.
/// While the clips link any ([active]), the Feed tab shows those items only
/// once their moment has played, newest first, as if they had just happened,
/// and opens each on its moment. Items no clip links to are shown as usual.
class FeedMoments extends ChangeNotifier {
  FeedMoments({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  Set<String> _linked = const {};
  final _played = <String, FeedMoment>{};

  /// The items the followed cameras' clips have moments about.
  Set<String> get linked => _linked;

  bool get active => _linked.isNotEmpty;

  /// [item]'s moment, once it has played.
  FeedMoment? operator [](String item) => _played[item];

  /// Whether the feed shows [item] now: one no clip links to always, a linked one once it has played.
  bool shows(String item) => !_linked.contains(item) || _played.containsKey(item);

  /// The items the cameras' clips link to now; what no clip links to any more is forgotten.
  void link(Set<String> items) {
    if (setEquals(items, _linked)) return;
    _linked = items;
    _played.removeWhere((item, _) => !items.contains(item));
    notifyListeners();
  }

  /// [item]'s moment has just started playing on [camera].
  FeedMoment played(
    String item,
    Camera camera,
    double start,
    double end, {
    List<int> focus = const [],
    List<int> focusKinds = const [],
  }) {
    final moment = _played[item] = FeedMoment(
      item: item,
      camera: camera,
      start: start,
      end: end,
      seen: _now(),
      focus: focus,
      focusKinds: focusKinds,
    );
    notifyListeners();
    return moment;
  }
}
