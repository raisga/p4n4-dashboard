import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/mjpeg_view.dart';

/// Live camera feed from the edge device (MJPEG stream or JPEG snapshots).
class VideoTab extends StatefulWidget {
  const VideoTab({super.key, required this.active});

  final bool active;

  @override
  State<VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends State<VideoTab> {
  P4Colors get p4 => context.p4;

  final _view = GlobalKey<MjpegViewState>();
  bool _paused = false;

  Future<void> _editUrl(AppSettings s) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _SourceDialog(initial: s.videoUrl.isEmpty ? 'http://${s.host}:' : s.videoUrl),
    );
    if (result != null) s.videoUrl = result;
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final uri = Uri.tryParse(s.videoUrl);
    final valid = s.videoUrl.isNotEmpty && uri != null && uri.hasScheme && uri.host.isNotEmpty;
    // Only admins see or change the source URL.
    final admin = SessionScope.of(context).isAdmin;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          color: p4.bg2,
          child: Row(
            children: [
              Icon(Icons.videocam_outlined, color: p4.accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  switch ((valid, admin)) {
                    (true, true) => s.videoUrl,
                    (true, false) => 'live camera',
                    _ => 'no source configured',
                  },
                  overflow: TextOverflow.ellipsis,
                  style: p4.mono(),
                ),
              ),
              if (valid) ...[
                IconButton(
                  tooltip: _paused ? 'Resume' : 'Pause',
                  onPressed: () => setState(() => _paused = !_paused),
                  icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 18),
                ),
                IconButton(
                  tooltip: 'Reconnect',
                  onPressed: () => _view.currentState?.reconnect(),
                  icon: const Icon(Icons.refresh, size: 18),
                ),
              ],
              if (admin)
                IconButton(
                  tooltip: 'Change source',
                  onPressed: () => _editUrl(s),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: valid
              ? MjpegView(key: _view, uri: uri, active: widget.active && !_paused)
              : EmptyState(
                  icon: Icons.videocam_off_outlined,
                  title: 'No video source',
                  message: admin
                      ? 'Add the URL of an MJPEG stream or JPEG snapshot from your edge camera.'
                      : 'No camera has been set up yet. Ask your administrator to add one.',
                  actions: [if (admin) FilledButton(onPressed: () => _editUrl(s), child: const Text('SET SOURCE'))],
                ),
        ),
      ],
    );
  }
}

/// Owns its controller so it outlives the dialog's exit animation.
class _SourceDialog extends StatefulWidget {
  const _SourceDialog({required this.initial});

  final String initial;

  @override
  State<_SourceDialog> createState() => _SourceDialogState();
}

class _SourceDialogState extends State<_SourceDialog> {
  P4Colors get p4 => context.p4;

  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: p4.bg2,
      shape: RoundedRectangleBorder(side: BorderSide(color: p4.border2)),
      title: Text('Video source', style: p4.display()),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: const InputDecoration(labelText: 'MJPEG or snapshot URL'),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 12),
            Text(
              'e.g. mjpg-streamer  http://host:8080/?action=stream\n'
              '     motion         http://host:8081/\n'
              '     go2rtc         http://host:1984/api/stream.mjpeg?src=cam\n'
              '     snapshot       http://host/snapshot.jpg',
              style: p4.mono(size: 10, spacing: 0),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('SAVE')),
      ],
    );
  }
}
