import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/settings.dart';
import '../demo/demo.dart';
import '../demo/demo_charts.dart';
import '../l10n/l10n.dart';
import '../widgets/service_viewer.dart';

/// [uri] in the app's light or dark mode and, given one, its [language]:
/// Grafana's `theme` and `lang` parameters override the signed-in user's own
/// for that page load, so Grafana's menus and pickers speak the app's
/// language. [grafanaKeepQuery] keeps them across Grafana's sign-in.
Uri themedGrafanaUri(Uri uri, Brightness brightness, {String? language}) => uri.replace(
  queryParameters: {
    ...uri.queryParameters,
    'theme': brightness.name,
    if (language != null) 'lang': grafanaLanguage(language),
  },
);

/// Grafana's name for a dashboard language (a code such as `es`, or a locale
/// name such as `pt_BR`): its regional tags, which it requires.
String grafanaLanguage(String language) {
  final code = language.split(RegExp('[_-]')).first.toLowerCase();
  return switch (code) {
    'en' => 'en-US',
    'es' => 'es-ES',
    'fr' => 'fr-FR',
    'de' => 'de-DE',
    'it' => 'it-IT',
    'nl' => 'nl-NL',
    'pt' => 'pt-BR',
    'ja' => 'ja-JP',
    'ko' => 'ko-KR',
    'zh' => 'zh-Hans',
    _ => 'en-US',
  };
}

/// [ServiceViewer.keepQuery] for Grafana: its sign-in lands on its home
/// without `theme` and `lang`, in the user's own.
const grafanaKeepQuery = {'theme', 'lang'};

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
      SettingsScope.of(context).grafanaUriFor(session.role ?? Role.normie, language: l.localeName),
      Theme.of(context).brightness,
      language: l.localeName,
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
