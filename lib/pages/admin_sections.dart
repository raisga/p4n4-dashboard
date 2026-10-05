import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/auth.dart' as auth;
import '../api/status_monitor.dart';
import '../api/users.dart';
import '../core/brand.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';

/// Settings → users: the connected deployment's p4n4-api accounts, and which
/// view each one gets. Admins only; the API checks that too.
class UsersSection extends StatefulWidget {
  const UsersSection({super.key});

  @override
  State<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<UsersSection> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  List<ApiUser>? _users;
  Object? _loadError;

  /// The last failed change, shown above the list until the next one.
  String? _actionError;
  bool _busy = false;
  Uri? _api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = SettingsScope.of(context).apiUri;
    if (api != _api) {
      _api = api;
      _load();
    }
  }

  Future<void> _load() async {
    final api = _api!;
    setState(() => _loadError = null);
    try {
      final users = await listUsers(api);
      if (mounted && api == _api) setState(() => _users = users);
    } catch (e) {
      if (mounted && api == _api) setState(() => _loadError = e);
    }
  }

  /// Runs a change, then reloads the list (or shows why it failed).
  Future<void> _run(Future<void> Function(Uri api) change) async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await change(_api!);
    } catch (e) {
      if (mounted) setState(() => _actionError = _describe(e));
    }
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  /// The API's own messages (validation, conflicts) come as it sends them.
  String _describe(Object e) => switch (e) {
    UsersException(statusCode: 401) => l.sessionExpired,
    UsersException(statusCode: 403) => l.usersOnlyAdmins,
    _ => '$e',
  };

  Future<void> _add() async {
    final form = await showDialog<_NewUser>(context: context, builder: (_) => const _NewUserDialog());
    if (form == null) return;
    await _run((api) => createUser(api, username: form.username, password: form.password, view: form.view));
  }

  Future<void> _resetPassword(ApiUser u) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _PasswordDialog(username: u.username),
    );
    if (password == null) return;
    await _run((api) => updateUser(api, u.username, password: password));
  }

  Future<void> _delete(ApiUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.removeUserTitle(u.username)),
        content: Text(l.removeUserBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.remove)),
        ],
      ),
    );
    if (ok == true) await _run((api) => deleteUser(api, u.username));
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).username;
    final users = _users;
    final muted = p4.body(size: 13, color: p4.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.usersNote(BrandScope.of(context).platform), style: muted),
        if (_actionError case final error?) ...[
          const SizedBox(height: 10),
          Text(error, style: p4.mono(color: p4.err, spacing: 0)),
        ],
        const SizedBox(height: 10),
        if (_loadError != null && users == null)
          Row(
            children: [
              Expanded(
                child: Text(l.usersLoadFailed(_describe(_loadError!)), style: p4.mono(color: p4.err, spacing: 0)),
              ),
              TextButton(onPressed: _load, child: Text(l.retry)),
            ],
          )
        else if (users == null)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent)),
          )
        else
          for (final u in users)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      u.username == me ? l.userYou(u.username) : u.username,
                      overflow: TextOverflow.ellipsis,
                      style: p4.display(size: 14, weight: FontWeight.w500, spacing: 0),
                    ),
                  ),
                  DropdownButton<Role>(
                    key: ValueKey('view-${u.username}'),
                    value: u.view,
                    underline: const SizedBox.shrink(),
                    style: p4.display(size: 14, color: p4.text, weight: FontWeight.w500, spacing: 0),
                    dropdownColor: p4.bg2,
                    items: [for (final r in Role.values) DropdownMenuItem(value: r, child: Text(l.roleName(r)))],
                    onChanged: _busy
                        ? null
                        : (r) => r == null || r == u.view ? null : _run((api) => updateUser(api, u.username, view: r)),
                  ),
                  IconButton(
                    tooltip: l.resetPasswordTooltip,
                    onPressed: _busy ? null : () => _resetPassword(u),
                    icon: Icon(Icons.key_outlined, size: 18, color: p4.muted),
                  ),
                  IconButton(
                    tooltip: l.removeUserTooltip,
                    onPressed: _busy || u.username == me ? null : () => _delete(u),
                    icon: Icon(Icons.delete_outline, size: 18, color: p4.muted),
                  ),
                ],
              ),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _busy || users == null ? null : _add,
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: Text(l.addUserButton),
          ),
        ),
      ],
    );
  }
}

typedef _NewUser = ({String username, String password, Role view});

class _NewUserDialog extends StatefulWidget {
  const _NewUserDialog();

  @override
  State<_NewUserDialog> createState() => _NewUserDialogState();
}

class _NewUserDialogState extends State<_NewUserDialog> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  var _view = Role.normie;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The API has the final say on names and password length; this only
    // keeps ADD off until both are filled in.
    final ready = _name.text.trim().isNotEmpty && _password.text.isNotEmpty;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.addUserTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l.fieldUsername),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: l.fieldPassword, helperText: l.passwordMinLength),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Role>(
              initialValue: _view,
              decoration: InputDecoration(labelText: l.fieldView),
              items: [for (final r in Role.values) DropdownMenuItem(value: r, child: Text(l.roleName(r)))],
              onChanged: (r) => setState(() => _view = r ?? _view),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: ready
              ? () => Navigator.pop<_NewUser>(context, (
                  username: _name.text.trim(),
                  password: _password.text,
                  view: _view,
                ))
              : null,
          child: Text(l.add),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.username});

  final String username;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.newPasswordTitle(widget.username)),
      content: TextField(
        controller: _password,
        autofocus: true,
        obscureText: true,
        decoration: InputDecoration(labelText: l.fieldPassword, helperText: l.newPasswordHelp),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: _password.text.isEmpty ? null : () => Navigator.pop(context, _password.text),
          child: Text(l.reset),
        ),
      ],
    );
  }
}

