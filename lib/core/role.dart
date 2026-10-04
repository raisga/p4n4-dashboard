/// Which view of the dashboard the user gets, most technical first.
enum Role {
  /// Every tab, client deployments, stack controls, users and diagnostics.
  admin,

  /// The admin layout without fleet, user or stack management.
  power,

  /// Home and the tabs an admin picks, in plain language.
  normie;

  /// Hosts, URLs, raw errors and endpoint settings: everyone but normies.
  bool get technical => this != normie;

  /// Reads a stored role name. `client`, the view before there were three,
  /// is now normie.
  static Role? named(Object? name) => name == 'client' ? normie : values.asNameMap()[name];
}

/// p4n4-api roles → dashboard views: admin → admin, operator → power,
/// normie (or anything unknown) → normie.
Role roleForApi(String apiRole) => switch (apiRole) {
  'admin' => Role.admin,
  'operator' => Role.power,
  _ => Role.normie,
};

/// Dashboard views → the p4n4-api role that gets them.
String apiRoleFor(Role role) => switch (role) {
  Role.admin => 'admin',
  Role.power => 'operator',
  Role.normie => 'normie',
};

/// Set by `make run` (`--dart-define=P4N4_DEV_USERS=true`): the sign-in form
/// offers p4n4-api's dev accounts (`P4N4_API_DEV_USERS=true`), one per view.
const devUsers = bool.fromEnvironment('P4N4_DEV_USERS');

/// p4n4-api's dev accounts and the view each gets. Their password is public:
/// development only.
const devAccounts = [('admin', Role.admin), ('power', Role.power), ('normie', Role.normie)];
const devPassword = 'p4n4';
