import 'package:flutter/material.dart';

import '../api/fleet.dart';
import '../api/status_monitor.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Admin list of client deployments with live status from each host.
class ClientsTab extends StatefulWidget {
  const ClientsTab({super.key, required this.active});

  final bool active;

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  P4Colors get p4 => context.p4;

  late StatusMonitor _monitor;
  late List<StatusTarget> _targets;

  /// Every deployment's status comes from the shared StatusMonitor, keyed by
  /// host and API, so renaming a deployment keeps its status and the
  /// connected one shares checks with Home and Services.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _monitor = StatusScope.of(context);
    final s = SettingsScope.of(context);
    _targets = [for (final d in s.deployments) s.targetOf(d)];
    _watch();
  }

  @override
  void didUpdateWidget(ClientsTab old) {
    super.didUpdateWidget(old);
    _watch();
  }

  void _watch() =>
      widget.active ? _monitor.watch(this, _targets, interval: const Duration(seconds: 30)) : _monitor.unwatch(this);

  @override
  void dispose() {
    _monitor.unwatch(this);
    super.dispose();
  }

  Future<void> _refresh() => Future.wait(_targets.toSet().map(_monitor.refresh));

  Future<void> _edit(AppSettings s, [Deployment? d]) async {
    final result = await showDialog<_DeploymentForm>(
      context: context,
      builder: (_) => _DeploymentDialog(
        initial: d == null ? null : (name: d.name, host: s.hostOf(d), apiBase: d.values['apiBase'] as String? ?? ''),
      ),
    );
    if (result == null) return;
    // An empty API URL means "the default", so drop the key rather than store ''.
    final values = {...?d?.values, 'host': result.host}..remove('apiBase');
    if (result.apiBase.isNotEmpty) values['apiBase'] = result.apiBase;
    // Saving changes the targets, which triggers a check of anything new.
    await s.saveDeployment(
      d == null
          ? Deployment(id: s.newDeploymentId(), name: result.name, values: values)
          : d.copyWith(name: result.name, values: values),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final list = s.deployments;
    return RefreshIndicator(
      color: p4.accent,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    tag: 'admin',
                    title: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Client '),
                          TextSpan(
                            text: 'Deployments',
                            style: TextStyle(color: p4.accent),
                          ),
                        ],
                      ),
                      style: p4.display(size: 32, weight: FontWeight.w800, spacing: -1.5),
                    ),
                    trailing: FilledButton.icon(
                      onPressed: () => _edit(s),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('ADD'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Status comes from each deployment\'s API (port 8000 unless set), or from probing service ports when '
                    'it\'s down. Connect switches this dashboard, and every connection setting, to that deployment.',
                    style: p4.display(size: 14, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                  ),
                  const SizedBox(height: 24),
                  if (list.isEmpty)
                    const EmptyState(
                      icon: Icons.devices_other_outlined,
                      title: 'No deployments',
                      message: 'Add a client deployment by name and host to monitor it here.',
                    )
                  else
                    Container(
                      color: p4.border,
                      padding: const EdgeInsets.all(1),
                      child: Column(
                        children: [
                          for (final (i, d) in list.indexed) ...[if (i > 0) const SizedBox(height: 1), _row(s, d)],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppSettings s, Deployment d) {
    final r = _monitor.statusOf(s.targetOf(d)).report;
    final current = d.id == s.deployment.id;
    final api = s.apiUriOf(d);
    final customApi = api != Uri.parse('http://${s.hostOf(d)}:8000');
    final health = switch (r) {
      null => Health.pending,
      _ when r.known == 0 => Health.unknown,
      _ when r.online == 0 => Health.down,
      _ => Health.up,
    };
    final label = switch (r) {
      null => null,
      _ when r.online == 0 => 'offline',
      _ => '${r.online}/${r.known} up${r.viaApi ? '' : ' (probed)'}',
    };
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(d.name, overflow: TextOverflow.ellipsis, style: p4.display()),
            ),
            if (current) ...[const SizedBox(width: 10), TagBadge('current', color: p4.accent)],
          ],
        ),
        const SizedBox(height: 4),
        Text(customApi ? '${s.hostOf(d)} · api $api' : s.hostOf(d), overflow: TextOverflow.ellipsis, style: p4.mono()),
        const SizedBox(height: 8),
        StatusIndicator(health, label: label),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: current ? null : () => s.connect(d.id), child: const Text('CONNECT')),
        IconButton(tooltip: 'Edit', onPressed: () => _edit(s, d), icon: const Icon(Icons.edit_outlined, size: 18)),
        IconButton(
          tooltip: current ? 'Connect to another deployment to remove this one' : 'Remove',
          onPressed: current ? null : () => s.removeDeployment(d.id),
          icon: const Icon(Icons.delete_outline, size: 18),
        ),
      ],
    );
    return Container(
      color: p4.bg2,
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      // Actions sit beside the details when there's room, below them on phones.
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 520
            ? Row(
                children: [
                  Expanded(child: info),
                  actions,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              ),
      ),
    );
  }
}

typedef _DeploymentForm = ({String name, String host, String apiBase});

/// Owns its controllers so they outlive the dialog's exit animation.
class _DeploymentDialog extends StatefulWidget {
  const _DeploymentDialog({this.initial});

  final _DeploymentForm? initial;

  @override
  State<_DeploymentDialog> createState() => _DeploymentDialogState();
}

class _DeploymentDialogState extends State<_DeploymentDialog> {
  P4Colors get p4 => context.p4;

  late final _name = TextEditingController(text: widget.initial?.name);
  late final _host = TextEditingController(text: widget.initial?.host);
  late final _api = TextEditingController(text: widget.initial?.apiBase);

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _api.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim(), host = _host.text.trim(), api = _api.text.trim();
    if (host.isEmpty) return;
    Navigator.pop<_DeploymentForm>(context, (name: name.isEmpty ? host : name, host: host, apiBase: api));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: p4.bg2,
      shape: RoundedRectangleBorder(side: BorderSide(color: p4.border2)),
      title: Text(widget.initial == null ? 'Add deployment' : 'Edit deployment', style: p4.display()),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: const InputDecoration(labelText: 'Client name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _host,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: const InputDecoration(labelText: 'Host', hintText: '192.168.1.50'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _api,
              style: p4.mono(size: 13, color: p4.text, spacing: 0),
              decoration: const InputDecoration(
                labelText: 'API URL (optional)',
                hintText: 'http://<host>:8000',
                helperText: 'Only if the API isn\'t on port 8000 of the host',
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(onPressed: _save, child: const Text('SAVE')),
      ],
    );
  }
}
