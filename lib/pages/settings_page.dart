import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final s = SettingsScope.of(context);
    final brand = BrandScope.of(context);
    final session = SessionScope.of(context);
    // Clients only get appearance, account and about; everything else is admin configuration.
    final admin = session.isAdmin;
    return Scaffold(
      appBar: AppBar(title: const Text('settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section('appearance', [
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        shape: const RoundedRectangleBorder(),
                        selectedBackgroundColor: p4.accent,
                        selectedForegroundColor: p4.onAccent,
                        textStyle: p4.mono(size: 11, weight: FontWeight.w600),
                        side: BorderSide(color: p4.border2),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('SYSTEM'),
                          icon: Icon(Icons.brightness_auto_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('LIGHT'),
                          icon: Icon(Icons.light_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('DARK'),
                          icon: Icon(Icons.dark_mode_outlined, size: 16),
                        ),
                      ],
                      selected: {s.themeMode},
                      onSelectionChanged: (v) => s.themeMode = v.first,
                    ),
                  ]),
                  if (admin) ...[
                    _section('connection', [
                      Text(
                        'This section and the ones below belong to the "${s.deployment.name}" deployment. '
                        'Switch deployments from the Clients tab.',
                        style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                      ),
                      _Field(
                        'Host',
                        s.host,
                        (v) => s.host = v,
                        help: 'Machine running the ${brand.platform} stacks. From the Android emulator use 10.0.2.2.',
                      ),
                      _Field(
                        '${brand.platform}-api base URL',
                        s.apiBase,
                        (v) => s.apiBase = v,
                        hint: s.url(8000).toString(),
                      ),
                    ]),
                    if (brand.tabs.contains(DashTab.edge))
                      _section('edge metrics', [
                        _Field(
                          'Metrics URL',
                          s.edgeMetricsUrl,
                          (v) => s.edgeMetricsUrl = v,
                          hint: s.apiUri.resolve('/api/v1/edge/metrics').toString(),
                          help: 'Endpoint returning the edge metrics JSON (see README).',
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Demo data', style: p4.display(size: 14)),
                          subtitle: Text('Synthetic metrics for previewing without an edge device', style: p4.mono()),
                          value: s.edgeDemo,
                          onChanged: (v) => s.edgeDemo = v,
                        ),
                      ]),
                    if (brand.tabs.contains(DashTab.agent))
                      _section('agent', [
                        _Field(
                          'Letta server password',
                          s.lettaToken,
                          (v) => s.lettaToken = v,
                          obscure: true,
                          help: 'Only needed if LETTA_SERVER_PASSWORD is set.',
                        ),
                      ]),
                    if (brand.tabs.contains(DashTab.grafana))
                      _section('grafana', [
                        _Field(
                          'Dashboard path',
                          s.grafanaPath,
                          (v) => s.grafanaPath = v,
                          hint: '/d/<uid>/<slug>',
                          help: 'Path on ${s.url(3000)} to open in the Grafana tab.',
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Kiosk mode', style: p4.display(size: 14)),
                          subtitle: Text('Hide Grafana navigation chrome', style: p4.mono()),
                          value: s.grafanaKiosk,
                          onChanged: (v) => s.grafanaKiosk = v,
                        ),
                      ]),
                    if (brand.tabs.contains(DashTab.video))
                      _section('video', [
                        for (final c in s.cameras) Text('${c.name}  ${c.url}', style: p4.mono(color: p4.text)),
                        Text(
                          '${s.cameras.isEmpty ? 'No cameras yet. ' : ''}Add, edit and remove cameras on the Video tab.',
                          style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                        ),
                      ]),
                    _section('client view', [
                      Text(
                        'Tabs clients see after Home. Clients never see connection settings.',
                        style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in brand.tabs)
                            FilterChip(
                              label: Text(t.name.toUpperCase()),
                              selected: s.clientTabs.contains(t),
                              onSelected: (on) => s.clientTabs = [
                                for (final c in DashTab.values)
                                  if (c == t ? on : s.clientTabs.contains(c)) c,
                              ],
                            ),
                        ],
                      ),
                    ]),
                  ],
                  _section('account', [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Signed in as ${admin ? 'administrator' : 'client'}',
                            style: p4.display(size: 14),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                            session.signOut();
                          },
                          icon: const Icon(Icons.logout, size: 14),
                          label: const Text('SIGN OUT'),
                        ),
                      ],
                    ),
                  ]),
                  _section('about', [
                    Text(brand.appName, style: p4.display(size: 16)),
                    if (brand.tagline.isNotEmpty)
                      Text(
                        brand.tagline,
                        style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                      ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (final l in brand.links)
                          OutlinedButton.icon(
                            onPressed: () => launchUrl(l.url, mode: LaunchMode.externalApplication),
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: Text(l.label.toUpperCase()),
                          ),
                        // Fonts, Flutter and every package the app ships with.
                        OutlinedButton.icon(
                          onPressed: () => showLicensePage(context: context, applicationName: brand.appName),
                          icon: const Icon(Icons.gavel_outlined, size: 14),
                          label: const Text('LICENSES'),
                        ),
                      ],
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String tag, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(tag: tag, title: const SizedBox.shrink()),
        for (final c in children) Padding(padding: const EdgeInsets.only(bottom: 14), child: c),
      ],
    ),
  );
}

/// Text field that commits on submit or focus loss.
class _Field extends StatefulWidget {
  const _Field(this.label, this.value, this.onCommit, {this.hint, this.help, this.obscure = false});

  final String label;
  final String value;
  final ValueChanged<String> onCommit;
  final String? hint;
  final String? help;
  final bool obscure;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  P4Colors get p4 => context.p4;

  late final _ctrl = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  void _commit() {
    if (_ctrl.text.trim() != widget.value) widget.onCommit(_ctrl.text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      obscureText: widget.obscure,
      style: p4.mono(size: 13, color: p4.text, spacing: 0),
      onSubmitted: (_) => _commit(),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.help,
        helperStyle: p4.mono(size: 10, spacing: 0),
        helperMaxLines: 2,
      ),
    );
  }
}
