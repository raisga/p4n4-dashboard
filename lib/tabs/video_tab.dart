import 'package:flutter/material.dart';

import '../api/camera.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/mjpeg_view.dart';

/// Live camera feeds from the edge device (MJPEG streams or JPEG snapshots):
/// one camera at a time, or all of them in a grid.
class VideoTab extends StatefulWidget {
  const VideoTab({super.key, required this.active});

  final bool active;

  @override
  State<VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends State<VideoTab> {
  P4Colors get p4 => context.p4;

  /// One key per camera id, so a camera's viewer (and its connection) moves
  /// between the single view and the grid instead of reconnecting.
  final _views = <String, GlobalKey<MjpegViewState>>{};
  String? _selectedId;
  bool _grid = false;
  bool _paused = false;

  GlobalKey<MjpegViewState> _key(Camera c) => _views.putIfAbsent(c.id, GlobalKey.new);

  Future<void> _edit(AppSettings s, [Camera? camera]) async {
    final cameras = s.cameras;
    final result = await showDialog<_CameraEdit>(
      context: context,
      builder: (_) =>
          _CameraDialog(initial: camera, defaultName: 'Camera ${cameras.length + 1}', defaultUrl: 'http://${s.host}:'),
    );
    if (result == null) return;
    if (camera == null) {
      final added = Camera(id: s.newCameraId(), name: result.name, url: result.url);
      s.cameras = [...cameras, added];
      setState(() => _selectedId = added.id);
    } else if (result.delete) {
      s.cameras = [
        for (final c in cameras)
          if (c.id != camera.id) c,
      ];
      _views.remove(camera.id);
    } else {
      s.cameras = [for (final c in cameras) c.id == camera.id ? c.copyWith(name: result.name, url: result.url) : c];
    }
  }

  void _reconnect(Iterable<Camera> cameras) {
    for (final c in cameras) {
      _views[c.id]?.currentState?.reconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final cameras = s.cameras;
    // Only admins and power users see URLs or change cameras.
    final technical = SessionScope.of(context).isTechnical;
    final selected = cameras.where((c) => c.id == _selectedId).firstOrNull ?? cameras.firstOrNull;
    final grid = _grid && cameras.length > 1;
    final shown = grid ? cameras : [?selected];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          color: p4.bg2,
          child: Row(
            children: [
              Icon(Icons.videocam_outlined, color: p4.accent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: _title(cameras, selected, grid, technical)),
              if (shown.isNotEmpty) ...[
                IconButton(
                  tooltip: _paused ? 'Resume' : 'Pause',
                  onPressed: () => setState(() => _paused = !_paused),
                  icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 18),
                ),
                IconButton(
                  tooltip: 'Reconnect',
                  onPressed: () => _reconnect(shown),
                  icon: const Icon(Icons.refresh, size: 18),
                ),
              ],
              if (cameras.length > 1)
                IconButton(
                  tooltip: grid ? 'Single camera' : 'All cameras',
                  onPressed: () => setState(() => _grid = !grid),
                  icon: Icon(grid ? Icons.crop_square : Icons.grid_view, size: 18),
                ),
              if (technical) ...[
                if (!grid && selected != null)
                  IconButton(
                    tooltip: 'Edit camera',
                    onPressed: () => _edit(s, selected),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                IconButton(tooltip: 'Add camera', onPressed: () => _edit(s), icon: const Icon(Icons.add, size: 18)),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (selected) {
            null => EmptyState(
              icon: Icons.videocam_off_outlined,
              title: 'No cameras',
              message: technical
                  ? 'Add the URL of an MJPEG stream or JPEG snapshot from your edge camera.'
                  : 'No camera has been set up yet. Ask your administrator to add one.',
              actions: [if (technical) FilledButton(onPressed: () => _edit(s), child: const Text('ADD CAMERA'))],
            ),
            _ when grid => _gridView(cameras),
            final c => _view(c),
          },
        ),
      ],
    );
  }

  Widget _title(List<Camera> cameras, Camera? selected, bool grid, bool technical) {
    final style = p4.mono();
    if (selected == null) return Text('no cameras configured', style: style);
    if (grid) return Text('${cameras.length} cameras', style: style);
    final url = technical ? Text(selected.url, overflow: TextOverflow.ellipsis, style: style) : null;
    if (cameras.length == 1) {
      return technical ? url! : Text(selected.name, overflow: TextOverflow.ellipsis, style: style);
    }
    return Row(
      children: [
        DropdownButton<String>(
          value: selected.id,
          isDense: true,
          underline: const SizedBox.shrink(),
          dropdownColor: p4.bg2,
          style: p4.mono(size: 12, color: p4.text, spacing: 0),
          onChanged: (id) => setState(() => _selectedId = id),
          items: [for (final c in cameras) DropdownMenuItem(value: c.id, child: Text(c.name))],
        ),
        if (url != null) ...[const SizedBox(width: 12), Expanded(child: url)],
      ],
    );
  }

  Widget _view(Camera c) => switch (c.uri) {
    final uri? => MjpegView(key: _key(c), uri: uri, active: widget.active && !_paused),
    null => Center(
      child: Text('"${c.name}" has an invalid URL', style: p4.mono(color: p4.err)),
    ),
  };

  /// Every camera at 16:9, as many columns as fit at ≥320px each.
  Widget _gridView(List<Camera> cameras) => LayoutBuilder(
    builder: (context, box) {
      final cols = (box.maxWidth / 320).floor().clamp(1, cameras.length);
      return GridView.count(
        crossAxisCount: cols,
        childAspectRatio: 16 / 9,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        children: [
          for (final c in cameras)
            Stack(
              fit: StackFit.expand,
              children: [
                _view(c),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: Colors.black54,
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedId = c.id;
                        _grid = false;
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                                style: p4.mono(size: 11, color: P4Colors.dark.text),
                              ),
                            ),
                            Icon(Icons.open_in_full, size: 14, color: P4Colors.dark.text),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    },
  );
}

typedef _CameraEdit = ({String name, String url, bool delete});

/// Add or edit one camera. Owns its controllers so they outlive the dialog's
/// exit animation.
class _CameraDialog extends StatefulWidget {
  const _CameraDialog({this.initial, required this.defaultName, required this.defaultUrl});

  final Camera? initial;
  final String defaultName;
  final String defaultUrl;

  @override
  State<_CameraDialog> createState() => _CameraDialogState();
}

class _CameraDialogState extends State<_CameraDialog> {
  P4Colors get p4 => context.p4;

  late final _name = TextEditingController(text: widget.initial?.name ?? widget.defaultName);
  late final _url = TextEditingController(text: widget.initial?.url ?? widget.defaultUrl);

  bool get _valid => Camera.parseUrl(_url.text) != null;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  void _save() {
    if (!_valid) return;
    final name = _name.text.trim();
    Navigator.pop<_CameraEdit>(context, (
      name: name.isEmpty ? widget.defaultName : name,
      url: _url.text.trim(),
      delete: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return AlertDialog(
      backgroundColor: p4.bg2,
      shape: RoundedRectangleBorder(side: BorderSide(color: p4.border2)),
      title: Text(editing ? 'Edit camera' : 'Add camera', style: p4.display()),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _url,
              autofocus: true,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: InputDecoration(
                labelText: 'MJPEG or snapshot URL',
                errorText: _url.text.isEmpty || _valid ? null : 'Enter an http:// or https:// URL',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
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
        if (editing)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p4.err),
            onPressed: () => Navigator.pop<_CameraEdit>(context, (name: '', url: '', delete: true)),
            child: const Text('DELETE'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(onPressed: _valid ? _save : null, child: const Text('SAVE')),
      ],
    );
  }
}
