import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/settings.dart';
import '../demo/demo.dart';
import '../demo/demo_charts.dart';
import '../l10n/l10n.dart';
import '../widgets/service_viewer.dart';

/// [uri] in the app's light or dark mode: Grafana's `theme` parameter
/// overrides the signed-in user's own theme for that page load.
/// [grafanaKeepQuery] keeps it across Grafana's sign-in.
Uri themedGrafanaUri(Uri uri, Brightness brightness) =>
    uri.replace(queryParameters: {...uri.queryParameters, 'theme': brightness.name});

/// [ServiceViewer.keepQuery] for Grafana: its sign-in lands on its home
/// without `theme`, in the user's own theme.
const grafanaKeepQuery = {'theme'};

/// Embedded Grafana (kiosk mode by default), in the app's light or dark mode:
/// the [ServiceViewer], at the view's own page if an admin set one (Settings
/// → Views). Switching the app's theme changes the URL, so Grafana reloads in it.
class GrafanaTab extends StatelessWidget {
  const GrafanaTab({super.key});

  @override
  Widget build(BuildContext context) {
    // The demo build has no Grafana: it draws the project's charts itself.
    if (demoMode) return const DemoChartsTab();
    final session = SessionScope.of(context);
    final technical = session.isTechnical;
    final l = context.l10n;
    final uri = themedGrafanaUri(
      SettingsScope.of(context).grafanaUriFor(session.role ?? Role.normie),
      Theme.of(context).brightness,
    );
    // Grafana must allow framing (GF_SECURITY_ALLOW_EMBEDDING=true), or be
    // served through the dashboard's proxy (/grafana/); Open in browser still works.
    return ServiceViewer(
      uri: uri,
      title: l.grafanaDashboards,
      icon: Icons.show_chart,
      technical: technical,
      keepQuery: grafanaKeepQuery,
      texts: ViewerTexts(
        unsupportedMessage: l.embedUnavailableMsg,
        openLabel: l.openGrafana,
        failedTitle: technical ? l.grafanaUnreachable : l.dashboardsUnavailable,
        failedMessage: l.dashboardsUnavailableMsg,
      ),
    );
  }
}
