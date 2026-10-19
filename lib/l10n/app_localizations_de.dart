// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navHome => 'Start';

  @override
  String get navClients => 'Kunden';

  @override
  String get navServices => 'Dienste';

  @override
  String get navEdge => 'Gerät';

  @override
  String get navAgent => 'Assistent';

  @override
  String get navGrafana => 'Diagramme';

  @override
  String get navVideo => 'Kameras';

  @override
  String previewingView(String view) {
    return 'Sie sehen das Dashboard wie ein $view-Profil';
  }

  @override
  String get backToAdmin => 'Zurück zu Admin';

  @override
  String themeTooltip(String mode) {
    return 'Design: $mode';
  }

  @override
  String get themeSystem => 'Wie das Gerät';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get signOutTooltip => 'Abmelden';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePower => 'Erweitert';

  @override
  String get roleNormie => 'Leser';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get add => 'Hinzufügen';

  @override
  String get remove => 'Entfernen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get delete => 'Löschen';

  @override
  String get clear => 'Neue Unterhaltung';

  @override
  String get open => 'Öffnen';

  @override
  String get connect => 'Verbinden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get refreshStatus => 'Status aktualisieren';

  @override
  String get healthOnline => 'Online';

  @override
  String get healthOffline => 'Offline';

  @override
  String get healthChecking => 'Wird geprüft…';

  @override
  String get healthUnknown => 'Unbekannt';

  @override
  String get fieldUsername => 'Benutzername';

  @override
  String get fieldPassword => 'Passwort';

  @override
  String get fieldHost => 'Host';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldView => 'Profil';

  @override
  String hostHelp(String platform) {
    return 'Der Rechner, auf dem die $platform-Stacks laufen. Im Android-Emulator 10.0.2.2 verwenden.';
  }

  @override
  String apiBaseUrl(String platform) {
    return 'Basis-URL von $platform-api';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return 'Basis-URL von $platform-api (optional)';
  }

  @override
  String get sessionExpired => 'Ihre Sitzung ist abgelaufen. Bitte melden Sie sich erneut an.';

  @override
  String get signInTag => 'Anmelden';

  @override
  String get signInConnecting => 'Verbinden…';

  @override
  String get signInWelcome => 'Willkommen';

  @override
  String get signInButton => 'Anmelden';

  @override
  String get signInWrongCredentials => 'Falscher Benutzername oder falsches Passwort.';

  @override
  String get signInRateLimited => 'Zu viele Versuche. Warten Sie eine Minute und versuchen Sie es erneut.';

  @override
  String signInApiFailed(String platform) {
    return '$platform-api ist nicht erreichbar. Prüfen Sie den Server und versuchen Sie es erneut.';
  }

  @override
  String get signInChooseTitle => 'Wählen Sie, wie es weitergeht';

  @override
  String signInAuthOffNote(String platform) {
    return '$platform-api läuft ohne Anmeldung (P4N4_API_AUTH=off), daher kann jeder ein Profil wählen.';
  }

  @override
  String get signInOfflineTitle => 'Ohne Anmeldung fortfahren';

  @override
  String signInOfflineNote(String platform) {
    return 'Ohne $platform-api wird der Dienststatus durch Prüfen der Ports ermittelt, und Sie wählen das Profil selbst.';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return '$platform-api ist nicht erreichbar';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return 'Für die Anmeldung wird $platform-api unter $url benötigt. Prüfen Sie, ob es läuft und von diesem Gerät erreichbar ist, oder ändern Sie unten den Server.';
  }

  @override
  String get signInOfflineButton => 'Ohne Anmeldung fortfahren';

  @override
  String get signInDevAccounts => 'Entwicklerkonten';

  @override
  String signInDevAccountsNote(String platform) {
    return 'Erfordert $platform-api mit P4N4_API_DEV_USERS=true';
  }

  @override
  String signInServer(String url) {
    return 'Server: $url';
  }

  @override
  String get signInChangeServer => 'Ändern';

  @override
  String get roleAdminTitle => 'Administrator';

  @override
  String get roleAdminDesc => 'Alles, dazu Kundenbereitstellungen, Stack-Steuerung, Benutzer und Diagnose.';

  @override
  String get rolePowerTitle => 'Erweiterter Benutzer';

  @override
  String get rolePowerDesc => 'Alle Dienste und Einstellungen, ohne Bereitstellungen oder Benutzer zu verwalten.';

  @override
  String get roleNormieTitle => 'Leser';

  @override
  String get roleNormieDesc => 'Systemstatus, Diagramme, Kameras und Assistent. Ansehen, ohne Einstellungen zu ändern.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get sectionAppearance => 'Darstellung';

  @override
  String get sectionLanguage => 'Sprache';

  @override
  String get sectionConnection => 'Verbindung';

  @override
  String get sectionEdgeMetrics => 'Gerätewerte';

  @override
  String get sectionGrafana => 'Diagramme';

  @override
  String get sectionVideo => 'Kameras';

  @override
  String get sectionViews => 'Profile';

  @override
  String get sectionUsers => 'Benutzer';

  @override
  String get sectionDiagnostics => 'Diagnose';

  @override
  String get sectionAccount => 'Konto';

  @override
  String get sectionAbout => 'Über';

  @override
  String get languageSystem => 'Wie das Gerät';

  @override
  String get fieldDeployment => 'Bereitstellung';

  @override
  String get resetConnection => 'Standardverbindung wiederherstellen';

  @override
  String get metricsUrl => 'Messwert-URL';

  @override
  String get demoData => 'Demodaten';

  @override
  String get grafanaBaseUrl => 'Grafana-Basis-URL';

  @override
  String get dashboardPath => 'Dashboard-Pfad';

  @override
  String get kioskMode => 'Kioskmodus';

  @override
  String viewsSaveFailed(String error) {
    return 'Profile konnten nicht gespeichert werden: $error';
  }

  @override
  String get tabOrder => 'Reihenfolge der Tabs';

  @override
  String get resetTabOrder => 'Reihenfolge zurücksetzen';

  @override
  String get dragToReorder => 'Zum Sortieren ziehen';

  @override
  String previewView(String view) {
    return 'Als $view ansehen';
  }

  @override
  String signedInAs(String user) {
    return 'Angemeldet als $user';
  }

  @override
  String get signedInWithoutAccount => 'Ohne Konto angemeldet';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · $platform-api-Konto';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · bei der Anmeldung gewählt';
  }

  @override
  String get licenses => 'Lizenzen';

  @override
  String usersNote(String platform) {
    return '$platform-api-Konten in dieser Bereitstellung. Eine Profiländerung gilt ab der nächsten Aktualisierung des Benutzers; ein zurückgesetztes Passwort meldet ihn ab.';
  }

  @override
  String usersLoadFailed(String error) {
    return 'Benutzer können nicht geladen werden: $error';
  }

  @override
  String get usersOnlyAdmins => 'Nur Administratoren können Benutzer verwalten.';

  @override
  String userYou(String user) {
    return '$user (Sie)';
  }

  @override
  String get resetPasswordTooltip => 'Passwort zurücksetzen';

  @override
  String get removeUserTooltip => 'Benutzer entfernen';

  @override
  String get addUserButton => 'Benutzer hinzufügen';

  @override
  String get addUserTitle => 'Benutzer hinzufügen';

  @override
  String get passwordMinLength => 'Mindestens 10 Zeichen';

  @override
  String removeUserTitle(String user) {
    return '$user entfernen?';
  }

  @override
  String get removeUserBody => 'Die Person wird überall abgemeldet und kann sich nicht wieder anmelden.';

  @override
  String newPasswordTitle(String user) {
    return 'Neues Passwort für $user';
  }

  @override
  String get newPasswordHelp => 'Meldet die Person überall ab';

  @override
  String get diagDeployment => 'Bereitstellung';

  @override
  String get diagSignIn => 'Anmeldung';

  @override
  String get diagView => 'Profil';

  @override
  String get diagAuthMode => 'Authentifizierungsmodus';

  @override
  String get diagAccessToken => 'Zugriffstoken';

  @override
  String get diagRefreshToken => 'Aktualisierungstoken';

  @override
  String get diagSecureStorage => 'Sicherer Speicher';

  @override
  String get diagServices => 'Dienste';

  @override
  String get diagChecking => 'wird geprüft…';

  @override
  String get diagNotChecked => 'nicht geprüft';

  @override
  String get diagNoAccount => 'kein Konto';

  @override
  String get diagNone => 'keins';

  @override
  String get diagStored => 'gespeichert';

  @override
  String get diagAvailable => 'verfügbar';

  @override
  String get diagUnavailable => 'nicht verfügbar (nur im Arbeitsspeicher)';

  @override
  String diagServicesViaApi(int online, int known) {
    return '$online von $known aktiv laut API';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return '$online von $known aktiv laut Ports';
  }

  @override
  String get tokenNone => 'keins (wird bei der nächsten Anfrage geholt)';

  @override
  String tokenExpired(String time) {
    return 'abgelaufen um $time';
  }

  @override
  String tokenValid(String time, int minutes) {
    return 'gültig bis $time ($minutes min)';
  }

  @override
  String get tokenUnreadable => 'vorhanden (nicht lesbar)';

  @override
  String get checkSignIn => 'Anmeldung prüfen';

  @override
  String get checkServices => 'Dienste prüfen';

  @override
  String get copySettings => 'Einstellungen kopieren';

  @override
  String get settingsDump => 'Einstellungsexport';

  @override
  String get secretsHidden => 'Geheimnisse ausgeblendet';

  @override
  String get summaryChecking => 'Ihr System wird geprüft…';

  @override
  String get summaryCheckingSub => 'Das dauert ein paar Sekunden.';

  @override
  String get summaryUnavailable => 'Dienststatus nicht verfügbar';

  @override
  String get summaryUnavailableSub =>
      'Ihr System antwortet, hat aber keinen Dienststatus gemeldet. Wenden Sie sich an Ihren Administrator, falls das anhält.';

  @override
  String get summaryUnreachable => 'Ihr System ist nicht erreichbar';

  @override
  String get summaryUnreachableSub => 'Prüfen Sie, ob das Gerät eingeschaltet und verbunden ist.';

  @override
  String get summaryOk => 'Alles läuft';

  @override
  String get summaryOkSub => 'Ihr System funktioniert normal.';

  @override
  String get summaryAttention => 'Etwas braucht Aufmerksamkeit';

  @override
  String get summaryAttentionSub =>
      'Ein Teil Ihres Systems funktioniert gerade nicht. Wenn er sich nicht in ein paar Minuten erholt, wenden Sie sich an Ihren Administrator.';

  @override
  String summaryAffected(String features) {
    return 'Betroffen: $features';
  }

  @override
  String summaryUpdated(String time) {
    return 'Geprüft um $time';
  }

  @override
  String get featureAssistant => 'Assistent';

  @override
  String get featureCharts => 'Diagramme';

  @override
  String get featureHistory => 'Datenverlauf';

  @override
  String get featureSensors => 'Sensordaten';

  @override
  String get featureAutomations => 'Automatisierungen';

  @override
  String get featureDeviceAi => 'KI auf dem Gerät';

  @override
  String get featureConnection => 'Verbindung zum System';

  @override
  String get yourDevice => 'Ihr Gerät';

  @override
  String get deviceUnavailable => 'Gerätewerte sind gerade nicht verfügbar.';

  @override
  String get deviceLoading => 'Werte werden geladen…';

  @override
  String get readingProcessor => 'Prozessor';

  @override
  String get readingMemory => 'Arbeitsspeicher';

  @override
  String get readingTemperature => 'Temperatur';

  @override
  String get levelNormal => 'Normal';

  @override
  String get levelHigh => 'Hoch';

  @override
  String get levelCritical => 'Sehr hoch';

  @override
  String get levelWarm => 'Warm';

  @override
  String get levelHot => 'Heiß';

  @override
  String get deviceDetails => 'Details';

  @override
  String servicesApiUnreachable(String platform) {
    return '$platform-api antwortet nicht, daher wird der Status durch Prüfen des Ports jedes Dienstes ermittelt.';
  }

  @override
  String servicesApiNoStatus(String platform, String reason) {
    return '$platform-api liefert keinen Dienststatus ($reason), daher wird der Status durch Prüfen des Ports jedes Dienstes ermittelt.';
  }

  @override
  String get servicesTitle => 'Dienste';

  @override
  String servicesSubtitle(String host) {
    return 'Die Anwendungen, die auf $host laufen. Öffnen Sie eine, um sie direkt zu verwenden.';
  }

  @override
  String get servicesSubtitlePlain =>
      'Die Anwendungen, die auf Ihrem System laufen. Öffnen Sie eine, um sie zu verwenden.';

  @override
  String servicesLiveFrom(String authority) {
    return 'Live-Status von $authority';
  }

  @override
  String servicesContacting(String authority) {
    return 'Verbindung zu $authority…';
  }

  @override
  String serviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Dienste', one: '1 Dienst');
    return '$_temp0';
  }

  @override
  String endpointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Endpunkte', one: '1 Endpunkt');
    return '$_temp0';
  }

  @override
  String get stackControls => 'Stack-Aktionen';

  @override
  String get stackStart => 'Starten';

  @override
  String get stackRestart => 'Neu starten';

  @override
  String get stackStop => 'Stoppen';

  @override
  String stackConfirmStop(String stack) {
    return '$stack stoppen?';
  }

  @override
  String get stackConfirmStopBody => 'Seine Dienste funktionieren für niemanden mehr, bis ihn jemand wieder startet.';

  @override
  String stackConfirmRestart(String stack) {
    return '$stack neu starten?';
  }

  @override
  String get stackConfirmRestartBody => 'Seine Dienste sind kurz unterbrochen, während er neu startet.';

  @override
  String stackJobRunning(String stack) {
    return '$stack wird bearbeitet…';
  }

  @override
  String stackJobDone(String stack) {
    return '$stack ist fertig.';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return 'Aktion für $stack fehlgeschlagen: $error';
  }

  @override
  String couldNotOpen(String url) {
    return '$url konnte nicht geöffnet werden';
  }

  @override
  String get tcpOnly => 'Keine Webseite';

  @override
  String get stackIot => 'IoT-Stack';

  @override
  String get stackAi => 'KI-Stack';

  @override
  String get stackApi => 'API-Gateway';

  @override
  String get serviceGrafanaDesc => 'Dashboards und Diagramme';

  @override
  String get serviceNodeRedDesc => 'Ablaufautomatisierung';

  @override
  String get serviceInfluxDesc => 'Verlauf der Sensordaten';

  @override
  String get serviceMqttDesc => 'Nachrichtenbroker für Geräte';

  @override
  String get serviceOllamaDesc => 'Lokale KI-Modelle';

  @override
  String get serviceLettaDesc => 'KI-Agenten mit Gedächtnis';

  @override
  String get serviceN8nDesc => 'Workflow-Automatisierung';

  @override
  String get serviceEiRunnerDesc => 'KI auf dem Gerät (Edge Impulse)';

  @override
  String get serviceApiDesc => 'Ein Einstiegspunkt für alle Stacks';

  @override
  String get serviceSwaggerDesc => 'Interaktive API-Dokumentation';

  @override
  String get clientsIntro =>
      'Der Status jeder Bereitstellung kommt von ihrer API oder, wenn diese nicht antwortet, aus der Prüfung der Dienst-Ports. Verbinden schaltet dieses Dashboard und alle Verbindungseinstellungen auf diese Bereitstellung um.';

  @override
  String get clientsTitle => 'Kundenbereitstellungen';

  @override
  String get noDeployments => 'Keine Bereitstellungen';

  @override
  String get noDeploymentsMsg =>
      'Fügen Sie eine Kundenbereitstellung mit Name und Host hinzu, um sie hier zu überwachen.';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known aktiv';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known aktiv (über Ports)';
  }

  @override
  String get currentBadge => 'Verbunden';

  @override
  String get editTooltip => 'Bearbeiten';

  @override
  String get removeTooltip => 'Entfernen';

  @override
  String get removeCurrentTooltip => 'Verbinden Sie sich mit einer anderen Bereitstellung, um diese zu entfernen';

  @override
  String get addDeployment => 'Bereitstellung hinzufügen';

  @override
  String get editDeployment => 'Bereitstellung bearbeiten';

  @override
  String get clientName => 'Kundenname';

  @override
  String get apiUrlOptional => 'API-URL (optional)';

  @override
  String get apiUrlHelp => 'Nur wenn die API nicht auf Port 8000 des Hosts läuft';

  @override
  String get edgeDemoSwitch => 'Demodaten';

  @override
  String get edgeNoMetrics => 'Keine Gerätewerte';

  @override
  String edgeFetchFailed(String url, String error) {
    return '$url konnte nicht gelesen werden: $error\n\nRichten Sie die Messwert-URL in den Einstellungen auf einen Endpunkt, der das im README beschriebene JSON liefert.';
  }

  @override
  String get edgeUnavailable => 'Gerätewerte sind gerade nicht verfügbar. Versuchen Sie es gleich noch einmal.';

  @override
  String get edgeSubtitle => 'Live-Werte Ihres Geräts, alle 2 Sekunden.';

  @override
  String get useDemoData => 'Demodaten verwenden';

  @override
  String get edgeStale => 'Veraltet';

  @override
  String get edgeDemoLabel => 'Demodaten';

  @override
  String get edgeSynthetic => 'Erfundene Werte zum Testen';

  @override
  String get edgeLive => 'Live';

  @override
  String get metricInference => 'KI-Antwortzeit';

  @override
  String get factDisk => 'Belegter Speicher';

  @override
  String get factLoad => 'Durchschnittslast';

  @override
  String get factUptime => 'Läuft seit';

  @override
  String sparkStart(int minutes) {
    return 'vor $minutes Min.';
  }

  @override
  String get sparkNow => 'Jetzt';

  @override
  String get agentModel => 'Modell';

  @override
  String get agentAgent => 'Agent';

  @override
  String get assistantUnavailable => 'Assistent nicht verfügbar';

  @override
  String get assistantUnavailableMsg => 'Der Assistent antwortet gerade nicht. Versuchen Sie es später noch einmal.';

  @override
  String get assistantNotSetUp => 'Kein Assistent eingerichtet';

  @override
  String get assistantNotSetUpMsg => 'Bitten Sie Ihren Administrator, einen einzurichten.';

  @override
  String get assistantChat => 'Fragen Sie Ihren Assistenten';

  @override
  String get assistantChatMsg =>
      'Er kennt den aktuellen Zustand Ihres Systems, Sie können also nach Ihren Geräten, Daten und Diensten fragen.';

  @override
  String get assistantSuggestStatus => 'Läuft alles normal?';

  @override
  String get assistantSuggestDevice => 'Wie stark ist mein Gerät gerade ausgelastet?';

  @override
  String get assistantSuggestHelp => 'Wobei können Sie mir helfen?';

  @override
  String get assistantSharedModel => 'Alle in dieser Bereitstellung sprechen mit diesem Modell.';

  @override
  String get assistantSharedAgent => 'Alle in dieser Bereitstellung sprechen mit diesem Agenten.';

  @override
  String assistantSaveFailed(String error) {
    return 'Assistent konnte nicht gewechselt werden: $error';
  }

  @override
  String get assistantErrorUnavailable => 'Der Assistent antwortet gerade nicht. Versuchen Sie es gleich noch einmal.';

  @override
  String get assistantErrorChanged =>
      'Der Assistent hat sich geändert. Beginnen Sie eine neue Unterhaltung, um fortzufahren.';

  @override
  String get assistantErrorGeneric => 'Das hat nicht geklappt. Bitte erneut versuchen.';

  @override
  String get assistantInputUnavailable => 'Der Assistent ist gerade nicht verfügbar';

  @override
  String get sendTooltip => 'Senden';

  @override
  String get stopTooltip => 'Stoppen';

  @override
  String agentUnreachable(String backend) {
    return '$backend antwortet nicht';
  }

  @override
  String get agentNoModels => 'Keine Modelle installiert';

  @override
  String get agentNoModelsMsg =>
      'Laden Sie zuerst eines auf das Gerät, z. B. `docker exec p4n4-ollama ollama pull llama3.2`.';

  @override
  String get agentNoAgents => 'Noch keine Agenten';

  @override
  String get agentNoAgentsMsg => 'Erstellen Sie einen Agenten im Letta-ADE und versuchen Sie es erneut.';

  @override
  String agentOllamaMsg(String platform) {
    return 'Nachrichten gehen über $platform-api an Ollama, zusammen mit dem aktuellen Zustand Ihres Systems. Der Verlauf bleibt nur in dieser Sitzung erhalten.';
  }

  @override
  String get agentLettaMsg => 'Letta-Agenten behalten ihr eigenes Gedächtnis über Sitzungen hinweg.';

  @override
  String get agentMessageHint => 'Stellen Sie eine Frage… (Umschalt+Eingabe für neue Zeile)';

  @override
  String get agentSelectFirst => 'Wählen Sie zuerst ein Modell oder einen Agenten';

  @override
  String get agentStopped => '(gestoppt)';

  @override
  String get agentThinking => 'Denkt nach…';

  @override
  String agentStepLookup(String what) {
    return 'Prüft $what';
  }

  @override
  String get agentStepData => 'Prüft die Daten';

  @override
  String get agentWriting => 'Schreibt die Antwort…';

  @override
  String agentElapsed(int seconds) {
    return '$seconds s';
  }

  @override
  String agentWaitLast(int seconds) {
    return 'Die letzte Antwort dauerte $seconds s.';
  }

  @override
  String get agentWaitHint => 'Antworten können bis zu einer Minute dauern.';

  @override
  String get bubbleYou => 'Sie';

  @override
  String get bubbleAgent => 'Assistent';

  @override
  String get bubbleError => 'Etwas ist schiefgelaufen';

  @override
  String get grafanaDashboards => 'Diagramme';

  @override
  String get reloadTooltip => 'Neu laden';

  @override
  String get backTooltip => 'Zurück';

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String embedUnavailable(String platform) {
    return 'Die eingebettete Ansicht ist auf $platform nicht verfügbar';
  }

  @override
  String get embedUnavailableMsg =>
      'Flutters WebView unterstützt Android, iOS und macOS. Auf dieser Plattform öffnet sich Grafana in Ihrem Standardbrowser.';

  @override
  String get openGrafana => 'Grafana öffnen';

  @override
  String get grafanaUnreachable => 'Grafana antwortet nicht';

  @override
  String get dashboardsUnavailable => 'Diagramme nicht verfügbar';

  @override
  String get dashboardsUnavailableMsg =>
      'Die Diagramme können gerade nicht geladen werden. Versuchen Sie es später noch einmal.';

  @override
  String get viewerClose => 'Zurück zu den Diensten';

  @override
  String viewerLoading(String service) {
    return '$service wird geladen…';
  }

  @override
  String viewerBlankHint(String service) {
    return 'Leer? $service lässt sich womöglich nicht in der App anzeigen.';
  }

  @override
  String get viewerDismissHint => 'Ausblenden';

  @override
  String openService(String service) {
    return '$service öffnen';
  }

  @override
  String viewerDownTitle(String service) {
    return '$service ist ausgefallen';
  }

  @override
  String get viewerDownMsg =>
      'Sein Container läuft nicht. Starten Sie ihn auf dem Tab „Dienste“ (neu) und versuchen Sie es dann erneut.';

  @override
  String get viewerDownMsgPlain => 'Er läuft gerade nicht. Versuchen Sie es später noch einmal.';

  @override
  String viewerUnsupportedMsg(String service) {
    return 'Flutters WebView unterstützt Android, iOS und macOS. Auf dieser Plattform öffnet sich $service in Ihrem Standardbrowser.';
  }

  @override
  String viewerBlockedTitle(String service) {
    return '$service kann hier nicht angezeigt werden';
  }

  @override
  String viewerBlockedMsg(String service) {
    return '$service lässt sich nicht in einer anderen Website anzeigen. Stellen Sie es über den Proxy des Dashboards bereit (gleicher Ursprung) oder öffnen Sie es im Browser.';
  }

  @override
  String viewerInsecureMsg(String service) {
    return 'Das Dashboard läuft über HTTPS, $service nur über HTTP, daher zeigt der Browser es hier nicht an. Stellen Sie es über den Proxy des Dashboards bereit oder öffnen Sie es im Browser.';
  }

  @override
  String viewerBlockedMsgPlain(String service) {
    return '$service kann nicht in der App angezeigt werden. Öffnen Sie es stattdessen im Browser.';
  }

  @override
  String viewerUnreachable(String service) {
    return '$service nicht erreichbar';
  }

  @override
  String viewerUnavailable(String service) {
    return '$service ist nicht verfügbar';
  }

  @override
  String get viewerUnavailableMsg => 'Kann gerade nicht geladen werden. Versuchen Sie es später noch einmal.';

  @override
  String viewerSlowTitle(String service) {
    return '$service braucht eine Weile';
  }

  @override
  String viewerSlowMsg(String service) {
    return 'Bleibt es leer, lässt sich $service womöglich nicht in der App anzeigen. Sie können es im Browser öffnen.';
  }

  @override
  String get viewerSlowDetails =>
      'Seiten mit X-Frame-Options oder einer frame-ancestors-Richtlinie bleiben in einem Frame leer. Stellen Sie den Dienst über den Proxy des Dashboards bereit (/svc/<id>/), um ihn einzubetten.';

  @override
  String get viewerKeepWaiting => 'Weiter warten';

  @override
  String couldNotOpenService(String service) {
    return '$service konnte nicht geöffnet werden';
  }

  @override
  String serviceUrlField(String service) {
    return '$service-URL';
  }

  @override
  String cameraDefaultName(int n) {
    return 'Kamera $n';
  }

  @override
  String get resumeTooltip => 'Fortsetzen';

  @override
  String get pauseTooltip => 'Pause';

  @override
  String get reconnectTooltip => 'Neu verbinden';

  @override
  String get singleCamera => 'Eine Kamera';

  @override
  String get allCameras => 'Alle Kameras';

  @override
  String get editCamera => 'Kamera bearbeiten';

  @override
  String get addCamera => 'Kamera hinzufügen';

  @override
  String get addCameraButton => 'Kamera hinzufügen';

  @override
  String get noCameras => 'Keine Kameras';

  @override
  String get noCamerasTechnical =>
      'Fügen Sie die URL eines MJPEG-Streams, eines JPEG-Schnappschusses oder einer Videodatei Ihrer Edge-Kamera hinzu, oder eine der Kameras dieses Geräts.';

  @override
  String get noCamerasNormie =>
      'Es ist noch keine Kamera eingerichtet. Bitten Sie Ihren Administrator, eine hinzuzufügen.';

  @override
  String get noCamerasConfigured => 'Keine Kameras eingerichtet';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Kameras', one: '1 Kamera');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '„$name“ hat eine ungültige URL';
  }

  @override
  String get cameraUrl => 'Stream-, Schnappschuss- oder Video-URL oder Gerätekamera';

  @override
  String get cameraUrlError => 'Geben Sie eine http://- oder https://-URL, device:back oder device:front ein';

  @override
  String get cameraExamples => 'z. B.';

  @override
  String get cameraReconnecting => 'Neu verbinden…';

  @override
  String get cameraStreamEnded => 'Stream beendet';

  @override
  String get cameraUnavailable => 'Kamera nicht verfügbar';

  @override
  String get cameraLive => 'Live';

  @override
  String get cameraVideo => 'Video';

  @override
  String get backCamera => 'Rückkamera';

  @override
  String get frontCamera => 'Frontkamera';

  @override
  String get deviceCameraMissing => 'Dieses Gerät hat diese Kamera nicht';

  @override
  String get deviceCameraOneAtATime => 'Dieses Gerät zeigt jeweils nur eine seiner Kameras';

  @override
  String get deviceCameraShow => 'Diese zeigen';

  @override
  String deviceCameraUnsupported(String platform) {
    return 'Gerätekameras funktionieren in der App auf $platform nicht';
  }

  @override
  String get videoDemoSwitch => 'Demokameras';

  @override
  String get videoGridDefault => 'Mit allen Kameras öffnen';

  @override
  String get alertSound => 'Alarmton';

  @override
  String get alertDismiss => 'Alarm schließen';

  @override
  String get visionPerson => 'Person';

  @override
  String visionPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
      zero: 'Niemand im Bild',
    );
    return '$_temp0';
  }

  @override
  String get sectionChats => 'Chats';

  @override
  String get chatsNote =>
      'Mit dem Bot des Projekts verknüpfte Chats erhalten seine Warnungen, sobald sie auftreten, und können ihn zum Projekt befragen. In einer verknüpften Gruppe kann das jeder.';

  @override
  String get chatsLink => 'Chat verknüpfen';

  @override
  String chatsLinkHow(String bot) {
    return 'Öffne den Link auf dem Telefon, das den Bot nutzen wird, oder sende diesen Befehl an $bot. Für eine Gruppe füge den Bot zuerst der Gruppe hinzu und sende den Befehl dort.';
  }

  @override
  String get chatsTheBot => 'den Bot';

  @override
  String chatsCodeExpires(String time) {
    return 'Gilt einmal, bis $time.';
  }

  @override
  String get chatsCopyLink => 'Link kopieren';

  @override
  String get chatsCopyCommand => 'Befehl kopieren';

  @override
  String get chatsNone => 'Noch keine Chats verknüpft.';

  @override
  String chatsLinkedBy(String date, String who) {
    return 'Verknüpft am $date von $who';
  }

  @override
  String chatsLinkedOn(String date) {
    return 'Verknüpft am $date';
  }

  @override
  String chatsMuted(String codes) {
    return 'Stumm: $codes';
  }

  @override
  String get chatsUnlink => 'Trennen';

  @override
  String chatsUnlinkTitle(String name) {
    return '$name trennen?';
  }

  @override
  String get chatsUnlinkBody =>
      'Er erhält keine Warnungen mehr, und der Bot antwortet ihm nicht mehr. Der Chat wird benachrichtigt.';

  @override
  String chatsLoadFailed(String error) {
    return 'Chats konnten nicht geladen werden: $error';
  }

  @override
  String get chatsMock => 'Testmodus: Der Bot protokolliert seine Nachrichten, statt sie zu senden.';

  @override
  String get chatsOff => 'Aus: Der Bot hat kein Token.';

  @override
  String get useDemoCameras => 'Demokameras verwenden';

  @override
  String get videoDemoCredits =>
      'Demomaterial: Clips von MDN (CC0); Big Buck Bunny und Sintel © Blender Foundation (CC BY 3.0).';

  @override
  String videoUnsupported(String platform) {
    return 'Videodateien werden in der App auf $platform nicht abgespielt';
  }

  @override
  String get settingsSearch => 'Einstellungen durchsuchen';

  @override
  String settingsNoMatch(String query) {
    return 'Keine Treffer für „$query“';
  }

  @override
  String get groupPersonal => 'Persönlich';

  @override
  String get groupDeployment => 'Bereitstellung';

  @override
  String get groupAdmin => 'Verwaltung';

  @override
  String get sectionAccessibility => 'Bedienungshilfen';

  @override
  String get sectionLanguageRegion => 'Sprache und Region';

  @override
  String get sectionEndpoints => 'Endpunkte';

  @override
  String get themeHeading => 'Design';

  @override
  String get textSize => 'Textgröße';

  @override
  String textSizeValue(String size) {
    return 'Text $size';
  }

  @override
  String get textSizePreview => 'So sieht Text im gesamten Dashboard aus.';

  @override
  String get textSizeSmaller => 'Kleinerer Text';

  @override
  String get textSizeLarger => 'Größerer Text';

  @override
  String get resetToDefault => 'Zurücksetzen';

  @override
  String get highContrast => 'Hoher Kontrast';

  @override
  String get reduceMotion => 'Bewegung reduzieren';

  @override
  String get onInDeviceSettings => 'In den Einstellungen Ihres Geräts aktiviert.';

  @override
  String languageDevice(String language) {
    return 'Wie das Gerät ($language)';
  }

  @override
  String get searchLanguages => 'Sprachen suchen';

  @override
  String get formatsHeading => 'Formate';

  @override
  String get temperatureUnit => 'Temperatur';

  @override
  String get unitAuto => 'Auto';

  @override
  String get timeFormat => 'Uhrzeit';

  @override
  String get time12h => '12 Stunden';

  @override
  String get time24h => '24 Stunden';

  @override
  String tourWelcome(String appName) {
    return 'Willkommen bei $appName! Hier das Wichtigste.';
  }

  @override
  String get tourNavigation =>
      'Hier sind Ihre Bildschirme. Start zeigt, wie alles läuft; tippen Sie auf einen anderen, um ihn zu öffnen.';

  @override
  String get tourTheme => 'Wechseln Sie zwischen hellem und dunklem Design oder folgen Sie Ihrem Gerät.';

  @override
  String get tourSettings =>
      'Sprache, Textgröße und mehr finden Sie in den Einstellungen. Dort können Sie diese Tour auch wiederholen.';

  @override
  String get tourSignOut => 'Melden Sie sich hier ab, wenn Sie fertig sind.';

  @override
  String tourProgress(Object current, Object total) {
    return '$current von $total';
  }

  @override
  String get tourNext => 'Weiter';

  @override
  String get tourBack => 'Zurück';

  @override
  String get tourDone => 'Verstanden';

  @override
  String get tourSkip => 'Tour überspringen';

  @override
  String get takeTour => 'Tour starten';

  @override
  String get takeTourSubtitle => 'Ein kurzer Rundgang durch das Dashboard';

  @override
  String get navFeed => 'Aktivität';

  @override
  String get feedEmpty => 'Noch nichts';

  @override
  String get feedEmptyMsg => 'Ereignisse und Warnungen erscheinen hier, sobald sie eintreten.';

  @override
  String get feedNotSetUp => 'Keine Aktivität';

  @override
  String get feedNotSetUpMsg => 'Diese Installation veröffentlicht keine Aktivität.';

  @override
  String get feedNotSetUpTechnical =>
      'Das Projekt hat keinen Feed: Fügen Sie dashboard.feed zu seiner .p4n4.json hinzu.';

  @override
  String get feedUnavailable => 'Aktivität kann nicht gelesen werden';

  @override
  String get feedUnavailableMsg => 'Prüfen Sie, ob die Dienste des Geschäfts laufen, und versuchen Sie es erneut.';

  @override
  String feedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count zu prüfen', one: '1 zu prüfen');
    return '$_temp0';
  }

  @override
  String get feedFilterAll => 'Alle';

  @override
  String get feedFilterAlerts => 'Warnungen';

  @override
  String get feedFilterPending => 'Zu prüfen';

  @override
  String get feedOlder => 'Ältere';

  @override
  String feedActionFailed(String error) {
    return 'Fehlgeschlagen: $error';
  }

  @override
  String get feedDemoData => 'Demodaten';

  @override
  String get feedStatusPending => 'Zu prüfen';

  @override
  String get feedStatusAttended => 'Erledigt';

  @override
  String get feedStatusConfirmed => 'Bestätigt';

  @override
  String get feedStatusDismissed => 'Verworfen';

  @override
  String feedPosition(int index, int count) {
    return '$index von $count';
  }

  @override
  String get feedPrevious => 'Zurück';

  @override
  String get feedNext => 'Weiter';

  @override
  String get feedKeys => 'Tasten: 1, 2… die Aktionen · J / K nächstes / voriges · Esc zurück';

  @override
  String get feedPicture => 'Das Bild zur Meldung';

  @override
  String get feedPictureFailed => 'Das Bild ließ sich nicht laden.';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get changePasswordSubtitle => 'Meldet dich auf deinen anderen Geräten ab';

  @override
  String get changePasswordTitle => 'Neues Passwort wählen';

  @override
  String get changePasswordBody => 'Ein Admin bittet dich, vor dem Fortfahren dein eigenes Passwort zu wählen.';

  @override
  String get fieldCurrentPassword => 'Aktuelles Passwort';

  @override
  String get fieldNewPassword => 'Neues Passwort';

  @override
  String get fieldRepeatPassword => 'Neues Passwort wiederholen';

  @override
  String get passwordsDontMatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get passwordCurrentWrong => 'Das aktuelle Passwort ist falsch';

  @override
  String get passwordChanged => 'Passwort geändert';

  @override
  String get signOutUserTooltip => 'Überall abmelden';

  @override
  String signOutUserTitle(String user) {
    return '$user überall abmelden?';
  }

  @override
  String get signOutUserBody => 'Die Person muss sich auf jedem Gerät neu anmelden. Das Passwort bleibt gleich.';

  @override
  String get signOutSelfBody =>
      'Du musst dich hier und auf deinen anderen Geräten neu anmelden. Dein Passwort bleibt gleich.';

  @override
  String userLastSignIn(String when) {
    return 'Zuletzt angemeldet: $when';
  }

  @override
  String get userNeverSignedIn => 'Nie angemeldet';

  @override
  String get userMustChangePassword => 'Muss ein neues Passwort wählen';

  @override
  String get mustChangeAtFirstSignIn => 'Bei der ersten Anmeldung ein eigenes Passwort wählen';

  @override
  String get mustChangeAtNextSignIn => 'Bei der nächsten Anmeldung ein neues Passwort wählen';

  @override
  String get sectionAudit => 'Audit-Log';

  @override
  String get auditNote => 'Wer was in dieser Bereitstellung geändert hat, neueste zuerst';

  @override
  String auditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Änderungen', one: '1 Änderung');
    return '$_temp0, neueste zuerst';
  }

  @override
  String get auditEmpty => 'Noch keine Änderungen';

  @override
  String auditLoadFailed(String error) {
    return 'Audit-Log konnte nicht geladen werden: $error';
  }

  @override
  String get auditLoadMore => 'Mehr laden';

  @override
  String get sectionBanner => 'Hinweisbanner';

  @override
  String get bannerNone => 'Kein Banner';

  @override
  String get bannerShowing => 'Auf allen Geräten sichtbar, bis du es entfernst';

  @override
  String bannerShowingUntil(String when) {
    return 'Auf allen Geräten sichtbar bis $when';
  }

  @override
  String get bannerText => 'Nachricht';

  @override
  String get bannerHint => 'Wartung heute 15–16 Uhr';

  @override
  String get bannerInfo => 'Info';

  @override
  String get bannerWarning => 'Warnung';

  @override
  String get bannerUntilCleared => 'Bis zum Entfernen';

  @override
  String bannerForHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: 'Für $hours Stunden', one: 'Für 1 Stunde');
    return '$_temp0';
  }

  @override
  String get bannerClear => 'Entfernen';

  @override
  String get bannerShow => 'Anzeigen';

  @override
  String get viewStartTab => 'Öffnet mit';

  @override
  String get viewHomeCards => 'Start zeigt';

  @override
  String get homeCardStatus => 'Status';

  @override
  String get homeCardDevice => 'Gerätewerte';

  @override
  String get homeCardPage => 'Projektseite';

  @override
  String get viewGrafanaPage => 'Grafana-Seite';

  @override
  String get viewGrafanaPageHelp => 'Leer: die Seite der Bereitstellung';

  @override
  String get viewCameras => 'Kameras';

  @override
  String get viewCameraOverlay => 'Vision-Overlay';

  @override
  String get viewAlerts => 'Eingeblendete Warnungen';

  @override
  String get alertsAll => 'Alle';

  @override
  String get alertsReview => 'Nur zu prüfende';

  @override
  String get alertsOff => 'Keine';

  @override
  String get viewAlertSound => 'Ton bei zu prüfenden Warnungen';

  @override
  String get sectionDevice => 'Dieses Gerät';

  @override
  String get deviceKiosk => 'Kioskmodus';

  @override
  String get kioskModeHelp =>
      'Bindet dieses Gerät an ein Betrachter-Konto: kein Abmelden, keine Einstellungen, und es beginnt neu, wenn niemand es nutzt';

  @override
  String get kioskNeedsAccounts => 'Erfordert die Anmeldung mit p4n4-api-Konten';

  @override
  String get kioskIdleReset => 'Bei Inaktivität neu beginnen';

  @override
  String get idleSignOut => 'Admins und Power-User bei Inaktivität abmelden';

  @override
  String get idleNever => 'Nie';

  @override
  String idleAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nach $count Minuten',
      one: 'Nach 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String get startKioskTitle => 'Kioskmodus einschalten';

  @override
  String get startKioskBody =>
      'Melde dieses Gerät mit einem Betrachter-Konto an. Hier kann sich niemand abmelden oder Einstellungen ändern, und es beginnt neu, wenn niemand es nutzt.';

  @override
  String get kioskTurnOn => 'Einschalten';

  @override
  String get leaveKiosk => 'Kioskmodus verlassen';

  @override
  String get leaveKioskBody =>
      'Melde dich mit einem Admin-Konto an. Das Gerät bleibt dann mit diesem Admin angemeldet.';

  @override
  String get kioskNeedsViewer => 'Das ist kein Betrachter-Konto.';

  @override
  String get kioskNeedsAdmin => 'Das ist kein Admin-Konto.';

  @override
  String get startTabDefault => 'Standard';

  @override
  String get chartHistory => 'Diagrammverlauf';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Minuten', one: '1 Minute');
    return '$_temp0';
  }

  @override
  String get defaultCamera => 'Standardkamera';

  @override
  String get defaultCameraFirst => 'Die erste';

  @override
  String logsTitle(String name) {
    return 'Protokolle von $name';
  }

  @override
  String logsFailed(String error) {
    return 'Gestoppt: $error';
  }

  @override
  String get logsEnded => 'Der Protokollstrom ist beendet';

  @override
  String get logsFollowing => 'Neue Zeilen werden verfolgt';

  @override
  String get copyTooltip => 'Kopieren';

  @override
  String get copied => 'Kopiert';

  @override
  String get logsFilter => 'Filtern';

  @override
  String get logsEmpty => 'Noch keine Protokollzeilen';

  @override
  String get logsNoMatch => 'Keine Zeile passt zum Filter';

  @override
  String get logsLatest => 'Zur neuesten Zeile';

  @override
  String get logsMenu => 'Protokolle';

  @override
  String get serviceConfirmRestartBody => 'Er hält für alle, die ihn nutzen, kurz an.';

  @override
  String serviceUptime(String time) {
    return 'läuft seit $time';
  }

  @override
  String get serviceUnhealthy => 'Fehlerhaft';

  @override
  String get serviceStarting => 'Startet';

  @override
  String serviceActions(String name) {
    return 'Aktionen für $name';
  }

  @override
  String get sectionDevices => 'Geräte';

  @override
  String devicesNote(String platform) {
    return 'Geräte, die Messwerte an $platform-api senden, jedes mit eigenem Schlüssel.';
  }

  @override
  String get devicesOnlyAdmins => 'Nur Administratoren können Geräte ändern.';

  @override
  String devicesLoadFailed(String error) {
    return 'Geräte konnten nicht geladen werden: $error';
  }

  @override
  String get devicesNone => 'Noch keine Geräte registriert.';

  @override
  String get deviceDisabled => 'Deaktiviert';

  @override
  String deviceLastSeen(String time) {
    return 'Zuletzt gesehen $time';
  }

  @override
  String get deviceNeverSeen => 'Nie gesehen';

  @override
  String deviceKey(String prefix) {
    return 'Schlüssel $prefix…';
  }

  @override
  String get deviceDisable => 'Deaktivieren: Es kann sich nicht mehr anmelden';

  @override
  String get deviceEnable => 'Aktivieren';

  @override
  String get rotateKey => 'Neuer Schlüssel';

  @override
  String rotateKeyTitle(String name) {
    return 'Neuer Schlüssel für $name?';
  }

  @override
  String get rotateKeyBody =>
      'Der aktuelle Schlüssel funktioniert sofort nicht mehr. Hinterlegen Sie den neuen auf dem Gerät.';

  @override
  String removeDeviceTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get removeDeviceBody =>
      'Sein Schlüssel funktioniert sofort nicht mehr, und es kann keine Messwerte mehr senden.';

  @override
  String get removeDeviceTooltip => 'Gerät entfernen';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get addDevice => 'Gerät hinzufügen';

  @override
  String get editDevice => 'Gerät bearbeiten';

  @override
  String get deviceId => 'Geräte-ID';

  @override
  String get deviceIdHelp => 'Buchstaben, Ziffern, Punkte, Binde- und Unterstriche; später nicht änderbar';

  @override
  String get deviceName => 'Name';

  @override
  String get deviceDescription => 'Beschreibung';

  @override
  String deviceKeyTitle(String id) {
    return 'Schlüssel für $id';
  }

  @override
  String get deviceKeyBody => 'Kopieren Sie ihn jetzt auf das Gerät: Er wird nicht wieder angezeigt.';

  @override
  String get done => 'Fertig';

  @override
  String get contactSupport => 'Support kontaktieren';

  @override
  String summaryDownFor(String time) {
    return 'Ausgefallen seit $time';
  }

  @override
  String deviceUpdatedAt(String time) {
    return 'Aktualisiert um $time';
  }

  @override
  String deviceStaleSince(String time) {
    return 'Aktualisierung fehlgeschlagen · Werte von $time';
  }

  @override
  String get sectionThresholds => 'Schwellenwerte';

  @override
  String get thresholdServiceDown => 'Dienst ausgefallen';

  @override
  String get sensorsTitle => 'Sensoren';

  @override
  String get sensorsSubtitle => 'Live-Messwerte der Geräte. Tippen Sie auf einen für seinen Verlauf.';

  @override
  String sensorsUnavailable(String error) {
    return 'Keine Live-Messwerte: $error';
  }

  @override
  String get sensorsNoBroker => 'Noch nicht mit dem MQTT-Broker verbunden';

  @override
  String get sensorsWaiting => 'Warten auf Messwerte…';

  @override
  String sensorReadAt(String time) {
    return 'Gemessen um $time';
  }

  @override
  String get rangeHour => 'Stunde';

  @override
  String get rangeDay => 'Tag';

  @override
  String get rangeWeek => 'Woche';

  @override
  String sensorHistoryFailed(String error) {
    return 'Verlauf konnte nicht geladen werden: $error';
  }

  @override
  String get sensorHistoryEmpty => 'Für diesen Zeitraum sind keine Messwerte gespeichert';

  @override
  String sensorMin(String value) {
    return 'Minimum $value';
  }

  @override
  String sensorMax(String value) {
    return 'Maximum $value';
  }

  @override
  String get modelTitle => 'Modell';

  @override
  String get modelSubtitle => 'Der Inferenz-Runner auf dem Edge-Gerät';

  @override
  String get modelNoRunner => 'Kein Inferenz-Runner in dieser Bereitstellung, oder er antwortet nicht.';

  @override
  String modelFailed(String error) {
    return 'Runner nicht erreichbar: $error';
  }

  @override
  String get modelInferences => 'Inferenzen';

  @override
  String get modelLastLatency => 'Letzte Latenz';

  @override
  String get modelLastAt => 'Letzte';

  @override
  String get modelRecent => 'Letzte Ergebnisse';

  @override
  String get classifyTitle => 'Ausprobieren';

  @override
  String get classifyValues => 'Eingabewerte';

  @override
  String classifyExpects(int expected, int count) {
    return '$count von $expected Werten';
  }

  @override
  String get classify => 'Klassifizieren';

  @override
  String classifyAnomaly(String score) {
    return 'Anomalie $score';
  }

  @override
  String get classifyNotNumbers => 'Geben Sie Zahlen ein, getrennt durch Kommas oder Leerzeichen.';

  @override
  String get commandTitle => 'Befehl senden';

  @override
  String get commandSubtitle => 'Veröffentlicht eine MQTT-Nachricht, z. B. an das Befehls-Topic eines Geräts';

  @override
  String get commandTopic => 'Topic';

  @override
  String get commandPayload => 'Nachricht';

  @override
  String get commandPayloadHelp => 'Text oder JSON';

  @override
  String get commandRetain => 'Behalten (retain)';

  @override
  String commandSent(String topic, int bytes) {
    return 'An $topic gesendet ($bytes Bytes)';
  }

  @override
  String commandTopicNotAllowed(String topic) {
    return 'Diese Bereitstellung erlaubt keine Veröffentlichung an $topic (P4N4_API_MQTT_PUBLISH_ALLOW und _DENY in p4n4-api).';
  }

  @override
  String commandNoBroker(String error) {
    return 'p4n4-api ist nicht mit dem Broker verbunden: $error';
  }

  @override
  String get commandNotAllowed => 'Nur Operatoren und Administratoren können Befehle senden.';

  @override
  String commandFailed(String error) {
    return 'Nicht gesendet: $error';
  }

  @override
  String thresholdsNote(String deployment) {
    return 'Ab wann die Messwerte von $deployment auf diesem Gerät als hoch oder kritisch gelten.';
  }

  @override
  String thresholdLevels(String high, String critical) {
    return 'Hoch ab $high · kritisch ab $critical';
  }

  @override
  String get thresholdServiceDownHelp => 'Ein Dienst, der nicht mehr antwortet, ist zuerst eine Warnung, dann kritisch';

  @override
  String get thresholdsReset => 'Auf Standardwerte zurücksetzen';

  @override
  String get fleetNoReadings => 'Keine Gerätemesswerte';

  @override
  String get incidentUnreachable => 'Alles';

  @override
  String incidentOngoing(String service, String start, String length) {
    return '$service ausgefallen seit $start ($length)';
  }

  @override
  String incidentEnded(String service, String start, String end) {
    return '$service ausgefallen $start–$end';
  }

  @override
  String get incidentHistory => 'Ausfallverlauf';

  @override
  String incidentHistoryOf(String name) {
    return '$name: Ausfälle';
  }

  @override
  String get incidentNone => 'Von diesem Gerät aus wurden keine Ausfälle gesehen.';

  @override
  String get incidentNote => 'Von diesem Gerät aus gesehen, während es den Status dieser Bereitstellung anzeigte.';

  @override
  String serviceDownFor(String time) {
    return 'Offline · $time';
  }

  @override
  String get answerStyle => 'Antwortstil';

  @override
  String get styleStandard => 'Standard';

  @override
  String get styleBrief => 'Kurz';

  @override
  String get styleSteps => 'Schritt für Schritt';

  @override
  String get styleSimple => 'Einfache Worte';

  @override
  String get styleCustom => 'Eigene Anweisungen';

  @override
  String get styleCustomLabel => 'Wie soll der Assistent antworten?';

  @override
  String get styleCustomHelp => 'Wird mit jeder Frage von diesem Gerät gesendet';

  @override
  String get videoGridLight => 'Leichtes Raster für langsame Verbindungen';

  @override
  String get videoGridLightHelp => 'Im Raster alle 2 Sekunden ein neues Bild statt Live-Bewegung';

  @override
  String cameraFrameEvery(int seconds) {
    return 'alle $seconds s';
  }

  @override
  String get clearList => 'Leeren';
}
