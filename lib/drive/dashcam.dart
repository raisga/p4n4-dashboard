import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart' show CameraPlatform, VideoCaptureOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/settings.dart';
import '../platform/local_files.dart';
import '../widgets/device_camera_view.dart';
import 'drive_channel.dart';
import 'geo.dart';
import 'location.dart';

/// A recording on this phone, made by the [Dashcam].
@immutable
class DashClip {
  const DashClip({
    required this.path,
    required this.bytes,
    required this.modified,
    required this.locked,
    this.gpx,
    this.recording = false,
  });

  final String path;
  final int bytes;
  final DateTime modified;

  /// Saved: kept until deleted here, never to make room.
  final bool locked;

  /// Its GPS track, a GPX file, if it has one.
  final String? gpx;

  /// Being recorded now: growing, and not to be played or deleted yet.
  final bool recording;

  /// `yyyyMMdd-HHmmss`, when it began.
  String get name => path.split('/').last.replaceAll(RegExp(r'\.mp4$'), '');

  /// When it began, from its [name]; null for a file the dashcam didn't name.
  DateTime? get began {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})$').firstMatch(name);
    if (m == null) return null;
    final n = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
    return DateTime(n[0], n[1], n[2], n[3], n[4], n[5]);
  }
}

/// Why the dashcam stopped, besides what the camera says.
enum DashcamProblem { noCamera, permission, noStorage, storageFull }

class DashcamException implements Exception {
  const DashcamException(this.problem);

  final DashcamProblem problem;

  @override
  String toString() => 'DashcamException(${problem.name})';
}

/// Which of the unsaved [clips] to delete, oldest first, so that they take no
/// more than [capBytes] and, with [freeBytes] free now, [reserveBytes] stay
/// free. Never [keep] (the clip being recorded).
List<String> clipsToDelete(
  List<({String path, int bytes, DateTime modified})> clips, {
  required int capBytes,
  int? freeBytes,
  int reserveBytes = 500 << 20,
  String? keep,
}) {
  final oldestFirst = [...clips]
    ..sort(
      (a, b) => switch (a.modified.compareTo(b.modified)) {
        0 => a.path.compareTo(b.path),
        final c => c,
      },
    );
  var total = clips.fold(0, (sum, c) => sum + c.bytes);
  var free = freeBytes;
  final doomed = <String>[];
  for (final clip in oldestFirst) {
    if (total <= capBytes && (free == null || free >= reserveBytes)) break;
    if (clip.path == keep) continue;
    doomed.add(clip.path);
    total -= clip.bytes;
    if (free != null) free += clip.bytes;
  }
  return doomed;
}

/// Tells a crash or hard braking from the bumps of the road: the phone's
/// acceleration (gravity aside) averaged over [window], at least [thresholdG].
/// Then quiet for [cooldown], so one jolt saves one clip.
class ImpactDetector {
  ImpactDetector({
    required this.thresholdG,
    this.window = const Duration(milliseconds: 250),
    this.cooldown = const Duration(seconds: 30),
  });

  /// 0: never.
  double thresholdG;
  final Duration window;
  final Duration cooldown;

  final _samples = <(DateTime, double)>[];
  DateTime? _last;

  static const _g = 9.80665;

  /// One reading, in m/s² without gravity (sensors_plus' user accelerometer),
  /// taken at [time]; true when it makes an impact.
  bool add(double x, double y, double z, DateTime time) {
    if (thresholdG <= 0) return false;
    _samples
      ..add((time, math.sqrt(x * x + y * y + z * z)))
      ..removeWhere((s) => time.difference(s.$1) > window);
    // Too few readings to tell a jolt from a spike.
    if (time.difference(_samples.first.$1) < window * 0.8) return false;
    final mean = _samples.fold(0.0, (sum, s) => sum + s.$2) / _samples.length;
    if (mean / _g < thresholdG) return false;
    if (_last case final last? when time.difference(last) < cooldown) return false;
    _last = time;
    _samples.clear();
    return true;
  }
}

