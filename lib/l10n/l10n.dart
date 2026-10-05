import 'package:flutter/widgets.dart';

import '../api/services.dart';
import '../core/brand.dart';
import '../core/role.dart';
import '../widgets/common.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// A language for the picker: its name in itself, so anyone can find theirs,
/// and in English, so anyone can help them.
typedef LanguageName = ({String native, String english});

/// Names of the languages a translation is likely to arrive in. Add a
/// language by adding `app_<code>.arb` next to `app_en.arb`; the picker lists
/// it on its own (and only needs a line here if it isn't one of these).
const knownLanguages = <String, LanguageName>{
  'ar': (native: 'العربية', english: 'Arabic'),
  'ca': (native: 'Català', english: 'Catalan'),
  'cs': (native: 'Čeština', english: 'Czech'),
  'da': (native: 'Dansk', english: 'Danish'),
  'de': (native: 'Deutsch', english: 'German'),
  'el': (native: 'Ελληνικά', english: 'Greek'),
  'en': (native: 'English', english: 'English'),
  'es': (native: 'Español', english: 'Spanish'),
  'eu': (native: 'Euskara', english: 'Basque'),
  'fi': (native: 'Suomi', english: 'Finnish'),
  'fr': (native: 'Français', english: 'French'),
  'gl': (native: 'Galego', english: 'Galician'),
  'he': (native: 'עברית', english: 'Hebrew'),
  'hi': (native: 'हिन्दी', english: 'Hindi'),
  'hu': (native: 'Magyar', english: 'Hungarian'),
  'id': (native: 'Bahasa Indonesia', english: 'Indonesian'),
  'it': (native: 'Italiano', english: 'Italian'),
  'ja': (native: '日本語', english: 'Japanese'),
  'ko': (native: '한국어', english: 'Korean'),
  'nb': (native: 'Norsk bokmål', english: 'Norwegian'),
  'nl': (native: 'Nederlands', english: 'Dutch'),
  'pl': (native: 'Polski', english: 'Polish'),
  'pt': (native: 'Português', english: 'Portuguese'),
  'ro': (native: 'Română', english: 'Romanian'),
  'ru': (native: 'Русский', english: 'Russian'),
  'sv': (native: 'Svenska', english: 'Swedish'),
  'th': (native: 'ไทย', english: 'Thai'),
  'tr': (native: 'Türkçe', english: 'Turkish'),
  'uk': (native: 'Українська', english: 'Ukrainian'),
  'vi': (native: 'Tiếng Việt', english: 'Vietnamese'),
  'zh': (native: '中文', english: 'Chinese'),
};

/// [code]'s names; the code itself for a language missing from [knownLanguages].
LanguageName languageName(String code) =>
    knownLanguages[code] ?? (native: code.toUpperCase(), english: code.toUpperCase());

/// Every language the dashboard is translated into (one per ARB file), by code,
/// in alphabetical order of their own names.
final List<String> supportedLanguages = [for (final l in AppLocalizations.supportedLocales) l.languageCode]
  ..sort((a, b) => languageName(a).native.toLowerCase().compareTo(languageName(b).native.toLowerCase()));

extension L10nContext on BuildContext {
  /// The dashboard's strings in the current language.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Labels for the dashboard's enums and service catalog.
extension L10nLabels on AppLocalizations {
  String roleName(Role role) => switch (role) {
    Role.admin => roleAdmin,
    Role.power => rolePower,
    Role.normie => roleNormie,
  };

  String tabName(DashTab tab) => switch (tab) {
    DashTab.services => navServices,
    DashTab.edge => navEdge,
    DashTab.agent => navAgent,
    DashTab.grafana => navGrafana,
    DashTab.video => navVideo,
  };

  /// [level] in words: "High" for usage, "Warm" for a [temperature].
  String levelName(Level level, {bool temperature = false}) => switch (level) {
    Level.normal => levelNormal,
    Level.high => temperature ? levelWarm : levelHigh,
    Level.critical => temperature ? levelHot : levelCritical,
  };

  String healthName(Health health) => switch (health) {
    Health.up => healthOnline,
    Health.down => healthOffline,
    Health.pending => healthChecking,
    Health.unknown => healthUnknown,
  };

  String stackLabel(StackDef stack) => switch (stack.suffix) {
    'iot' => stackIot,
    'ai' => stackAi,
    'edge' => stackEdge,
    'api' => stackApi,
    _ => stack.label,
  };

  String serviceDesc(ServiceDef service) => switch (service.name) {
    'Grafana' => serviceGrafanaDesc,
    'Node-RED' => serviceNodeRedDesc,
    'InfluxDB' => serviceInfluxDesc,
    'MQTT' => serviceMqttDesc,
    'Ollama' => serviceOllamaDesc,
    'Letta' => serviceLettaDesc,
    'n8n' => serviceN8nDesc,
    'EI Runner' => serviceEiRunnerDesc,
    'p4n4-api' => serviceApiDesc,
    'Swagger UI' => serviceSwaggerDesc,
    _ => service.desc,
  };
}
