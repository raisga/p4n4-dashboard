import 'dart:async';

import 'package:flutter/material.dart';

import '../api/auth.dart' as auth;
import '../core/brand.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';

/// Shown instead of the dashboard while an admin wants this account to
/// choose a new password (`password_change_required`): the API turns down
/// everything else until then.
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final session = SessionScope.of(context);
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
                  const SizedBox(height: 40),
                  SectionHeader(tag: session.username ?? l.signInTag, title: Text(l.changePasswordTitle)),
                  const SizedBox(height: 12),
                  Text(l.changePasswordBody, style: p4.body(color: p4.muted)),
                  const SizedBox(height: 16),
                  const PasswordChangeForm(),
                  const SizedBox(height: 8),
                  TextButton(onPressed: session.signOut, child: Text(l.signOut)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings → Account → Change password.
Future<void> showChangePasswordDialog(BuildContext context) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final done = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.changePassword),
      content: SizedBox(
        width: 360,
        child: PasswordChangeForm(
          onCancel: () => Navigator.pop(context, false),
          onDone: () => Navigator.pop(context, true),
        ),
      ),
    ),
  );
  if (done == true) messenger.showSnackBar(SnackBar(content: Text(l.passwordChanged)));
}

/// Current password, a new one twice, and the button that changes it.
class PasswordChangeForm extends StatefulWidget {
  const PasswordChangeForm({super.key, this.onDone, this.onCancel});

  final VoidCallback? onDone;

  /// Shows a Cancel button beside the change one.
  final VoidCallback? onCancel;

  @override
  State<PasswordChangeForm> createState() => _PasswordChangeFormState();
}

class _PasswordChangeFormState extends State<PasswordChangeForm> {
  /// The API's rule; it has the final say, this only explains it early.
  static const _minLength = 10;

  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  bool get _ready =>
      _current.text.isNotEmpty && _next.text.length >= _minLength && _repeat.text == _next.text && !_busy;

  Future<void> _submit() async {
    if (!_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _attempt(context.l10n, SessionScope.of(context), BrandScope.of(context).platform);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) widget.onDone?.call();
  }

  /// Changes the password; null when it worked, else what to tell the person.
  // Returning the message, not setting a local in each catch: dart2js (Dart
  // 3.13) compiled that pattern wrong after a successful await (see
  // kiosk_dialogs.dart).
  Future<String?> _attempt(AppLocalizations l, Session session, String platform) async {
    try {
      await session.changePassword(_current.text, _next.text);
      return null;
    } on auth.AuthException catch (e) {
      return switch (e.statusCode) {
        403 => l.passwordCurrentWrong,
        429 => l.signInRateLimited,
        401 => l.sessionExpired,
        _ => e.message, // the API's reason for refusing the new one
      };
    } catch (_) {
      return l.signInApiFailed(platform);
    }
  }

  Widget _button(P4Colors p4, AppLocalizations l) => FilledButton(
    onPressed: _ready ? _submit : null,
    child: _busy
        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.onAccent))
        : Text(l.changePassword),
  );

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final mismatch = _repeat.text.isNotEmpty && _repeat.text != _next.text;
    void changed(String _) => setState(() {});
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _current,
            enabled: !_busy,
            autofocus: true,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.next,
            onChanged: changed,
            decoration: InputDecoration(labelText: l.fieldCurrentPassword),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _next,
            enabled: !_busy,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            onChanged: changed,
            decoration: InputDecoration(labelText: l.fieldNewPassword, helperText: l.passwordMinLength),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _repeat,
            enabled: !_busy,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.go,
            onChanged: changed,
            onSubmitted: (_) => unawaited(_submit()),
            decoration: InputDecoration(
              labelText: l.fieldRepeatPassword,
              errorText: mismatch ? l.passwordsDontMatch : null,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: p4.body(size: 14, color: p4.err, weight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 20),
          if (widget.onCancel case final cancel?)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _busy ? null : cancel, child: Text(l.cancel)),
                const SizedBox(width: 8),
                _button(p4, l),
              ],
            )
          else
            _button(p4, l),
        ],
      ),
    );
  }
}
