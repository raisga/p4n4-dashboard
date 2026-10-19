import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/services.dart';
import '../api/stack_control.dart';
import '../api/status_monitor.dart';
import '../core/brand.dart';
import '../core/format.dart';
import '../core/incidents.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../pages/logs_page.dart';
import '../widgets/common.dart';
import '../widgets/service_viewer.dart';
import 'grafana_tab.dart' show grafanaKeepQuery, themedGrafanaUri;

/// Service launcher with live Compose status from p4n4-api. Admins can also
/// start, restart and stop stacks; viewers (if an admin gives them this tab)
/// see only the apps they can open, without hosts or ports.
///
/// Services with a web app ([ServiceDef.embed]) open in the [ServiceViewer]:
/// in place of the cards on wide screens, on a page of their own on phones.
/// The others, and Open in browser on any card, go to the browser.
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

  /// Open in place of the cards (wide screens).
  ServiceDef? _viewing;

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

  /// In the viewer if it has a web app (beside the navigation on wide screens,
  /// on its own page on phones), else in the browser.
  void _open(ServiceDef def) {
    if (!def.embed) {
      openServiceExternally(context, def);
    } else if (MediaQuery.sizeOf(context).width >= 800) {
      setState(() => _viewing = def);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Builder(
                builder: (context) => serviceViewerFor(context, def, onClose: () => Navigator.pop(context)),
              ),
            ),
          ),
        ),
      );
    }
  }

  static Health _healthOf(ServiceDef def, ServiceReport? r) => switch (r?.up[def]) {
    _ when r == null => Health.pending,
    true => Health.up,
    false => Health.down,
    null => Health.unknown,
  };

  @override
  Widget build(BuildContext context) {
    if (_viewing case final def?) {
      void close() => setState(() => _viewing = null);
      // Back (Android, Escape on the desktop) returns to the cards first.
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) close();
        },
        child: serviceViewerFor(context, def, onClose: close),
      );
    }
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
            false => switch (status.report?.apiProblem) {
              // Inside parentheses: without the API's own full stop
              final reason? => l.servicesApiNoStatus(brand.platform, reason.replaceFirst(RegExp(r'\.$'), '')),
              null => l.servicesApiUnreachable(brand.platform),
            },
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
              _ServiceCard(
                svc,
                stack.tone(p4),
                _healthOf(svc, report),
                settings,
                technical: technical,
                detail: technical ? report?.detail[svc] : null,
                onRestarted: _refresh,
                onOpen: () => _open(svc),
              ),
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

  Future<void> _run(StackAction? action) async {
    final l = context.l10n;
    final name = l.stackLabel(widget.stack);
    if (action == null) return openLogs(context, stack: widget.stack.suffix, title: name);
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
    // A null value is the logs.
    return PopupMenuButton<StackAction?>(
      tooltip: l.stackControls,
      icon: Icon(Icons.more_horiz, color: p4.muted),
      onSelected: _run,
      itemBuilder: (_) => [
        for (final (action, icon, label) in [
          (StackAction.up, Icons.play_arrow_outlined, l.stackStart),
          (StackAction.restart, Icons.restart_alt, l.stackRestart),
          (StackAction.down, Icons.stop_outlined, l.stackStop),
          (null, Icons.notes, l.logsMenu),
        ])
          PopupMenuItem(
            value: action,
            child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 12), Text(label)]),
          ),
      ],
    );
  }
}

/// Opens the logs of [stack], or of one [service] in it.
Future<void> openLogs(BuildContext context, {required String stack, String? service, required String title}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LogsPage(stack: stack, service: service, title: title),
      ),
    );

class _ServiceCard extends StatelessWidget {
  const _ServiceCard(
    this.def,
    this.color,
    this.health,
    this.settings, {
    required this.technical,
    this.detail,
    required this.onRestarted,
    required this.onOpen,
  });

  final ServiceDef def;
  final Color color;
  final Health health;
  final AppSettings settings;
  final bool technical;

  /// What p4n4-api says about its Compose service, for admins and power users.
  final ComposeService? detail;
  final Future<void> Function() onRestarted;

  /// In the viewer, or the browser (see [_ServicesTabState._open]).
  final VoidCallback onOpen;

