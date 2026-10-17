import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_error.dart';
import '../api/devices.dart';
import '../core/brand.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Settings → Devices: the devices that send readings to the connected
/// deployment's p4n4-api. Power users see the list; admins also register,
/// disable, rotate keys and remove (the API checks that too).
class DevicesSection extends StatefulWidget {
  const DevicesSection({super.key});

  @override
  State<DevicesSection> createState() => _DevicesSectionState();
}

class _DevicesSectionState extends State<DevicesSection> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  static const _page = 50;

  List<ApiDevice>? _devices;
  int _total = 0;
  Object? _loadError;
  String? _actionError;
  bool _busy = false;
  Uri? _api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = SettingsScope.of(context).apiUri;
    if (api != _api) {
      _api = api;
      _devices = null;
      _load();
    }
  }

  /// The first page again, or with [more], the next one after those shown.
  Future<void> _load({bool more = false}) async {
    final api = _api!;
    final offset = more ? _devices?.length ?? 0 : 0;
    setState(() => _loadError = null);
    try {
      final page = await listDevices(
        api,
        limit: more ? _page : (_devices?.length ?? 0).clamp(_page, 200),
        offset: offset,
      );
      if (!mounted || api != _api) return;
      setState(() {
        _devices = [if (more) ...?_devices, ...page.items];
        _total = page.total;
      });
    } catch (e) {
      if (mounted && api == _api) setState(() => _loadError = e);
    }
  }

  /// Runs a change, then reloads the list (or shows why it failed).
  Future<T?> _run<T>(Future<T> Function(Uri api) change) async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    T? result;
    try {
      result = await change(_api!);
    } catch (e) {
      if (mounted) setState(() => _actionError = _describe(e));
    }
    await _load();
    if (mounted) setState(() => _busy = false);
    return result;
  }

  String _describe(Object e) => switch (e) {
    ApiException(statusCode: 401) => l.sessionExpired,
    ApiException(statusCode: 403) => l.devicesOnlyAdmins,
    _ => '$e',
  };

  Future<void> _add() async {
    final form = await showDialog<_DeviceForm>(context: context, builder: (_) => const _DeviceDialog());
    if (form == null) return;
    final created = await _run((api) => createDevice(api, id: form.id, name: form.name, description: form.description));
    if (created != null && mounted) await _showKey(created.$1.id, created.$2);
  }

  Future<void> _edit(ApiDevice d) async {
    final form = await showDialog<_DeviceForm>(
      context: context,
      builder: (_) => _DeviceDialog(initial: d),
    );
    if (form == null) return;
    await _run((api) => updateDevice(api, d.id, name: form.name, description: form.description));
  }

  Future<void> _rotate(ApiDevice d) async {
    final ok = await _confirm(l.rotateKeyTitle(_label(d)), l.rotateKeyBody, l.rotateKey);
    if (!ok) return;
    final key = await _run((api) => rotateDeviceKey(api, d.id));
    if (key != null && mounted) await _showKey(d.id, key);
  }

  Future<void> _delete(ApiDevice d) async {
    if (await _confirm(l.removeDeviceTitle(_label(d)), l.removeDeviceBody, l.remove)) {
      await _run((api) => deleteDevice(api, d.id));
    }
  }

  Future<bool> _confirm(String title, String body, String verb) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(verb)),
          ],
        ),
      ) ==
      true;

  Future<void> _showKey(String id, String key) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _KeyDialog(id: id, apiKey: key),
  );

  static String _label(ApiDevice d) => d.name.isEmpty ? d.id : d.name;

  @override
  Widget build(BuildContext context) {
    final admin = SessionScope.of(context).isAdmin;
    final devices = _devices;
    final muted = p4.body(size: 13, color: p4.muted);
    final f = context.formats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.devicesNote(BrandScope.of(context).platform), style: muted),
        if (_actionError case final error?) ...[
          const SizedBox(height: 10),
          Text(error, style: p4.mono(color: p4.err, spacing: 0)),
        ],
        const SizedBox(height: 10),
        if (_loadError != null && devices == null)
          Row(
            children: [
              Expanded(
                child: Text(l.devicesLoadFailed(_describe(_loadError!)), style: p4.mono(color: p4.err, spacing: 0)),
              ),
              TextButton(onPressed: _load, child: Text(l.retry)),
            ],
          )
        else if (devices == null)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent)),
          )
        else if (devices.isEmpty)
          Text(l.devicesNone, style: muted)
        else
          for (final d in devices)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: _label(d)),
                              if (d.name.isNotEmpty)
                                TextSpan(
                                  text: '  ${d.id}',
                                  style: p4.mono(size: 12, color: p4.muted, spacing: 0),
                                ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: p4.display(
                            size: 14,
                            weight: FontWeight.w500,
                            spacing: 0,
                            color: d.enabled ? p4.text : p4.muted,
                          ),
                        ),
                        if (d.description.isNotEmpty)
                          Text(
                            d.description,
                            overflow: TextOverflow.ellipsis,
                            style: p4.body(size: 12, color: p4.muted),
                          ),
                        Text(
                          [
                            if (!d.enabled) l.deviceDisabled,
                            switch (d.lastSeenAt) {
                              final at? => l.deviceLastSeen(f.dateTime(at)),
                              null => l.deviceNeverSeen,
                            },
                            if (d.keyPrefix.isNotEmpty) l.deviceKey(d.keyPrefix),
                          ].join(' · '),
                          overflow: TextOverflow.ellipsis,
                          style: p4.body(size: 12, color: d.enabled ? p4.muted : p4.warn),
                        ),
                      ],
                    ),
                  ),
                  if (admin) ...[
                    Tooltip(
                      message: d.enabled ? l.deviceDisable : l.deviceEnable,
                      child: Switch(
                        value: d.enabled,
                        onChanged: _busy ? null : (v) => _run((api) => updateDevice(api, d.id, enabled: v)),
                      ),
                    ),
                    IconButton(
                      tooltip: l.editTooltip,
                      onPressed: _busy ? null : () => _edit(d),
                      icon: Icon(Icons.edit_outlined, size: 18, color: p4.muted),
                    ),
                    IconButton(
                      tooltip: l.rotateKey,
                      onPressed: _busy ? null : () => _rotate(d),
                      icon: Icon(Icons.key_outlined, size: 18, color: p4.muted),
                    ),
                    IconButton(
                      tooltip: l.removeDeviceTooltip,
                      onPressed: _busy ? null : () => _delete(d),
                      icon: Icon(Icons.delete_outline, size: 18, color: p4.muted),
                    ),
                  ],
                ],
              ),
            ),
        if (devices != null && devices.length < _total)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: _busy ? null : () => _load(more: true), child: Text(l.showMore)),
          ),
        if (admin)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _busy || devices == null ? null : _add,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.addDevice),
            ),
          ),
      ],
    );
  }
}

