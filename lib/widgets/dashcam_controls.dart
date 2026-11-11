import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../drive/dashcam.dart';
import '../l10n/l10n.dart';
import '../pages/dashcam_clips_page.dart';

/// [error], a [Dashcam.error], in words.
String dashcamErrorText(AppLocalizations l, Object error) => switch (error) {
  DashcamException(problem: DashcamProblem.noCamera) => l.dashcamNoCamera,
  DashcamException(problem: DashcamProblem.permission) => l.dashcamPermission,
  DashcamException(problem: DashcamProblem.noStorage) => l.dashcamNoStorage,
  DashcamException(problem: DashcamProblem.storageFull) => l.dashcamStorageFull,
  _ => '$error',
};

/// How long the dashcam has been recording: `12:34`, `1:02:03` past an hour.
String dashcamElapsed(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final clock = '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  return d.inHours > 0 ? '${d.inHours}:$clock' : clock;
}

/// "● REC 12:34" while the [dashcam] records, ticking; for a moment after
/// [Dashcam.saveClip], that the clip was saved.
class DashcamClock extends StatefulWidget {
  const DashcamClock({super.key, required this.dashcam});

  final Dashcam dashcam;

  @override
  State<DashcamClock> createState() => _DashcamClockState();
}

class _DashcamClockState extends State<DashcamClock> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    widget.dashcam.addListener(_changed);
    _ticking();
  }

  @override
  void didUpdateWidget(DashcamClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dashcam == widget.dashcam) return;
    oldWidget.dashcam.removeListener(_changed);
    widget.dashcam.addListener(_changed);
    _ticking();
  }

  @override
  void dispose() {
    widget.dashcam.removeListener(_changed);
    _tick?.cancel();
    super.dispose();
  }

  void _changed() {
    _ticking();
    setState(() {});
  }

  /// Ticks each second while recording.
  void _ticking() {
    if (widget.dashcam.since == null) {
      _tick?.cancel();
      _tick = null;
    } else {
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final dashcam = widget.dashcam;
    final since = dashcam.since;
    final now = DateTime.now();
    final saved = switch (dashcam.lastSave) {
      final s? when now.difference(s.at) < const Duration(seconds: 4) => s,
      _ => null,
    };
    final style = p4.mono(size: 10, color: P4Colors.dark.text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black54,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            since == null ? Icons.pause : Icons.fiber_manual_record,
            size: 12,
            color: since == null ? P4Colors.dark.muted : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(switch (since) {
            final since? => 'REC ${dashcamElapsed(now.difference(since))}',
            _ when dashcam.held => l.dashcamPaused,
            _ => l.dashcamStarting,
          }, style: style),
          if (saved != null) ...[
            const SizedBox(width: 10),
            Icon(Icons.lock, size: 12, color: P4Colors.dark.accent),
            const SizedBox(width: 4),
            Text(saved.impact ? l.dashcamSavedImpact : l.dashcamSaved, style: style),
          ],
        ],
      ),
    );
  }
}

/// On the dashcam's preview: save the clip, the clips, stop.
class DashcamButtons extends StatelessWidget {
  const DashcamButtons({super.key, required this.dashcam});

  final Dashcam dashcam;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: dashcam,
      builder: (context, _) => Wrap(
        spacing: 8,
        children: [
          FilledButton.icon(
            onPressed: dashcam.recording ? dashcam.saveClip : null,
            icon: const Icon(Icons.lock_outline, size: 18),
            label: Text(l.dashcamSave),
          ),
          IconButton.filledTonal(
            tooltip: l.dashcamClips,
            onPressed: () => openDashcamClips(context, dashcam),
            icon: const Icon(Icons.video_library_outlined),
          ),
          IconButton.filledTonal(tooltip: l.dashcamStop, onPressed: dashcam.stop, icon: const Icon(Icons.stop)),
        ],
      ),
    );
  }
}

/// Starts the dashcam.
class DashcamRecordButton extends StatelessWidget {
  const DashcamRecordButton({super.key, required this.dashcam});

  final Dashcam dashcam;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: dashcam.start,
    icon: const Icon(Icons.fiber_manual_record, size: 18),
    label: Text(context.l10n.dashcamRecord),
  );
}

/// "Dashcam paused", over the front camera that paused it.
class DashcamPausedBanner extends StatelessWidget {
  const DashcamPausedBanner({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_outline, size: 16, color: P4Colors.dark.text),
            const SizedBox(width: 8),
            Flexible(
              child: Text(l.dashcamPaused, style: context.p4.body(size: 13, color: P4Colors.dark.text)),
            ),
            TextButton(onPressed: onResume, child: Text(l.dashcamResume)),
          ],
        ),
      ),
    );
  }
}

/// The dashcam on the Map tab: its clock and Save while on, Record while off.
class DashcamChip extends StatelessWidget {
  const DashcamChip({super.key, required this.dashcam});

  final Dashcam dashcam;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListenableBuilder(
      listenable: dashcam,
      builder: (context, _) {
        if (!dashcam.on) return DashcamRecordButton(dashcam: dashcam);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dashcam.error case final error?)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: ActionChip(
                  avatar: Icon(Icons.error_outline, size: 16, color: context.p4.err),
                  label: Text(dashcamErrorText(l, error), maxLines: 2, overflow: TextOverflow.ellipsis),
                  tooltip: l.retry,
                  onPressed: dashcam.retry,
                ),
              )
            else
              DashcamClock(dashcam: dashcam),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: l.dashcamSave,
              onPressed: dashcam.recording ? dashcam.saveClip : null,
              icon: const Icon(Icons.lock_outline),
            ),
          ],
        );
      },
    );
  }
}
