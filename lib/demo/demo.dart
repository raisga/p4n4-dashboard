/// The in-browser demo: a static build (`--dart-define=P4N4_DEMO=true`) that
/// answers p4n4-api's endpoints itself, from a recorded store served next to
/// the app (`demo/store.json`), so a preview needs no stack behind it. See
/// [DemoClient] (demo_client.dart).
library;

/// Set by `--dart-define=P4N4_DEMO=true`.
const demoMode = bool.fromEnvironment('P4N4_DEMO');

/// The password of the demo's accounts (`--dart-define=P4N4_DEMO_PASSWORD=`).
/// It's checked in the browser: it keeps casual visitors out, nothing more.
const demoPassword = String.fromEnvironment('P4N4_DEMO_PASSWORD', defaultValue: 'demo');

/// The demo's accounts, one per view: username → p4n4-api role.
const demoAccounts = {'admin': 'admin', 'power': 'operator', 'normie': 'normie'};