typedef _DeviceForm = ({String id, String name, String description});

/// A new device's ID, name and description; or an existing one's name and
/// description (its ID can't change).
class _DeviceDialog extends StatefulWidget {
  const _DeviceDialog({this.initial});

  final ApiDevice? initial;

  @override
  State<_DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<_DeviceDialog> {
  late final _id = TextEditingController(text: widget.initial?.id);
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _description = TextEditingController(text: widget.initial?.description);

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (_id.text.trim().isEmpty) return;
    Navigator.pop<_DeviceForm>(context, (
      id: _id.text.trim(),
      name: _name.text.trim(),
      description: _description.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p4 = context.p4;
    final editing = widget.initial != null;
    return AlertDialog(
      title: Text(editing ? l.editDevice : l.addDevice),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _id,
              enabled: !editing,
              autofocus: !editing,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: InputDecoration(
                labelText: l.deviceId,
                hintText: 'shelf-sensor-01',
                helperText: l.deviceIdHelp,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: editing,
              decoration: InputDecoration(labelText: l.deviceName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: InputDecoration(labelText: l.deviceDescription),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _id.text.trim().isEmpty ? null : _save, child: Text(editing ? l.save : l.add)),
      ],
    );
  }
}

/// A device's new key, shown this once: only a hash of it is kept.
class _KeyDialog extends StatelessWidget {
  const _KeyDialog({required this.id, required this.apiKey});

  final String id;
  final String apiKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p4 = context.p4;
    return AlertDialog(
      title: Text(l.deviceKeyTitle(id)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.deviceKeyBody, style: p4.body(size: 14, color: p4.muted)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: p4.bg3, borderRadius: BorderRadius.circular(Radii.control)),
              child: SelectableText(apiKey, style: p4.mono(size: 13, color: p4.text, spacing: 0)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: apiKey));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
          },
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: Text(l.copyTooltip),
        ),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.done)),
      ],
    );
  }
}
