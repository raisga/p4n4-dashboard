import 'package:flutter/material.dart';

import '../api/camera.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';
import '../widgets/mjpeg_view.dart';
import '../widgets/video_view.dart';

/// Live camera feeds from the edge device (MJPEG streams, JPEG snapshots or
/// video files): one camera at a time, or all of them in a grid. Admins can
/// swap in [demoCameras] to show it off without cameras.
class VideoTab extends StatefulWidget {
  const VideoTab({super.key, required this.active});

  final bool active;

  @override
  State<VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends State<VideoTab> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  /// One key per camera id, so a camera's viewer (and its connection) moves
  /// between the single view and the grid instead of reconnecting.
  final _views = <String, GlobalKey>{};
  String? _selectedId;
  bool _grid = false;
  bool _paused = false;

  GlobalKey _key(Camera c) => _views.putIfAbsent(c.id, GlobalKey.new);

  Future<void> _edit(AppSettings s, [Camera? camera]) async {
    final cameras = s.cameras;
    final result = await showDialog<_CameraEdit>(
      context: context,
      builder: (_) => _CameraDialog(
        initial: camera,
        defaultName: l.cameraDefaultName(cameras.length + 1),
        defaultUrl: 'http://${s.host}:',
      ),
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
      switch (_views[c.id]?.currentState) {
        case final MjpegViewState v:
          v.reconnect();
        case final VideoViewState v:
          v.reconnect();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final session = SessionScope.of(context);
    final demo = s.videoDemo;
    final cameras = demo ? demoCameras : s.cameras;
    // Only admins and power users see URLs or change cameras; demo cameras
    // aren't the deployment's to change.
    final technical = session.isTechnical;
    final editable = technical && !demo;
    final selected = cameras.where((c) => c.id == _selectedId).firstOrNull ?? cameras.firstOrNull;
    final grid = _grid && cameras.length > 1;
    final shown = grid ? cameras : [?selected];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          color: p4.bg2,
          child: Row(
            children: [
              Icon(Icons.videocam_outlined, color: p4.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(child: _title(cameras, selected, grid, technical)),
              if (shown.isNotEmpty) ...[
                IconButton(
                  tooltip: _paused ? l.resumeTooltip : l.pauseTooltip,
                  onPressed: () => setState(() => _paused = !_paused),
                  icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 20),
                ),
                IconButton(
                  tooltip: l.reconnectTooltip,
                  onPressed: () => _reconnect(shown),
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
              if (cameras.length > 1)
                IconButton(
                  tooltip: grid ? l.singleCamera : l.allCameras,
                  onPressed: () => setState(() => _grid = !grid),
                  icon: Icon(grid ? Icons.crop_square : Icons.grid_view, size: 20),
                ),
              // Demo cameras are a setting: admins only.
              if (session.isAdmin)
                IconButton(
                  tooltip: l.videoDemoSwitch,
                  isSelected: demo,
                  onPressed: () => s.videoDemo = !demo,
                  icon: const Icon(Icons.movie_outlined, size: 20),
                  selectedIcon: Icon(Icons.movie, size: 20, color: p4.accent),
                ),
              if (editable) ...[
                if (!grid && selected != null)
                  IconButton(
                    tooltip: l.editCamera,
                    onPressed: () => _edit(s, selected),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                IconButton(tooltip: l.addCamera, onPressed: () => _edit(s), icon: const Icon(Icons.add, size: 20)),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (selected) {
            null => EmptyState(
              icon: Icons.videocam_off_outlined,
              title: l.noCameras,
              message: technical ? l.noCamerasTechnical : l.noCamerasNormie,
              actions: [
                if (technical) FilledButton(onPressed: () => _edit(s), child: Text(l.addCameraButton)),
                if (session.isAdmin) OutlinedButton(onPressed: () => s.videoDemo = true, child: Text(l.useDemoCameras)),
              ],
            ),
            _ when grid => _gridView(cameras),
            final c => _view(c),
          },
        ),
        if (demo)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: p4.bg2,
            child: Text(l.videoDemoCredits, style: p4.body(size: 11, color: p4.muted)),
          ),
      ],
    );
  }

  Widget _title(List<Camera> cameras, Camera? selected, bool grid, bool technical) {
    final style = p4.display(size: 15, weight: FontWeight.w600, spacing: 0);
    if (selected == null) return Text(l.noCamerasConfigured, style: p4.body(color: p4.muted));
    if (grid) return Text(l.cameraCount(cameras.length), style: style);
    final url = technical
        ? Text(selected.url, overflow: TextOverflow.ellipsis, style: p4.mono(size: 12, spacing: 0))
        : null;
    if (cameras.length == 1) {
      return Row(
        children: [
          Flexible(
            child: Text(selected.name, overflow: TextOverflow.ellipsis, style: style),
          ),
          if (url != null) ...[const SizedBox(width: 12), Expanded(child: url)],
        ],
      );
    }
    return Row(
      children: [
        DropdownButton<String>(
          value: selected.id,
          isDense: true,
          underline: const SizedBox.shrink(),
          dropdownColor: p4.bg2,
          style: style.copyWith(color: p4.text),
          onChanged: (id) => setState(() => _selectedId = id),
          items: [for (final c in cameras) DropdownMenuItem(value: c.id, child: Text(c.name))],
        ),
        if (url != null) ...[const SizedBox(width: 12), Expanded(child: url)],
      ],
    );
  }

  Widget _view(Camera c) => switch (c.uri) {
    final uri? when c.isVideo => VideoView(key: _key(c), uri: uri, active: widget.active && !_paused),
    final uri? => MjpegView(key: _key(c), uri: uri, active: widget.active && !_paused),
    null => Center(
      child: Text(l.cameraInvalidUrl(c.name), style: p4.body(color: p4.err)),
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
                                style: p4.body(size: 13, color: P4Colors.dark.text, weight: FontWeight.w600),
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
    final l = context.l10n;
    // The examples line up under the localized "e.g.".
    final pad = ' ' * (l.cameraExamples.length + 1);
    return AlertDialog(
      title: Text(editing ? l.editCamera : l.addCamera),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: InputDecoration(labelText: l.fieldName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _url,
              autofocus: true,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: InputDecoration(
                labelText: l.cameraUrl,
                errorText: _url.text.isEmpty || _valid ? null : l.cameraUrlError,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Text(
              '${l.cameraExamples} mjpg-streamer  http://host:8080/?action=stream\n'
              '${pad}motion         http://host:8081/\n'
              '${pad}go2rtc         http://host:1984/api/stream.mjpeg?src=cam\n'
              '${pad}snapshot       http://host/snapshot.jpg\n'
              '${pad}video file     http://host/clip.mp4',
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
            child: Text(l.delete),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _valid ? _save : null, child: Text(l.save)),
      ],
    );
  }
}
