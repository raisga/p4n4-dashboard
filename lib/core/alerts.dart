import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/feed.dart';
import '../api/vision.dart' show VisionTone;
import '../platform/chime.dart';

/// Something that asks a person to look, shown as a toast on every tab: an
/// alert the vision overlay raised from what's on a camera, or a new one in
/// the project's feed.
class AlertNotice {
  AlertNotice({
    required this.id,
    required this.title,
    this.tone = VisionTone.info,
    this.code,
    this.where,
    this.detail,
    this.camera,
    this.fromFeed = false,
  });

  final String id;
  final VisionTone tone;

  /// The alert's name ("Loss risk — review").
  final String title;

  /// Its short code ("A4"), if it has one.
  final String? code;

  /// Which camera, and what was seen ("Fitting rooms · Tries it on").
  final String? where;

  /// What to do about it.
  final String? detail;

  /// The camera to open, if known.
  final String? camera;

  /// From the feed: opens the Feed when there's no camera to show.
  final bool fromFeed;
}

/// The alerts on screen, newest first: raising one shows it for a while
/// (longer for a risk, which also chimes) and drops the oldest past [maxShown].
/// The same alert on the same camera is shown once per [cooldown]: a demo
/// clip loops every few seconds, and a person lingers.
class AlertCenter extends ChangeNotifier {
  AlertCenter({
    this.sound,
    this.accept,
    Future<void> Function()? chime,
    this.cooldown = const Duration(seconds: 60),
    this.maxShown = 3,
    DateTime Function()? now,
  }) : _chime = chime ?? playChime,
       _now = now ?? DateTime.now;

  /// Whether to chime; read at each alert, so the setting applies at once.
  final bool Function()? sound;

  /// Whether this view shows [AlertNotice] at all (Settings → Views → Alerts);
  /// read at each alert, like [sound].
  final bool Function(AlertNotice notice)? accept;
  final Future<void> Function() _chime;
  final Duration cooldown;
  final int maxShown;
  final DateTime Function() _now;

  static const infoFor = Duration(seconds: 8);
  static const reviewFor = Duration(seconds: 20);

  final _shown = <AlertNotice>[];
  final _timers = <String, Timer>{};
  final _lastRaised = <String, DateTime>{};
  DateTime? _lastChime;
  var _disposed = false;

  List<AlertNotice> get shown => List.unmodifiable(_shown);

  /// Shows [notice] unless the same [key] was raised within [cooldown].
  /// Returns whether it was shown.
  bool raise(AlertNotice notice, {String? key}) {
    if (_disposed || !(accept?.call(notice) ?? true)) return false;
    final now = _now();
    if (key != null) {
      final last = _lastRaised[key];
      if (last != null && now.difference(last) < cooldown) return false;
      _lastRaised[key] = now;
    }
    _shown.removeWhere((n) => n.id == notice.id);
    _shown.insert(0, notice);
    while (_shown.length > maxShown) {
      _timers.remove(_shown.removeLast().id)?.cancel();
    }
    _timers[notice.id]?.cancel();
    _timers[notice.id] = Timer(notice.tone == VisionTone.review ? reviewFor : infoFor, () => dismiss(notice.id));
    if (notice.tone == VisionTone.review && (sound?.call() ?? true)) {
      // Two risks at once are one chime.
      if (_lastChime == null || now.difference(_lastChime!) > const Duration(seconds: 3)) {
        _lastChime = now;
        unawaited(_chime());
      }
    }
    notifyListeners();
    return true;
  }

  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    final before = _shown.length;
    _shown.removeWhere((n) => n.id == id);
    if (_shown.length != before && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}

/// Lets the tabs raise alerts without rebuilding when they come and go.
class AlertScope extends InheritedWidget {
  const AlertScope({super.key, required this.center, required super.child});

  final AlertCenter center;

  static AlertCenter? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<AlertScope>()?.center;

  @override
  bool updateShouldNotify(AlertScope old) => old.center != center;
}

/// Polls the project's feed while the Feed tab may be closed, and raises a
/// toast for each alert that arrives waiting for review: the edge's inference,
/// as its uplink posts it. What's there when it starts is old news: only what
/// appears after counts.
class FeedAlertWatcher {
  /// Every 5 s by default, as often as the edge's uplink posts: an alert
  /// toasts within about 10 s of the device writing it.
  FeedAlertWatcher(this.api, this.center, {this.interval = const Duration(seconds: 5)}) {
    _poll();
    _timer = Timer.periodic(interval, (_) => _poll());
  }

  final FeedApi api;
  final AlertCenter center;
  final Duration interval;
  late final Timer _timer;
  Set<String>? _seen;
  var _busy = false;
  var _closed = false;

  Future<void> _poll() async {
    if (_busy || _closed) return;
    _busy = true;
    try {
      final page = await api.page(limit: 20);
      if (_closed) return;
      final seen = _seen;
      _seen = {...?seen, for (final i in page.items) i.id};
      if (seen == null) return;
      // Oldest first, so the newest ends up on top.
      for (final item in page.items.reversed) {
        if (seen.contains(item.id) || !item.alert || !item.pending) continue;
        center.raise(
          AlertNotice(
            id: 'feed:${item.id}',
            title: item.title,
            tone: item.tone == FeedTone.review ? VisionTone.review : VisionTone.info,
            code: item.badge,
            where: item.subtitle,
            detail: item.detail,
            camera: item.meta['camera_id'],
            fromFeed: true,
          ),
        );
      }
    } catch (_) {
      // The Feed tab says what's wrong; a toast has nothing to add.
    } finally {
      _busy = false;
    }
  }

  void dispose() {
    _closed = true;
    _timer.cancel();
  }
}
