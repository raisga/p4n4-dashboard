import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/services.dart';
import '../api/stack_control.dart';
import '../api/status_monitor.dart';
import '../core/brand.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';

/// Service launcher with live Compose status from p4n4-api. Admins can also
/// start, restart and stop stacks; viewers (if an admin gives them this tab)
/// see only the apps they can open, without hosts or ports.
class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key, required this.active});

  final bool active;

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  late StatusMonitor _monitor;
  late StatusTarget _target;

  /// Shown while visible; the shared [StatusMonitor] does the polling.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _monitor = StatusScope.of(context);
    _target = SettingsScope.of(context).statusTarget;
    _watch();
  }

  @override
  void didUpdateWidget(ServicesTab old) {
    super.didUpdateWidget(old);
    _watch();
  }

  void _watch() =>
      widget.active ? _monitor.watch(this, [_target], interval: const Duration(seconds: 15)) : _monitor.unwatch(this);

  @override
  void dispose() {
    _monitor.unwatch(this);
    super.dispose();
  }

  Future<void> _refresh() => _monitor.refresh(_target);

  static Health _healthOf(ServiceDef def, ServiceReport? r) => switch (r?.up[def]) {
    _ when r == null => Health.pending,
    true => Health.up,
    false => Health.down,
    null => Health.unknown,
  };

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final status = StatusScope.of(context).statusOf(_target);
    final technical = SessionScope.of(context).isTechnical;
    final brand = BrandScope.of(context);
    final viaApi = status.report?.viaApi;
    return PageBody(
      onRefresh: _refresh,
      children: [
        PageHeader(
          title: l.servicesTitle,
          subtitle: technical ? l.servicesSubtitle(settings.host) : l.servicesSubtitlePlain,
          trailing: RefreshButton(busy: status.checking, onPressed: _refresh),
        ),
        if (technical) ...[
          const SizedBox(height: 8),
          Text(switch (viaApi) {
            false => l.servicesApiUnreachable(brand.platform),
            true => l.servicesLiveFrom(settings.apiUri.authority),
            null => l.servicesContacting(settings.apiUri.authority),
          }, style: p4.body(size: 13, color: viaApi == false ? p4.warn : p4.muted)),
        ],
        const SizedBox(height: 28),
        for (final stack in stacks.where(settings.showsStack))
          // Viewers only get what they can open: no gateway, no TCP-only brokers.
          if (technical || stack.suffix != 'api') ...[
            _stackSection(stack, settings, status.report, technical),
            const SizedBox(height: 32),
          ],
      ],
    );
  }

  Widget _stackSection(StackDef stack, AppSettings settings, ServiceReport? report, bool technical) {
    final services = [
      for (final s in stack.services)
        if (technical || !s.tcpOnly) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: stack.tone(p4), shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(l.stackLabel(stack), style: p4.display(size: 18))),
            if (technical) ...[
              const SizedBox(width: 10),
              TagBadge(stack.suffix == 'api' ? l.endpointCount(services.length) : l.serviceCount(services.length)),
            ],
            const Spacer(),
            if (SessionScope.of(context).isAdmin && stack.suffix != 'api') _StackControls(stack, onDone: _refresh),
          ],
        ),
        const SizedBox(height: 14),
        TileGrid(
          minWidth: 260,
          children: [
            for (final svc in services)
              _ServiceCard(svc, stack.tone(p4), _healthOf(svc, report), settings, technical: technical),
          ],
        ),
      ],
    );
  }
}

/// Start, restart and stop for one stack (admins only; the API checks too).
/// Stopping and restarting ask first: they take services away from everyone.
class _StackControls extends StatefulWidget {
  const _StackControls(this.stack, {required this.onDone});

  final StackDef stack;
  final Future<void> Function() onDone;

  @override
  State<_StackControls> createState() => _StackControlsState();
}

class _StackControlsState extends State<_StackControls> {
  bool _running = false;

  Future<void> _run(StackAction action) async {
    final l = context.l10n;
    final name = l.stackLabel(widget.stack);
    final confirm = switch (action) {
      StackAction.up => null,
      StackAction.restart => (l.stackConfirmRestart(name), l.stackConfirmRestartBody, l.stackRestart),
      StackAction.down => (l.stackConfirmStop(name), l.stackConfirmStopBody, l.stackStop),
    };
    if (confirm case (final title, final body, final verb)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(verb)),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final api = SettingsScope.of(context).apiUri;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _running = true);
    messenger.showSnackBar(SnackBar(content: Text(l.stackJobRunning(name))));
    String result;
    try {
      final job = await runStackAction(api, widget.stack.suffix, action);
      result = job.failed ? l.stackJobFailed(name, job.output.lastOrNull ?? job.status) : l.stackJobDone(name);
    } catch (e) {
      result = l.stackJobFailed(name, '$e');
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result)));
    if (mounted) setState(() => _running = false);
    await widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    if (_running) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent)),
      );
    }
    return PopupMenuButton<StackAction>(
      tooltip: l.stackControls,
      icon: Icon(Icons.more_horiz, color: p4.muted),
      onSelected: _run,
      itemBuilder: (_) => [
        for (final (action, icon, label) in [
          (StackAction.up, Icons.play_arrow_outlined, l.stackStart),
          (StackAction.restart, Icons.restart_alt, l.stackRestart),
          (StackAction.down, Icons.stop_outlined, l.stackStop),
        ])
          PopupMenuItem(
            value: action,
            child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 12), Text(label)]),
          ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard(this.def, this.color, this.health, this.settings, {required this.technical});

  final ServiceDef def;
  final Color color;
  final Health health;
  final AppSettings settings;
  final bool technical;

  Future<void> _open(BuildContext context) async {
    final uri = settings.url(def.port, def.path);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpen('$uri'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: def.tcpOnly ? null : () => _open(context),
        hoverColor: p4.bg3,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(Radii.control),
                    ),
                    child: Icon(def.icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      def.label(BrandScope.of(context).platform),
                      overflow: TextOverflow.ellipsis,
                      style: p4.display(size: 16),
                    ),
                  ),
                  if (!def.tcpOnly) StatusIndicator(health),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: Text(
                  l.serviceDesc(def),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: p4.body(size: 14, color: p4.muted),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: technical
                        ? Text(
                            '${settings.host}:${def.port}${def.path}',
                            overflow: TextOverflow.ellipsis,
                            style: p4.mono(size: 12, spacing: 0),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (def.tcpOnly)
                    TagBadge(l.tcpOnly)
                  else
                    FilledButton.tonalIcon(
                      onPressed: () => _open(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        backgroundColor: p4.accent.withValues(alpha: 0.14),
                        foregroundColor: p4.accent,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(l.open),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