class _Segment {
  _Segment(this.path, this.name, this.start);

  final String path;
  final String name;
  final DateTime start;
  final fixes = <Fix>[];
  bool lock = false;
}

/// The phone as a dashcam: records the back camera in clips of
/// [AppSettings.dashcamSegmentMinutes], each with a GPX file of the way
/// driven, deleting the oldest unsaved ones beyond
/// [AppSettings.dashcamStorageGb]. [saveClip] (or a jolt, see
/// [AppSettings.dashcamLockG]) keeps the clip being recorded, and the one
/// before when it's only just begun.
///
/// Clips go to the app's folder on the phone's storage
/// (`Android/data/<app>/files/dashcam`, saved ones in `locked/`), which a
/// computer can copy from over USB. No sound.
///
/// Records while [on], the app is in front (Android takes the camera from
/// apps that aren't) and nothing [hold]s it: the phone opens one camera at a
/// time, so showing the front camera pauses it. Android only.
class Dashcam extends ChangeNotifier with WidgetsBindingObserver {
  Dashcam(this._settings, this._location, this._awake) {
    WidgetsBinding.instance.addObserver(this);
    _foreground = switch (WidgetsBinding.instance.lifecycleState) {
      AppLifecycleState.paused || AppLifecycleState.hidden || AppLifecycleState.detached => false,
      _ => true,
    };
    _settings.addListener(_onSettings);
  }

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final AppSettings _settings;
  final LocationService _location;
  final KeepAwake _awake;

  bool _wanted = false;
  int _holds = 0;
  bool _foreground = true;

  /// Asked to record ([start]), whether or not it is right now.
  bool get on => _wanted;

  /// Paused for another camera ([hold]).
  bool get held => _holds > 0;

  /// Recording now.
  bool get recording => _segment != null;

  /// Recording without a break since.
  DateTime? get since => _since;
  DateTime? _since;

  /// The camera, while open: for a preview.
  CameraController? get controller => _controller;
  CameraController? _controller;

  /// Why it isn't recording while [on]: a [DashcamException], or the
  /// camera's error. It tries again by itself, unless the camera permission
  /// was denied: then on [retry].
  Object? get error => _error;
  Object? _error;

  /// The last clip saved, and whether a jolt saved it.
  ({DateTime at, bool impact})? get lastSave => _lastSave;
  ({DateTime at, bool impact})? _lastSave;

  _Segment? _segment;

  /// Where the clip recorded before [_segment] went.
  String? _previous;

  String? _folder;
  Timer? _rotation;
  bool _rotateDue = false;
  Timer? _retry;
  var _backoff = _firstBackoff;
  static const _firstBackoff = Duration(seconds: 5);

  /// The camera permission was denied: asking again by itself would only
  /// nag, so it waits for [retry].
  bool _denied = false;
  bool _busy = false, _dirty = false;
  Completer<void>? _releasedWaiter;
  StreamSubscription<Fix>? _fixes;
  StreamSubscription<UserAccelerometerEvent>? _jolts;
  ImpactDetector? _detector;
  bool _disposed = false;

  /// Starts recording.
  void start() {
    if (!supported) return;
    if (_wanted) return retry();
    _wanted = true;
    _error = null;
    _backoff = _firstBackoff;
    notifyListeners();
    _kick();
  }

  /// Stops recording; the clip being recorded is kept as it is.
  void stop() {
    if (!_wanted) return;
    _wanted = false;
    _retry?.cancel();
    _retry = null;
    _denied = false;
    _error = null;
    notifyListeners();
    _kick();
  }

  /// Tries again now, after an [error].
  void retry() {
    _retry?.cancel();
    _retry = null;
    _denied = false;
    _kick();
  }

  /// Pauses recording, to free the camera, until [unhold].
  void hold() {
    if (_holds++ == 0) _kick();
  }