/// Settings → diagnostics: sign-in, token and service checks for the
/// connected deployment, and a settings dump (secrets hidden) to copy into a
/// bug report.
class DiagnosticsSection extends StatefulWidget {
  const DiagnosticsSection({super.key});

  @override
  State<DiagnosticsSection> createState() => _DiagnosticsSectionState();
}

class _DiagnosticsSectionState extends State<DiagnosticsSection> {
  P4Colors get p4 => context.p4;

  auth.AuthMode? _authMode;
  bool _probing = false;

  Future<void> _probe() async {
    setState(() => _probing = true);
    final mode = await auth.probeAuth(SettingsScope.of(context).apiUri);
    if (mounted) {
      setState(() {
        _authMode = mode;
        _probing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final session = SessionScope.of(context);
    final status = StatusScope.of(context).statusOf(s.statusTarget);
    final platform = BrandScope.of(context).platform;
    final l = context.l10n;
    // Values that are identifiers (modes, roles) stay as they are, to match logs and the dump.
    final rows = <(String, String)>[
      (l.diagDeployment, '${s.deployment.name} (${s.deployment.id})'),
      ('$platform-api', '${s.apiUri}'),
      (
        l.diagSignIn,
        '${session.mode?.name ?? '-'} · ${session.username ?? l.diagNoAccount} · ${session.signedInRole?.name}',
      ),
      (l.diagView, session.role?.name ?? '-'),
      (l.diagAuthMode, _probing ? l.diagChecking : _authMode?.name ?? l.diagNotChecked),
      (l.diagAccessToken, _tokenSummary(l, context.formats, session.accessTokenFor(s.apiUri))),
      (l.diagRefreshToken, s.apiRefreshTokenOf(s.deployment).isEmpty ? l.diagNone : l.diagStored),
      (l.diagSecureStorage, s.secureStorageAvailable ? l.diagAvailable : l.diagUnavailable),
      (l.diagServices, _statusSummary(l, context.formats, status)),
    ];
    final dump = const JsonEncoder.withIndent('  ').convert(_dump(s, session));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(k, style: p4.body(size: 13, color: p4.muted)),
                ),
                Expanded(
                  child: SelectableText(v, style: p4.mono(size: 12, color: p4.text, spacing: 0)),
                ),
              ],
            ),
          ),
        if (status.report case final r?)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final MapEntry(key: d, value: up) in r.up.entries)
                TagBadge(
                  '${d.label(platform)}:${d.port}',
                  color: switch (up) {
                    true => p4.ok,
                    false => p4.err,
                    null => p4.muted,
                  },
                ),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _probing ? null : _probe,
              icon: const Icon(Icons.lock_outline, size: 14),
              label: Text(l.checkSignIn),
            ),
            OutlinedButton.icon(
              onPressed: () => StatusScope.of(context).refresh(s.statusTarget),
              icon: const Icon(Icons.refresh, size: 14),
              label: Text(l.checkServices),
            ),
            OutlinedButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: dump)),
              icon: const Icon(Icons.copy, size: 14),
              label: Text(l.copySettings),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(l.settingsDump),
          subtitle: Text(l.secretsHidden),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: p4.bg3,
              child: SelectableText(dump, style: p4.mono(size: 11, color: p4.text, spacing: 0)),
            ),
          ],
        ),
      ],
    );
  }

  String _statusSummary(AppLocalizations l, Formats f, TargetStatus status) => switch (status.report) {
    null => status.checking ? l.diagChecking : l.diagNotChecked,
    final r =>
      '${r.viaApi ? l.diagServicesViaApi(r.online, r.known) : l.diagServicesViaProbes(r.online, r.known)}'
          '${status.checkedAt == null ? '' : ' · ${f.clock(status.checkedAt!, seconds: true)}'}',
  };
}

/// Whether there's an access token and when it expires (from its `exp`
/// claim; the signature isn't checked, this is only for display).
String _tokenSummary(AppLocalizations l, Formats f, String? token) {
  if (token == null) return l.tokenNone;
  try {
    final payload = token.split('.')[1];
    final claims = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload)))) as Map;
    final exp = DateTime.fromMillisecondsSinceEpoch((claims['exp'] as int) * 1000);
    final left = exp.difference(DateTime.now());
    return left.isNegative
        ? l.tokenExpired(f.clock(exp, seconds: true))
        : l.tokenValid(f.clock(exp, seconds: true), left.inMinutes);
  } catch (_) {
    return l.tokenUnreadable;
  }
}

/// The connected deployment's settings plus the app-wide ones that shape the
/// views, with credentials replaced.
Map<String, Object?> _dump(AppSettings s, Session session) => {
  'deployment': {
    for (final MapEntry(:key, :value) in s.deployment.values.entries)
      key: secretKeys.contains(key) && value is String && value.isNotEmpty ? '<hidden>' : value,
  },
  'deployments': s.deployments.length,
  'project': s.project?.name,
  'themeMode': s.themeMode.name,
  'locale': s.locale?.languageCode,
  'tabOrder': [for (final t in s.tabOrder) t.name],
  'powerTabs': [for (final t in s.tabsFor(Role.power)) t.name],
  'normieTabs': [for (final t in s.tabsFor(Role.normie)) t.name],
  'secureStorage': s.secureStorageAvailable,
  'preview': session.preview?.name,
};
