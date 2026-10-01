import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/services.dart';
import '../api/status_monitor.dart';
import '../core/brand.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Service launcher with live Compose status from p4n4-api.
class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key, required this.active});

  final bool active;

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  P4Colors get p4 => context.p4;

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
                  _header(settings, status),
                  const SizedBox(height: 32),
                  for (final stack in stacks) ...[
                    _stackSection(stack, settings, status.report),
                    const SizedBox(height: 36),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppSettings settings, TargetStatus status) {
    final brand = BrandScope.of(context);
    final viaApi = status.report?.viaApi;
    final loading = status.checking;
    final apiLabel = switch (viaApi) {
      false => '${brand.platform}-api unreachable — probing service ports directly',
      true => 'Live status from ${settings.apiUri.authority}',
      null => 'Contacting ${settings.apiUri.authority}…',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          tag: 'dashboard',
          title: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Service '),
                TextSpan(
                  text: 'Launcher',
                  style: TextStyle(color: p4.accent),
                ),
              ],
            ),
            style: p4.display(size: 32, weight: FontWeight.w800, spacing: -1.5),
          ),
          trailing: IconButton(
            tooltip: 'Refresh status',
            onPressed: loading ? null : _refresh,
            icon: loading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent))
                : Icon(Icons.refresh, color: p4.muted),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Direct access to all running ${brand.platform} services across the IoT, AI, and Edge stacks on ${settings.host}.',
          style: p4.display(size: 14, color: p4.muted, weight: FontWeight.w400, spacing: 0),
        ),
        const SizedBox(height: 10),
        Text(apiLabel, style: p4.mono(color: viaApi == false ? p4.warn : p4.muted)),
      ],
    );
  }

  Widget _stackSection(StackDef stack, AppSettings settings, ServiceReport? report) {
    final n = stack.services.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          tag: stack.label,
          tagColor: stack.tone(p4),
          title: Row(
            children: [
              StackName(stack.suffix),
              const SizedBox(width: 12),
              TagBadge('$n ${stack.suffix == 'api' ? 'endpoint' : 'service'}${n == 1 ? '' : 's'}'),
            ],
          ),
          trailing: SessionScope.of(context).isAdmin && stack.suffix != 'api' ? const _StackControls() : null,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final cols = (c.maxWidth / 260).floor().clamp(1, 4);
            final w = (c.maxWidth - 2 - (cols - 1)) / cols - 0.01;
            return Container(
              color: p4.border,
              padding: const EdgeInsets.all(1),
              child: Wrap(
                spacing: 1,
                runSpacing: 1,
                children: [
                  for (final svc in stack.services)
                    SizedBox(width: w, child: _ServiceCard(svc, stack.tone(p4), _healthOf(svc, report), settings)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Start/restart/stop menu for a stack. The actions stay disabled until
/// p4n4-api has state-changing stack endpoints; wire them up then.
class _StackControls extends StatelessWidget {
  const _StackControls();

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return PopupMenuButton<void>(
      tooltip: 'Stack controls',
      icon: Icon(Icons.more_vert, color: p4.muted),
      color: p4.bg3,
      itemBuilder: (_) => [
        for (final (icon, label) in [
          (Icons.play_arrow_outlined, 'Start'),
          (Icons.restart_alt, 'Restart'),
          (Icons.stop_outlined, 'Stop'),
        ])
          PopupMenuItem(
            enabled: false,
            child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 12), Text(label)]),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: false,
          child: Text('Needs stack control endpoints in the API', style: p4.mono(size: 10, spacing: 0)),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatefulWidget {
  const _ServiceCard(this.def, this.color, this.health, this.settings);

  final ServiceDef def;
  final Color color;
  final Health health;
  final AppSettings settings;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  P4Colors get p4 => context.p4;

  bool _hover = false;

  Future<void> _open() async {
    final uri = widget.settings.url(widget.def.port, widget.def.path);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $uri')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _hover ? p4.bg3 : p4.bg2,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(def.icon, color: widget.color, size: 26),
                      const Spacer(),
                      if (!def.tcpOnly) StatusIndicator(widget.health),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(def.label(BrandScope.of(context).platform), style: p4.display()),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: Text(
                      def.desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.settings.host}:${def.port}${def.path}',
                          overflow: TextOverflow.ellipsis,
                          style: p4.mono(spacing: 0.05),
                        ),
                      ),
                      if (def.tcpOnly)
                        const TagBadge('TCP only')
                      else
                        FilledButton(
                          onPressed: _open,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('OPEN'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                scale: _hover ? 1 : 0,
                alignment: Alignment.centerLeft,
                child: Container(height: 2, color: widget.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
