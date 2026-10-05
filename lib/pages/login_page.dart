import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/auth.dart' as auth;
import '../core/brand.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';

/// Sign-in for the connected deployment.
///
/// Asks its p4n4-api first ([auth.probeAuth]):
/// - auth on → username and password; the role comes from the account;
/// - auth off (`P4N4_API_AUTH=off`) → the role picker, labelled as such;
/// - unreachable → an error with retry, and the picker behind "continue
///   without signing in", since the dashboard is still useful without the API.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.offerDevUsers = devUsers});

  /// One-tap sign-in with p4n4-api's dev accounts, under the form.
  final bool offerDevUsers;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

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

  Future<void> _signInAs(String user, String password) {
    _user.text = user;
    _password.text = password;
    return _signIn();
  }

  Future<void> _signIn() async {
    if (_busy || _user.text.trim().isEmpty || _password.text.isEmpty) return;
    final session = SessionScope.of(context);
    final platform = BrandScope.of(context).platform;
    final l = this.l;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.signInWithPassword(_user.text, _password.text);
    } on auth.AuthException catch (e) {
      _error = switch (e.statusCode) {
        401 => l.signInWrongCredentials,
        429 => l.signInRateLimited,
        _ => e.message,
      };
    } catch (_) {
      _error = l.signInApiFailed(platform);
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
                  const Center(child: Wordmark(size: 30)),
                  if (brand.tagline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      brand.tagline,
                      textAlign: TextAlign.center,
                      style: p4.body(color: p4.muted),
                    ),
                  ],
                  const SizedBox(height: 40),
                  FutureBuilder<auth.AuthMode>(
                    future: _mode,
                    builder: (context, snap) => switch (snap.data) {
                      _ when snap.connectionState != ConnectionState.done => _checking(),
                      auth.AuthMode.required => _form(),
                      auth.AuthMode.off => _picker(l.signInChooseTitle, l.signInAuthOffNote(brand.platform)),
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
      Text(l.signInConnecting, style: p4.body(color: p4.muted)),
    ],
  );

  Widget _form() => AutofillGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(tag: l.signInTag, title: Text(l.signInWelcome)),
        const SizedBox(height: 16),
        TextField(
          controller: _user,
          enabled: !_busy,
          autofocus: true,
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l.fieldUsername),
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
          decoration: InputDecoration(labelText: l.fieldPassword),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: p4.body(size: 14, color: p4.err, weight: FontWeight.w500),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _signIn,
          child: _busy
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.onAccent))
              : Text(l.signInButton),
        ),
        if (widget.offerDevUsers) ...[const SizedBox(height: 24), _devUsers()],
      ],
    ),
  );

  Widget _unreachable() {
    final brand = BrandScope.of(context);
    if (_offline) {
      return _picker(l.signInOfflineTitle, l.signInOfflineNote(brand.platform));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(tag: l.signInTag, title: Text(l.signInUnreachableTitle(brand.platform))),
        const SizedBox(height: 12),
        Text(l.signInUnreachableBody(brand.platform, '${_api ?? ''}'), style: p4.body(color: p4.muted)),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => setState(() => _check(_api!)), child: Text(l.retry)),
        const SizedBox(height: 8),
        TextButton(onPressed: () => setState(() => _offline = true), child: Text(l.signInOfflineButton)),
      ],
    );
  }

  /// Dev builds only (see [devUsers]): needs the API started with
  /// `P4N4_API_DEV_USERS=true`, or `p4n4-api users dev`.
  Widget _devUsers() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        l.signInDevAccounts,
        textAlign: TextAlign.center,
        style: p4.body(size: 12, color: p4.muted),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final (i, (user, view)) in devAccounts.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _signInAs(user, devPassword),
                child: Text(l.roleName(view), overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 6),
      Text(
        l.signInDevAccountsNote(BrandScope.of(context).platform),
        textAlign: TextAlign.center,
        style: p4.body(size: 12, color: p4.muted),
      ),
    ],
  );

  Widget _picker(String title, String note) {
    final session = SessionScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(tag: l.signInTag, title: Text(title)),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.admin_panel_settings_outlined,
          title: l.roleAdminTitle,
          desc: l.roleAdminDesc,
          onTap: () => session.signInLocal(Role.admin),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: Icons.engineering_outlined,
          title: l.rolePowerTitle,
          desc: l.rolePowerDesc,
          onTap: () => session.signInLocal(Role.power),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: Icons.person_outline,
          title: l.roleNormieTitle,
          desc: l.roleNormieDesc,
          onTap: () => session.signInLocal(Role.normie),
        ),
        const SizedBox(height: 16),
        Text(
          note,
          textAlign: TextAlign.center,
          style: p4.body(size: 12, color: p4.muted),
        ),
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
            child: Text(l.signInServer('${s.apiUri}'), overflow: TextOverflow.ellipsis, style: p4.mono(size: 11)),
          ),
          if (!kIsWeb)
            TextButton(onPressed: () => setState(() => _editServer = true), child: Text(l.signInChangeServer)),
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
    final l = context.l10n;
    final platform = BrandScope.of(context).platform;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _host,
          decoration: InputDecoration(labelText: l.fieldHost, helperText: l.hostHelp(platform)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _api,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l.apiBaseUrlOptional(platform),
            hintText: widget.settings.url(8000, '/').toString(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: widget.onDone, child: Text(l.cancel)),
            const SizedBox(width: 8),
            FilledButton(onPressed: _save, child: Text(l.save)),
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
    return Card(
      clipBehavior: Clip.antiAlias,
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
                    Text(desc, style: p4.body(size: 13, color: p4.muted)),
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