  void unhold() {
    if (_holds == 0) return;
    if (--_holds == 0) _kick();
  }

  /// Done once the dashcam has let go of the camera: now, if it has.
  Future<void> get released {
    if (_controller == null && !_busy) return Future.value();
    return (_releasedWaiter ??= Completer<void>()).future;
  }

  /// Keeps the clip being recorded, and the one before if this one has only
  /// just begun (it may hold what led up to it). The clip ends 30 seconds on,
  /// so that it's ready to watch soon.
  void saveClip({bool impact = false}) {
    final segment = _segment;
    if (segment == null) return;
    final now = DateTime.now();
    segment.lock = true;
    if (_previous case final previous? when now.difference(segment.start) < const Duration(minutes: 1)) {
      unawaited(_moveClip(previous, locked: true));
    }
    final ends = segment.start.add(_segmentLength);
    if (ends.difference(now) > const Duration(seconds: 30)) {
      _rotation?.cancel();
      _rotation = Timer(const Duration(seconds: 30), _rotate);
    }
    _lastSave = (at: now, impact: impact);
    notifyListeners();
  }

  Duration get _segmentLength => Duration(minutes: _settings.dashcamSegmentMinutes.clamp(1, 30));

  bool get _shouldRecord =>
      supported && _wanted && _holds == 0 && _foreground && _retry == null && !_denied && !_disposed;

  void _rotate() {
    _rotateDue = true;
    _kick();
  }

  void _kick() {
    if (_busy) {
      _dirty = true;
      return;
    }
    // Never within the caller (a build, say): the pump notifies listeners.
    _busy = true;
    scheduleMicrotask(() => unawaited(_pump()));
  }

