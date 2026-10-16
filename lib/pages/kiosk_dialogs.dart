import 'package:flutter/material.dart';

import '../api/auth.dart' as auth;
import '../core/brand.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Settings → This device → Kiosk mode: signs this device in with a viewer
/// account and locks it there. Returns whether it did.
Future<bool> showStartKioskDialog(BuildContext context) async {
  final l = context.l10n;
  final session = SessionScope.of(context);
  final settings = SettingsScope.of(context);
  final navigator = Navigator.of(context);
  final done = await showDialog<bool>(
    context: context,
    builder: (_) => _KioskSignInDialog(
      title: l.startKioskTitle,
      body: l.startKioskBody,
      action: l.kioskTurnOn,
      run: session.startKiosk,
    ),
  );
  if (done != true) return false;
  // Someone may walk off with an admin signed in here later: sign them out when idle.
  if (settings.idleSignOut == 0) settings.idleSignOut = 15;
  navigator.popUntil((r) => r.isFirst);
  return true;
}

/// The kiosk's lock button: an admin's sign-in turns kiosk mode off, and the
/// device stays signed in as that admin.
Future<void> showLeaveKioskDialog(BuildContext context) async {
  final l = context.l10n;
  final session = SessionScope.of(context);
  await showDialog<bool>(
    context: context,
    builder: (_) =>
        _KioskSignInDialog(title: l.leaveKiosk, body: l.leaveKioskBody, action: l.leaveKiosk, run: session.leaveKiosk),
  );
}

class _KioskSignInDialog extends StatefulWidget {
  const _KioskSignInDialog({required this.title, required this.body, required this.action, required this.run});

  final String title;
  final String body;
  final String action;
  final Future<void> Function(String username, String password) run;

  @override
  State<_KioskSignInDialog> createState() => _KioskSignInDialogState();
}

class _KioskSignInDialogState extends State<_KioskSignInDialog> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _ready => _user.text.trim().isNotEmpty && _password.text.isNotEmpty && !_busy;

  Future<void> _submit() async {
    if (!_ready) return;
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _attempt(context.l10n, BrandScope.of(context).platform);
    if (!mounted) return;
    if (error == null) return navigator.pop(true);
    _password.clear();
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  /// Runs the sign-in; null when it worked, else what to tell the person.
  // Returning the message, not setting a local in each catch: dart2js (Dart
  // 3.13) compiled that local wrong after a successful await, so the dialog
  // showed an error and stayed open on the web.
  Future<String?> _attempt(AppLocalizations l, String platform) async {
    try {
      await widget.run(_user.text, _password.text);
      return null;
    } on KioskAccountException catch (e) {
      return e.expected == Role.admin ? l.kioskNeedsAdmin : l.kioskNeedsViewer;
    } on auth.AuthException catch (e) {
      return switch (e.statusCode) {
        401 => l.signInWrongCredentials,
        429 => l.signInRateLimited,
        _ => e.message,
      };
    } catch (_) {
      return l.signInApiFailed(platform);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p4 = context.p4;
    void changed(String _) => setState(() {});
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.body, style: p4.body(size: 14, color: p4.muted)),
              const SizedBox(height: 16),
              TextField(
                controller: _user,
                enabled: !_busy,
                autofocus: true,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                onChanged: changed,
                decoration: InputDecoration(labelText: l.fieldUsername),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.go,
                onChanged: changed,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(labelText: l.fieldPassword),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: p4.body(size: 14, color: p4.err, weight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(onPressed: _ready ? _submit : null, child: Text(widget.action)),
      ],
    );
  }
}
