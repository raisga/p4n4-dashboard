import 'dart:async';

import 'package:flutter/material.dart';

import '../api/fleet.dart';
import '../api/services.dart';
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

  /// Keyed by host, so renaming a deployment keeps its status.
  final _reports = <String, ServiceReport>{};
  final _checking = <String>{};
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
    _schedule();
  }

  @override
  void didUpdateWidget(ClientsTab old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _refresh();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.active) _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!widget.active) return;
    final byHost = {for (final d in SettingsScope.of(context).deployments) d.host: d};
    await Future.wait(byHost.values.map(_check));
  }

  Future<void> _check(Deployment d) async {
    if (!_checking.add(d.host)) return;
    setState(() {});
    try {
      final r = await checkServices(d.apiUri, (s) => Uri.parse('http://${d.host}:${s.port}${s.path}'));
      if (mounted) setState(() => _reports[d.host] = r);
    } finally {
      if (mounted) setState(() => _checking.remove(d.host));
    }
  }

  Future<void> _edit(AppSettings s, [int? index]) async {
    final list = s.deployments;
    final result = await showDialog<Deployment>(
      context: context,
      builder: (_) => _DeploymentDialog(initial: index == null ? null : list[index]),
    );
    if (result == null) return;
    if (index == null) {
      list.add(result);
    } else {
      list[index] = result;
    }
    s.deployments = list;
    unawaited(_check(result));
  }

  void _remove(AppSettings s, int index) {
    final list = s.deployments..removeAt(index);
    s.deployments = list;
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
                    'Status comes from each host\'s API on port 8000, or from probing service ports when it\'s down. '
                    'Connect switches this dashboard to that host.',
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
                          for (final (i, d) in list.indexed) ...[if (i > 0) const SizedBox(height: 1), _row(s, i, d)],
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

  Widget _row(AppSettings s, int i, Deployment d) {
    final r = _reports[d.host];
    final current = d.host == s.host;
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
        Text(d.host, overflow: TextOverflow.ellipsis, style: p4.mono()),
        const SizedBox(height: 8),
        StatusIndicator(health, label: label),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: current ? null : () => s.host = d.host, child: const Text('CONNECT')),
        IconButton(tooltip: 'Edit', onPressed: () => _edit(s, i), icon: const Icon(Icons.edit_outlined, size: 18)),
        IconButton(tooltip: 'Remove', onPressed: () => _remove(s, i), icon: const Icon(Icons.delete_outline, size: 18)),
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

/// Owns its controllers so they outlive the dialog's exit animation.
class _DeploymentDialog extends StatefulWidget {
  const _DeploymentDialog({this.initial});

  final Deployment? initial;

  @override
  State<_DeploymentDialog> createState() => _DeploymentDialogState();
}

class _DeploymentDialogState extends State<_DeploymentDialog> {
  P4Colors get p4 => context.p4;

  late final _name = TextEditingController(text: widget.initial?.name);
  late final _host = TextEditingController(text: widget.initial?.host);

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim(), host = _host.text.trim();
    if (host.isEmpty) return;
    Navigator.pop(context, Deployment(name.isEmpty ? host : name, host));
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
