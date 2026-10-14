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
  String get stackEdge => 'Edge-Stack';

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
  String get sparkStart => 'vor 2 Min.';

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
  String get feedStatusDismissed => 'Verworfen';
}