  /// Brings the camera and the recording in line with what's wanted, one
  /// step at a time: whatever changes meanwhile is seen on the next turn.
  Future<void> _pump() async {
    try {
      do {
        _dirty = false;
        try {
          await _step();
        } catch (e) {
          await _fail(e);
        }
      } while (_dirty);
    } finally {
      _busy = false;
      if (_controller == null) {
        _releasedWaiter?.complete();
        _releasedWaiter = null;
      }
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _step() async {
    if (!_shouldRecord) {
      if (_segment != null) await _endSegment();
      _closeCamera();
      _recordingSince(null);
      return;
    }
    if (_segment != null && _rotateDue) await _endSegment();
    if (_segment != null) return;
    // Room for the next clip first: with none, there's no point opening the camera.
    final folder = await _folders();
    await _makeRoom(folder, _segmentBytes);
    final free = await DriveChannel.freeBytes(folder);
    if (free != null && free < _segmentBytes + (100 << 20)) throw const DashcamException(DashcamProblem.storageFull);
    // Held meanwhile: the next turn sees to it.
    if (!_shouldRecord) return;
    if (_controller == null) {
      _controller = await _openCamera();
      if (!_disposed) notifyListeners();
    }
    if (_shouldRecord) await _beginSegment(folder);
  }

  int get _segmentBytes => _segmentLength.inSeconds * _bitrate ~/ 8;

  Future<CameraController> _openCamera() async {
    // Let the cameras' views close theirs first.
    await Future<void>.delayed(Duration.zero);
    await deviceCamerasReleased;
    final back = (await availableCameras()).where((d) => d.lensDirection == CameraLensDirection.back).firstOrNull;
    if (back == null) throw const DashcamException(DashcamProblem.noCamera);
    final c = CameraController(back, ResolutionPreset.veryHigh, enableAudio: false, fps: 30, videoBitrate: _bitrate);
    try {
      await c.initialize();
    } catch (_) {
      releaseDeviceCamera(c);
      rethrow;
    }
    final view = PlatformDispatcher.instance.views.firstOrNull;
    seedDeviceOrientation(c, landscape: view != null && view.physicalSize.width > view.physicalSize.height);
    return c;
  }

  static const _bitrate = 6000000;

  void _closeCamera() {
    final c = _controller;
    if (c == null) return;
    _controller = null;
    // The preview goes first: a closed camera can't build one.
    if (!_disposed) notifyListeners();
    releaseDeviceCamera(c);
  }

  Future<String> _folders() async {
    if (_folder case final folder?) return folder;
    final folder = await externalFolder('dashcam');
    if (folder == null || await externalFolder('dashcam/locked') == null) {
      throw const DashcamException(DashcamProblem.noStorage);
    }
    return _folder = folder;
  }

  Future<void> _beginSegment(String folder) async {
    final c = _controller!;
    final now = DateTime.now();
    final name = clipName(now);
    final path = '$folder/$name.mp4';
    await CameraPlatform.instance.startVideoCapturing(
      VideoCaptureOptions(c.cameraId, videoOutputPath: path, enablePersistentRecording: false),
    );
    _segment = _Segment(path, name, now);
    _rotateDue = false;
    _rotation?.cancel();
    _rotation = Timer(_segmentLength, _rotate);
    _error = null;
    _backoff = _firstBackoff;
    _recordingSince(_since ?? now);
    if (!_disposed) notifyListeners();
  }

  Future<void> _endSegment() async {
    final segment = _segment!;
    _segment = null;
    _rotation?.cancel();
    _rotation = null;
    _rotateDue = false;
    try {
      if (_controller case final c?) await CameraPlatform.instance.stopVideoRecording(c.cameraId);
    } finally {
      await _finish(segment);
    }
  }

  /// Files [segment]: in `locked/` if saved, with its GPS track beside it.
  Future<void> _finish(_Segment segment) async {
    var path = segment.path;
    if (!await fileExists(path)) return;
    if (segment.lock) path = await _moveClip(path, locked: true) ?? path;
    if (segment.fixes.isNotEmpty) {
      try {
        await writeTextFile(_gpxOf(path), gpx(segment.fixes, name: segment.name));
      } catch (_) {
        // The clip matters more than its track.
      }
    }
    _previous = path;
  }

  /// Moves the clip at [path] (and its track) into `locked/`, or out of it;
  /// its new path, or null if it couldn't.
  Future<String?> _moveClip(String path, {required bool locked}) async {
    final folder = await _folders();
    final name = path.split('/').last;
    final to = locked ? '$folder/locked/$name' : '$folder/$name';
    if (to == path) return path;
    if (!await moveFile(path, to)) return null;
    if (await fileExists(_gpxOf(path))) await moveFile(_gpxOf(path), _gpxOf(to));
    if (_previous == path) _previous = to;
    return to;
  }

  /// Deletes the oldest unsaved clips, to keep the dashcam's share of the
  /// storage, and some free, with [incoming] bytes more to come.
  Future<void> _makeRoom(String folder, int incoming) async {
    final cap = (_settings.dashcamStorageGb.clamp(1, 1024) << 30) - incoming;
    final doomed = clipsToDelete(
      await listFiles(folder, '.mp4'),
      capBytes: math.max(0, cap),
      freeBytes: await DriveChannel.freeBytes(folder),
      keep: _segment?.path,
    );
    for (final path in doomed) {
      await deleteFile(path);
      await deleteFile(_gpxOf(path));
    }
  }

  static String _gpxOf(String clip) => clip.replaceAll(RegExp(r'\.mp4$'), '.gpx');

  /// A clip's name: when it began, `yyyyMMdd-HHmmss` in local time.
  static String clipName(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  /// Starts (or with null, ends) what goes with recording: the screen kept
  /// on, the GPS for the tracks, the jolt sensor.
  void _recordingSince(DateTime? since) {
    final was = _since != null;
    _since = since;
    if (was == (since != null)) return;
    if (since != null) {
      _awake.hold();
      _location.acquire();
      _fixes = _location.fixes.listen((fix) => _segment?.fixes.add(fix));
      _watchJolts();
    } else {
      _awake.release();
      _location.release();
      unawaited(_fixes?.cancel());
      _fixes = null;
      unawaited(_jolts?.cancel());
      _jolts = null;
      // A clip from an earlier run isn't what led up to the next one.
      _previous = null;
    }
  }

  void _watchJolts() {
    final threshold = _settings.dashcamLockG;
    if (_since == null || threshold <= 0) {
      unawaited(_jolts?.cancel());
      _jolts = null;
      return;
    }
    (_detector ??= ImpactDetector(thresholdG: threshold)).thresholdG = threshold;
    if (_jolts != null) return;
    try {
      _jolts = userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
        (e) {
          if (_detector!.add(e.x, e.y, e.z, e.timestamp)) saveClip(impact: true);
        },
        // No such sensor: no saving on a jolt.
        onError: (Object _) {
          unawaited(_jolts?.cancel());
          _jolts = null;
        },
        cancelOnError: true,
      );
    } catch (_) {
      _jolts = null;
    }
  }

  void _onSettings() => _watchJolts();

  Future<void> _fail(Object e) async {
    final denied = e is CameraException && e.code == 'CameraAccessDenied';
    _error = switch (e) {
      _ when denied => const DashcamException(DashcamProblem.permission),
      CameraException(:final description, :final code) => description ?? code,
      _ => e,
    };
    if (_segment != null) {
      try {
        await _endSegment();
      } catch (_) {
        // Already broken.
      }
    }
    _closeCamera();
    _recordingSince(null);
    if (!_wanted || _disposed) return;
    if (denied) {
      _denied = true;
      return;
    }
    _retry = Timer(_backoff, () {
      _retry = null;
      _kick();
    });
    _backoff = _backoff * 2 > const Duration(minutes: 1) ? const Duration(minutes: 1) : _backoff * 2;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Inactive (a dialog, the notification shade) keeps recording.
    final foreground = switch (state) {
      AppLifecycleState.paused || AppLifecycleState.hidden || AppLifecycleState.detached => false,
      AppLifecycleState.resumed || AppLifecycleState.inactive => true,
    };
    if (foreground == _foreground) return;
    _foreground = foreground;
    _kick();
  }

  /// The clips on this phone, newest first.
  Future<List<DashClip>> clips() async {
    final String folder;
    try {
      folder = await _folders();
    } on DashcamException {
      return const [];
    }
    final clips = <DashClip>[];
    for (final (dir, locked) in [(folder, false), ('$folder/locked', true)]) {
      final tracks = {for (final f in await listFiles(dir, '.gpx')) f.path};
      for (final f in await listFiles(dir, '.mp4')) {
        final track = _gpxOf(f.path);
        clips.add(
          DashClip(
            path: f.path,
            bytes: f.bytes,
            modified: f.modified,
            locked: locked,
            gpx: tracks.contains(track) ? track : null,
            recording: f.path == _segment?.path,
          ),
        );
      }
    }
    return clips..sort((a, b) => b.name.compareTo(a.name));
  }

  /// The bytes free where the clips go; null if unknown.
  Future<int?> freeBytes() async {
    try {
      return await DriveChannel.freeBytes(await _folders());
    } on DashcamException {
      return null;
    }
  }

  /// Saves [clip] ([locked]), or lets it go with the oldest ones. Not the
  /// one being recorded: [saveClip] saves that.
  Future<void> keep(DashClip clip, {required bool locked}) async {
    if (clip.recording) return;
    await _moveClip(clip.path, locked: locked);
    notifyListeners();
  }

  /// Deletes [clip] and its track; not the one being recorded.
  Future<void> delete(DashClip clip) async {
    if (clip.recording) return;
    await deleteFile(clip.path);
    if (clip.gpx case final track?) await deleteFile(track);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettings);
    _retry?.cancel();
    _rotation?.cancel();
    _wanted = false;
    _kick();
    super.dispose();
  }
}
