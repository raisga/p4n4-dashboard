import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/auth.dart' as auth;
import '../core/brand.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Sign-in for the connected deployment.
///
/// Asks its p4n4-api first ([auth.probeAuth]):
/// - auth on → username and password; the role comes from the account;
/// - auth off (`P4N4_API_AUTH=off`) → the role picker, labelled as such;
/// - unreachable → an error with retry, and the picker behind "continue
///   without signing in", since the dashboard is still useful without the API.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  P4Colors get p4 => context.p4;

  Uri? _api;
  Future<auth.AuthMode>? _mode;
  bool _offline = false;
  bool _editServer = false;

  final _user = TextEditingController();
  final _password = TextEditingController();

  /// Disabling the fields while signing in drops focus; a failed attempt
  /// gives it back to the password.
  final _passwordFocus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = SettingsScope.of(context).apiUri;
    if (api != _api) _check(api);
  }

  void _check(Uri api) {
    _api = api;
    _mode = SessionScope.of(context).probe(api);
    _offline = false;
    _error = null;
  }

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy || _user.text.trim().isEmpty || _password.text.isEmpty) return;
    final session = SessionScope.of(context);
    final platform = BrandScope.of(context).platform;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.signInWithPassword(_user.text, _password.text);
    } on auth.AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Can\'t reach $platform-api. Check the server and try again.';
    }
    if (mounted) {
      setState(() => _busy = false);
      if (_error != null) {
        _password.clear();
        // After the rebuild that re-enables the field: a disabled one can't take focus.
        WidgetsBinding.instance.addPostFrameCallback((_) => _passwordFocus.requestFocus());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: DefaultTextStyle(
                      style: p4.mono(size: 30, color: p4.accent, weight: FontWeight.w700, spacing: -0.05),
                      child: const Wordmark(size: 30),
                    ),
                  ),
                  if (brand.tagline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(brand.tagline, textAlign: TextAlign.center, style: p4.mono()),
                  ],
                  const SizedBox(height: 40),
                  FutureBuilder<auth.AuthMode>(
                    future: _mode,
                    builder: (context, snap) => switch (snap.data) {
                      _ when snap.connectionState != ConnectionState.done => _checking(),
                      auth.AuthMode.required => _form(),
                      auth.AuthMode.off => _picker(
                        'Choose how to continue',
                        '${brand.platform}-api runs without sign-in (P4N4_API_AUTH=off), so anyone can pick a role.',
                      ),
                      _ => _unreachable(),
                    },
                  ),
                  const SizedBox(height: 24),
                  _server(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _checking() => Column(
    children: [
      const SizedBox(height: 24),
      CircularProgressIndicator(color: p4.accent),
      const SizedBox(height: 16),
      Text('Connecting…', style: p4.mono()),
    ],
  );

  Widget _form() => AutofillGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(tag: 'sign in', title: const Text('Welcome back')),
        const SizedBox(height: 16),
        TextField(
          controller: _user,
          enabled: !_busy,
          autofocus: true,
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          focusNode: _passwordFocus,
          enabled: !_busy,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _signIn(),
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: p4.display(size: 13, color: p4.err, weight: FontWeight.w500, spacing: 0),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _signIn,
          child: _busy
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.onAccent))
              : const Text('SIGN IN'),
        ),
      ],
    ),
  );

  Widget _unreachable() {
    final brand = BrandScope.of(context);
    if (_offline) {
      return _picker(
        'Continue without signing in',
        'Without ${brand.platform}-api, service status comes from port checks and the role is your choice.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(tag: 'sign in', title: Text('Can\'t reach ${brand.platform}-api')),
        const SizedBox(height: 12),
        Text(
          'Signing in needs ${brand.platform}-api at ${_api ?? ''}. Check that it\'s running and reachable '
          'from this device, or change the server below.',
          style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => setState(() => _check(_api!)), child: const Text('RETRY')),
        const SizedBox(height: 8),
        TextButton(onPressed: () => setState(() => _offline = true), child: const Text('CONTINUE WITHOUT SIGNING IN')),
      ],
    );
  }

  Widget _picker(String title, String note) {
    final session = SessionScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(tag: 'sign in', title: Text(title)),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Administrator',
          desc: 'Every service, client deployments, stack controls and connection settings.',
          onTap: () => session.signInLocal(Role.admin),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: Icons.person_outline,
          title: 'Client',
          desc: 'System health at a glance, dashboards, camera and assistant.',
          onTap: () => session.signInLocal(Role.client),
        ),
        const SizedBox(height: 16),
        Text(note, textAlign: TextAlign.center, style: p4.mono(size: 10, spacing: 0)),
      ],
    );
  }

  /// Where sign-in goes. On web it's the page's own server (or config.json),
  /// so it's only shown; elsewhere it can be changed before signing in.
  Widget _server() {
    final s = SettingsScope.of(context);
    if (!_editServer) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text('server · ${s.apiUri}', overflow: TextOverflow.ellipsis, style: p4.mono(size: 10)),
          ),
          if (!kIsWeb) TextButton(onPressed: () => setState(() => _editServer = true), child: const Text('CHANGE')),
        ],
      );
    }
    return _ServerForm(settings: s, onDone: () => setState(() => _editServer = false));
  }
}

class _ServerForm extends StatefulWidget {
  const _ServerForm({required this.settings, required this.onDone});

  final AppSettings settings;
  final VoidCallback onDone;

  @override
  State<_ServerForm> createState() => _ServerFormState();
}

class _ServerFormState extends State<_ServerForm> {
  late final _host = TextEditingController(text: widget.settings.host);
  late final _api = TextEditingController(text: widget.settings.apiBase);

  @override
  void dispose() {
    _host.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = widget.settings;
    if (_host.text.trim().isNotEmpty) s.host = _host.text;
    s.apiBase = _api.text;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final platform = BrandScope.of(context).platform;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _host,
          decoration: InputDecoration(
            labelText: 'Host',
            helperText: 'Machine running the $platform stacks. From the Android emulator use 10.0.2.2.',
            helperStyle: p4.mono(size: 10, spacing: 0),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _api,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: '$platform-api base URL (optional)',
            hintText: widget.settings.url(8000, '/').toString(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: widget.onDone, child: const Text('CANCEL')),
            const SizedBox(width: 8),
            FilledButton(onPressed: _save, child: const Text('SAVE')),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.desc, required this.onTap});

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    return Material(
      color: p4.bg2,
      shape: Border.all(color: p4.border),
      child: InkWell(
        onTap: onTap,
        hoverColor: p4.bg3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: p4.accent, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: p4.display()),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: p4.display(size: 13, color: p4.muted, weight: FontWeight.w400, spacing: 0),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p4.muted),
            ],
          ),
        ),
      ),
    );
  }
}