  /// Restarts just this service, after asking: it's gone for everyone meanwhile.
  Future<void> _restart(BuildContext context, ComposeService svc, String name) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.stackConfirmRestart(name)),
        content: Text(l.serviceConfirmRestartBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.stackRestart)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final api = settings.apiUri;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l.stackJobRunning(name))));
    String result;
    try {
      final job = await waitForJob(api, await startServiceRestart(api, svc.stack, svc.name));
      result = job.failed ? l.stackJobFailed(name, job.output.lastOrNull ?? job.status) : l.stackJobDone(name);
    } catch (e) {
      result = l.stackJobFailed(name, '$e');
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result)));
    await onRestarted();
  }

  /// Online or not; an outage seen from here also says for how long, amber
  /// at first and red past the deployment's threshold (Settings → Thresholds).
  Widget _status(BuildContext context, String name) {
    final since = health == Health.down
        ? IncidentScope.maybeOf(context)?.ongoing(settings.deployment, def.name)?.lengthAt(DateTime.now())
        : null;
    if (since == null) return StatusIndicator(health);
    return StatusIndicator(
      health,
      label: context.l10n.serviceDownFor(context.formats.span(since)),
      color: levelColor(context.p4, settings.thresholds.downLevel(since)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final f = context.formats;
    final name = def.label(BrandScope.of(context).platform);
    final svc = detail;
    final admin = SessionScope.of(context).isAdmin;
    // Version, then how long it has run, or Docker's word on why it stopped.
    final facts = svc == null
        ? null
        : [
            ?svc.version,
            if (svc.uptime case final up?) l.serviceUptime(f.span(up)),
            if (!svc.running) ?svc.status,
          ].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: def.tcpOnly ? null : onOpen,
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
                    child: Text(name, overflow: TextOverflow.ellipsis, style: p4.display(size: 16)),
                  ),
                  if (!def.tcpOnly) Flexible(child: _status(context, name)),
                  if (admin && svc != null)
                    PopupMenuButton<String>(
                      tooltip: l.serviceActions(name),
                      icon: Icon(Icons.more_vert, size: 18, color: p4.muted),
                      onSelected: (v) => v == 'logs'
                          ? openLogs(context, stack: svc.stack, service: svc.name, title: name)
                          : _restart(context, svc, name),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'logs',
                          child: Row(
                            children: [const Icon(Icons.notes, size: 18), const SizedBox(width: 12), Text(l.logsMenu)],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'restart',
                          child: Row(
                            children: [
                              const Icon(Icons.restart_alt, size: 18),
                              const SizedBox(width: 12),
                              Text(l.stackRestart),
                            ],
                          ),
                        ),
                      ],
                    ),
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
              if (svc != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (svc.unhealthy || svc.health == 'starting') ...[
                      TagBadge(
                        svc.unhealthy ? l.serviceUnhealthy : l.serviceStarting,
                        color: svc.unhealthy ? p4.err : p4.warn,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Tooltip(
                        message: svc.image ?? '',
                        child: Text(
                          facts!.isEmpty ? (svc.image ?? '') : facts,
                          overflow: TextOverflow.ellipsis,
                          style: p4.mono(size: 12, color: p4.muted, spacing: 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: technical
                        ? Text(
                            _address(settings.serviceUri(def)),
                            overflow: TextOverflow.ellipsis,
                            style: p4.mono(size: 12, spacing: 0),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (def.tcpOnly)
                    TagBadge(l.tcpOnly)
                  else ...[
                    // The viewer's way out to the browser, from the card itself.
                    if (def.embed)
                      IconButton(
                        tooltip: l.openInBrowser,
                        onPressed: () => openServiceExternally(context, def),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                        icon: Icon(Icons.open_in_new, size: 16, color: p4.muted),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        backgroundColor: p4.accent.withValues(alpha: 0.14),
                        foregroundColor: p4.accent,
                      ),
                      icon: Icon(def.embed ? Icons.web_outlined : Icons.open_in_new, size: 16),
                      label: Text(l.open),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `host:port/path` for the card, or the whole URL for one on a proxy path.
String _address(Uri uri) => uri.hasPort ? '${uri.host}:${uri.port}${uri.path == '/' ? '' : uri.path}' : '$uri';

/// Where [def] opens for [context]'s view: Grafana in the app's theme, the
/// others at their URL (Settings → Endpoints, the project's or the port).
Uri serviceUriFor(BuildContext context, ServiceDef def) {
  final uri = SettingsScope.of(context).serviceUri(def, view: SessionScope.of(context).role ?? Role.normie);
  return def.id == 'grafana' ? themedGrafanaUri(uri, Theme.of(context).brightness) : uri;
}

/// Opens [def] in the browser; says so if it can't, without the URL for normies.
Future<void> openServiceExternally(BuildContext context, ServiceDef def) async {
  final l = context.l10n;
  final uri = serviceUriFor(context, def);
  final name = def.label(BrandScope.of(context).platform);
  final technical = SessionScope.of(context).isTechnical;
  final messenger = ScaffoldMessenger.of(context);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false)) {
    messenger.showSnackBar(SnackBar(content: Text(technical ? l.couldNotOpen('$uri') : l.couldNotOpenService(name))));
  }
}

/// [def] in a [ServiceViewer] with its live status, for the Services tab or
/// its own page.
Widget serviceViewerFor(BuildContext context, ServiceDef def, {required VoidCallback onClose}) {
  final settings = SettingsScope.of(context);
  final monitor = StatusScope.of(context);
  final target = settings.statusTarget;
  return ServiceViewer(
    uri: serviceUriFor(context, def),
    title: def.label(BrandScope.of(context).platform),
    icon: def.icon,
    health: _ServicesTabState._healthOf(def, monitor.statusOf(target).report),
    technical: SessionScope.of(context).isTechnical,
    sameOriginOnly: def.sameOriginOnly,
    keepQuery: def.id == 'grafana' ? grafanaKeepQuery : const {},
    onClose: onClose,
    onRetry: () => monitor.refresh(target),
  );
}
