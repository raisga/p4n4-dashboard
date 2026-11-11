import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/settings.dart';
import '../core/theme.dart';
import '../drive/dashcam.dart';
import '../l10n/l10n.dart';
import '../platform/local_files.dart';
import '../widgets/common.dart';

/// Opens the [dashcam]'s clips.
Future<void> openDashcamClips(BuildContext context, Dashcam dashcam) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DashcamClipsPage(dashcam: dashcam)));

/// [bytes] for people: `340 MB`, `1.2 GB`.
String clipSize(int bytes) {
  const mb = 1 << 20, gb = 1 << 30;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  return '${(bytes / mb).ceil()} MB';
}

/// The dashcam's clips on this phone, newest first: the saved ones, kept
/// until deleted here, then the rest, which go to make room for new ones.
/// A computer can copy them over USB, from `Android/data/<app>/files/dashcam`.
class DashcamClipsPage extends StatefulWidget {
  const DashcamClipsPage({super.key, required this.dashcam});

  final Dashcam dashcam;

  @override
  State<DashcamClipsPage> createState() => _DashcamClipsPageState();
}

class _DashcamClipsPageState extends State<DashcamClipsPage> {
  List<DashClip>? _clips;
  int? _free;
  bool _loading = false, _again = false;

  @override
  void initState() {
    super.initState();
    // A clip begins, ends, is saved or deleted.
    widget.dashcam.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.dashcam.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) {
      _again = true;
      return;
    }
    _loading = true;
    try {
      do {
        _again = false;
        final clips = await widget.dashcam.clips();
        final free = await widget.dashcam.freeBytes();
        if (!mounted) return;
        setState(() {
          _clips = clips;
          _free = free;
        });
      } while (_again);
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final clips = _clips;
    final saved = [...?clips?.where((c) => c.locked)];
    final recent = [...?clips?.where((c) => !c.locked)];
    return Scaffold(
      appBar: AppBar(title: Text(l.dashcamClips)),
      body: switch (clips) {
        null => Center(child: CircularProgressIndicator(color: context.p4.accent)),
        [] => EmptyState(icon: Icons.video_library_outlined, title: l.dashcamClipsEmpty, message: l.dashcamClipsWhere),
        _ => ListView(
          children: [
            _summary(saved, recent),
            if (saved.isNotEmpty) ...[_header(l.dashcamClipsSaved), for (final c in saved) _tile(c)],
            if (recent.isNotEmpty) ...[_header(l.dashcamClipsRecent), for (final c in recent) _tile(c)],
          ],
        ),
      },
    );
  }

  Widget _summary(List<DashClip> saved, List<DashClip> recent) {
    final l = context.l10n;
    final p4 = context.p4;
    int total(List<DashClip> clips) => clips.fold(0, (sum, c) => sum + c.bytes);
    final cap = SettingsScope.of(context).dashcamStorageGb;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        [
          l.dashcamClipsStorage(clipSize(total(recent)), '$cap GB', clipSize(total(saved))),
          if (_free case final free?) l.dashcamClipsFree(clipSize(free)),
          l.dashcamClipsWhere,
        ].join('\n'),
        style: p4.body(size: 13, color: p4.muted),
      ),
    );
  }

  Widget _header(String text) {
    final p4 = context.p4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: p4.mono(size: 11, color: p4.accent, weight: FontWeight.w600),
      ),
    );
  }

  Widget _tile(DashClip c) {
    final l = context.l10n;
    final p4 = context.p4;
    final local = MaterialLocalizations.of(context);
    final began = c.began ?? c.modified;
    return ListTile(
      leading: Icon(
        c.recording ? Icons.fiber_manual_record : (c.locked ? Icons.lock : Icons.movie_outlined),
        color: c.recording ? Colors.red : (c.locked ? p4.accent : p4.muted),
      ),
      title: Text('${local.formatMediumDate(began)} · ${local.formatTimeOfDay(TimeOfDay.fromDateTime(began))}'),
      subtitle: Text(
        [clipSize(c.bytes), if (c.gpx != null) l.dashcamClipTrack, if (c.recording) l.dashcamClipRecording].join(' · '),
      ),
      onTap: c.recording ? null : () => _play(c),
      trailing: c.recording
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: c.locked ? l.dashcamClipUnkeep : l.dashcamClipKeep,
                  onPressed: () => widget.dashcam.keep(c, locked: !c.locked),
                  icon: Icon(c.locked ? Icons.lock_open : Icons.lock_outline),
                ),
                IconButton(tooltip: l.delete, onPressed: () => _delete(c), icon: const Icon(Icons.delete_outline)),
              ],
            ),
    );
  }

  Future<void> _delete(DashClip c) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.dashcamClipDeleteTitle),
        content: Text(l.dashcamClipDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok == true) await widget.dashcam.delete(c);
  }

  Future<void> _play(DashClip c) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _ClipPlayer(clip: c)));
}

class _ClipPlayer extends StatefulWidget {
  const _ClipPlayer({required this.clip});

  final DashClip clip;

  @override
  State<_ClipPlayer> createState() => _ClipPlayerState();
}

class _ClipPlayerState extends State<_ClipPlayer> {
  late final VideoPlayerController _video = localVideoPlayer(widget.clip.path);
  Object? _error;

  @override
  void initState() {
    super.initState();
    _video.addListener(_changed);
    _video.initialize().then(
      (_) => unawaited(_video.play()),
      onError: (Object e) {
        if (mounted) setState(() => _error = e);
      },
    );
  }

  @override
  void dispose() {
    _video.removeListener(_changed);
    unawaited(_video.dispose());
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final local = MaterialLocalizations.of(context);
    final began = widget.clip.began ?? widget.clip.modified;
    final v = _video.value;
    String clock(Duration d) => '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${local.formatMediumDate(began)} · ${local.formatTimeOfDay(TimeOfDay.fromDateTime(began))}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: switch ((_error, v.isInitialized)) {
                (final error?, _) => Text(
                  '$error',
                  style: p4.body(color: p4.err),
                  textAlign: TextAlign.center,
                ),
                (_, false) => CircularProgressIndicator(color: p4.accent),
                _ => AspectRatio(aspectRatio: v.aspectRatio, child: VideoPlayer(_video)),
              },
            ),
          ),
          if (v.isInitialized) ...[
            VideoProgressIndicator(_video, allowScrubbing: true, colors: VideoProgressColors(playedColor: p4.accent)),
            Row(
              children: [
                IconButton(
                  color: P4Colors.dark.text,
                  onPressed: () => unawaited(v.isPlaying ? _video.pause() : _video.play()),
                  icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                Text('${clock(v.position)} / ${clock(v.duration)}', style: p4.mono(color: P4Colors.dark.text)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
