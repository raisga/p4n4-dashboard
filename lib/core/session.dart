import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which view of the dashboard the user gets.
enum Role { admin, client }

/// The signed-in role, persisted between launches.
///
/// p4n4-api has no auth yet, so the role is picked on the sign-in screen. Once
/// `/api/v1/auth/token` exists, [signIn] should take credentials and read the
/// role from the JWT instead.
class Session extends ChangeNotifier {
  Session._(this._prefs);

  final SharedPreferences _prefs;

  static Future<Session> load() async => Session._(await SharedPreferences.getInstance());

  Role? get role => Role.values.asNameMap()[_prefs.getString('role')];
  bool get isAdmin => role == Role.admin;

  Future<void> signIn(Role role) async {
    await _prefs.setString('role', role.name);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _prefs.remove('role');
    notifyListeners();
  }
}

/// Exposes [Session] to the widget tree and rebuilds dependents on change.
class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child}) : super(notifier: session);

  static Session of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
