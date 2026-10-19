// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get navHome => 'Start';

  @override
  String get navClients => 'Klanten';

  @override
  String get navServices => 'Diensten';

  @override
  String get navEdge => 'Apparaat';

  @override
  String get navAgent => 'Assistent';

  @override
  String get navGrafana => 'Grafieken';

  @override
  String get navVideo => 'Camera\'s';

  @override
  String previewingView(String view) {
    return 'Je ziet het dashboard zoals een $view-profiel het ziet';
  }

  @override
  String get backToAdmin => 'Terug naar admin';

  @override
  String themeTooltip(String mode) {
    return 'Thema: $mode';
  }

  @override
  String get themeSystem => 'Zoals het apparaat';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get settingsTooltip => 'Instellingen';

  @override
  String get signOutTooltip => 'Afmelden';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePower => 'Gevorderd';

  @override
  String get roleNormie => 'Lezer';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get cancel => 'Annuleren';

  @override
  String get save => 'Opslaan';

  @override
  String get add => 'Toevoegen';

  @override
  String get remove => 'Verwijderen';

  @override
  String get reset => 'Herstellen';

  @override
  String get delete => 'Wissen';

  @override
  String get clear => 'Nieuw gesprek';

  @override
  String get open => 'Openen';

  @override
  String get connect => 'Verbinden';

  @override
  String get signOut => 'Afmelden';

  @override
  String get refreshStatus => 'Status vernieuwen';

  @override
  String get healthOnline => 'Online';

  @override
  String get healthOffline => 'Offline';

  @override
  String get healthChecking => 'Controleren…';

  @override
  String get healthUnknown => 'Onbekend';

  @override
  String get fieldUsername => 'Gebruikersnaam';

  @override
  String get fieldPassword => 'Wachtwoord';

  @override
  String get fieldHost => 'Host';

  @override
  String get fieldName => 'Naam';

  @override
  String get fieldView => 'Profiel';

  @override
  String hostHelp(String platform) {
    return 'De machine waarop de $platform-stacks draaien. Gebruik 10.0.2.2 vanuit de Android-emulator.';
  }

  @override
  String apiBaseUrl(String platform) {
    return 'Basis-URL van $platform-api';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return 'Basis-URL van $platform-api (optioneel)';
  }

  @override
  String get sessionExpired => 'Je sessie is verlopen. Meld je opnieuw aan.';

  @override
  String get signInTag => 'Aanmelden';

  @override
  String get signInConnecting => 'Verbinden…';

  @override
  String get signInWelcome => 'Welkom';

  @override
  String get signInButton => 'Aanmelden';

  @override
  String get signInWrongCredentials => 'Onjuiste gebruikersnaam of onjuist wachtwoord.';

  @override
  String get signInRateLimited => 'Te veel pogingen. Wacht een minuut en probeer het opnieuw.';

  @override
  String signInApiFailed(String platform) {
    return 'Kan $platform-api niet bereiken. Controleer de server en probeer het opnieuw.';
  }

  @override
  String get signInChooseTitle => 'Kies hoe je verdergaat';

  @override
  String signInAuthOffNote(String platform) {
    return '$platform-api draait zonder aanmelding (P4N4_API_AUTH=off), dus iedereen kan een profiel kiezen.';
  }

  @override
  String get signInOfflineTitle => 'Doorgaan zonder aan te melden';

  @override
  String signInOfflineNote(String platform) {
    return 'Zonder $platform-api wordt de status van de diensten bepaald door poorten te testen, en kies je zelf het profiel.';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return 'Kan $platform-api niet bereiken';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return 'Voor aanmelden is $platform-api op $url nodig. Controleer of het draait en bereikbaar is vanaf dit apparaat, of wijzig hieronder de server.';
  }

  @override
  String get signInOfflineButton => 'Doorgaan zonder aan te melden';

  @override
  String get signInDevAccounts => 'Ontwikkelaccounts';

  @override
  String signInDevAccountsNote(String platform) {
    return 'Vereist $platform-api met P4N4_API_DEV_USERS=true';
  }

  @override
  String signInServer(String url) {
    return 'Server: $url';
  }

  @override
  String get signInChangeServer => 'Wijzigen';

  @override
  String get roleAdminTitle => 'Beheerder';

  @override
  String get roleAdminDesc => 'Alles, plus klantimplementaties, stackbeheer, gebruikers en diagnose.';

  @override
  String get rolePowerTitle => 'Gevorderde gebruiker';

  @override
  String get rolePowerDesc => 'Alle diensten en instellingen, zonder implementaties of gebruikers te beheren.';

  @override
  String get roleNormieTitle => 'Lezer';

  @override
  String get roleNormieDesc =>
      'Systeemstatus, grafieken, camera\'s en assistent. Bekijken zonder instellingen te wijzigen.';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get sectionAppearance => 'Weergave';

  @override
  String get sectionLanguage => 'Taal';

  @override
  String get sectionConnection => 'Verbinding';

  @override
  String get sectionEdgeMetrics => 'Apparaatmetingen';

  @override
  String get sectionGrafana => 'Grafieken';

  @override
  String get sectionVideo => 'Camera\'s';

  @override
  String get sectionViews => 'Profielen';

  @override
  String get sectionUsers => 'Gebruikers';

  @override
  String get sectionDiagnostics => 'Diagnose';

  @override
  String get sectionAccount => 'Account';

  @override
  String get sectionAbout => 'Over';

  @override
  String get languageSystem => 'Zoals het apparaat';

  @override
  String get fieldDeployment => 'Implementatie';

  @override
  String get resetConnection => 'Standaardverbinding herstellen';

  @override
  String get metricsUrl => 'Metingen-URL';

  @override
  String get demoData => 'Demogegevens';

  @override
  String get grafanaBaseUrl => 'Grafana-basis-URL';

  @override
  String get dashboardPath => 'Dashboardpad';

  @override
  String get kioskMode => 'Kioskmodus';

  @override
  String viewsSaveFailed(String error) {
    return 'Profielen konden niet worden opgeslagen: $error';
  }

  @override
  String get tabOrder => 'Volgorde van tabbladen';

  @override
  String get resetTabOrder => 'Volgorde herstellen';

  @override
  String get dragToReorder => 'Sleep om te ordenen';

  @override
  String previewView(String view) {
    return 'Bekijken als $view';
  }

  @override
  String signedInAs(String user) {
    return 'Aangemeld als $user';
  }

  @override
  String get signedInWithoutAccount => 'Aangemeld zonder account';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · $platform-api-account';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · gekozen bij aanmelden';
  }

  @override
  String get licenses => 'Licenties';

  @override
  String usersNote(String platform) {
    return '$platform-api-accounts in deze implementatie. Een profielwijziging geldt bij de volgende vernieuwing van de gebruiker; een wachtwoord herstellen meldt de gebruiker af.';
  }

  @override
  String usersLoadFailed(String error) {
    return 'Kan gebruikers niet laden: $error';
  }

  @override
  String get usersOnlyAdmins => 'Alleen beheerders kunnen gebruikers beheren.';

  @override
  String userYou(String user) {
    return '$user (jij)';
  }

  @override
  String get resetPasswordTooltip => 'Wachtwoord herstellen';

  @override
  String get removeUserTooltip => 'Gebruiker verwijderen';

  @override
  String get addUserButton => 'Gebruiker toevoegen';

  @override
  String get addUserTitle => 'Gebruiker toevoegen';

  @override
  String get passwordMinLength => 'Minstens 10 tekens';

  @override
  String removeUserTitle(String user) {
    return '$user verwijderen?';
  }

  @override
  String get removeUserBody => 'Diegene wordt overal afgemeld en kan zich niet meer aanmelden.';

  @override
  String newPasswordTitle(String user) {
    return 'Nieuw wachtwoord voor $user';
  }

  @override
  String get newPasswordHelp => 'Meldt diegene overal af';

  @override
  String get diagDeployment => 'Implementatie';

  @override
  String get diagSignIn => 'Aanmelding';

  @override
  String get diagView => 'Profiel';

  @override
  String get diagAuthMode => 'Authenticatiemodus';

  @override
  String get diagAccessToken => 'Toegangstoken';

  @override
  String get diagRefreshToken => 'Vernieuwingstoken';

  @override
  String get diagSecureStorage => 'Beveiligde opslag';

  @override
  String get diagServices => 'Diensten';

  @override
  String get diagChecking => 'controleren…';

  @override
  String get diagNotChecked => 'niet gecontroleerd';

  @override
  String get diagNoAccount => 'geen account';

  @override
  String get diagNone => 'geen';

  @override
  String get diagStored => 'opgeslagen';

  @override
  String get diagAvailable => 'beschikbaar';

  @override
  String get diagUnavailable => 'niet beschikbaar (alleen in geheugen)';

  @override
  String diagServicesViaApi(int online, int known) {
    return '$online van $known actief volgens de API';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return '$online van $known actief volgens de poorten';
  }

  @override
  String get tokenNone => 'geen (wordt bij het volgende verzoek opgehaald)';

  @override
  String tokenExpired(String time) {
    return 'verlopen om $time';
  }

  @override
  String tokenValid(String time, int minutes) {
    return 'geldig tot $time ($minutes min)';
  }

  @override
  String get tokenUnreadable => 'aanwezig (onleesbaar)';

  @override
  String get checkSignIn => 'Aanmelding controleren';

  @override
  String get checkServices => 'Diensten controleren';

  @override
  String get copySettings => 'Instellingen kopiëren';

  @override
  String get settingsDump => 'Export van instellingen';

  @override
  String get secretsHidden => 'Geheimen verborgen';

  @override
  String get summaryChecking => 'Je systeem wordt gecontroleerd…';

  @override
  String get summaryCheckingSub => 'Dit duurt een paar seconden.';

  @override
  String get summaryUnavailable => 'Status van diensten niet beschikbaar';

  @override
  String get summaryUnavailableSub =>
      'Je systeem reageert, maar heeft de status van de diensten niet gemeld. Neem contact op met je beheerder als dit aanhoudt.';

  @override
  String get summaryUnreachable => 'We kunnen je systeem niet bereiken';

  @override
  String get summaryUnreachableSub => 'Controleer of het apparaat aan staat en verbonden is.';

  @override
  String get summaryOk => 'Alles werkt';

  @override
  String get summaryOkSub => 'Je systeem werkt normaal.';

  @override
  String get summaryAttention => 'Er vraagt iets om aandacht';

  @override
  String get summaryAttentionSub =>
      'Een deel van je systeem werkt op dit moment niet. Als het zich niet binnen een paar minuten herstelt, neem dan contact op met je beheerder.';

  @override
  String summaryAffected(String features) {
    return 'Getroffen: $features';
  }

  @override
  String summaryUpdated(String time) {
    return 'Gecontroleerd om $time';
  }

  @override
  String get featureAssistant => 'Assistent';

  @override
  String get featureCharts => 'Grafieken';

  @override
  String get featureHistory => 'Gegevensgeschiedenis';

  @override
  String get featureSensors => 'Sensorgegevens';

  @override
  String get featureAutomations => 'Automatiseringen';

  @override
  String get featureDeviceAi => 'AI op het apparaat';

  @override
  String get featureConnection => 'Verbinding met het systeem';

  @override
  String get yourDevice => 'Je apparaat';

  @override
  String get deviceUnavailable => 'Apparaatmetingen zijn op dit moment niet beschikbaar.';

  @override
  String get deviceLoading => 'Metingen laden…';

  @override
  String get readingProcessor => 'Processor';

  @override
  String get readingMemory => 'Geheugen';

  @override
  String get readingTemperature => 'Temperatuur';

  @override
  String get levelNormal => 'Normaal';

  @override
  String get levelHigh => 'Hoog';

  @override
  String get levelCritical => 'Zeer hoog';

  @override
  String get levelWarm => 'Warm';

  @override
  String get levelHot => 'Heet';

  @override
  String get deviceDetails => 'Details';

  @override
  String servicesApiUnreachable(String platform) {
    return '$platform-api reageert niet, dus de status wordt bepaald door de poort van elke dienst te testen.';
  }

  @override
  String servicesApiNoStatus(String platform, String reason) {
    return '$platform-api geeft geen status van de diensten ($reason), dus de status wordt bepaald door de poort van elke dienst te testen.';
  }

  @override
  String get servicesTitle => 'Diensten';

  @override
  String servicesSubtitle(String host) {
    return 'De applicaties die op $host draaien. Open er een om hem direct te gebruiken.';
  }

  @override
  String get servicesSubtitlePlain => 'De applicaties die op je systeem draaien. Open er een om hem te gebruiken.';

  @override
  String servicesLiveFrom(String authority) {
    return 'Live status van $authority';
  }

  @override
  String servicesContacting(String authority) {
    return 'Verbinden met $authority…';
  }

  @override
  String serviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count diensten', one: '1 dienst');
    return '$_temp0';
  }

  @override
  String endpointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count endpoints', one: '1 endpoint');
    return '$_temp0';
  }

  @override
  String get stackControls => 'Stackacties';

  @override
  String get stackStart => 'Starten';

  @override
  String get stackRestart => 'Herstarten';

  @override
  String get stackStop => 'Stoppen';

  @override
  String stackConfirmStop(String stack) {
    return '$stack stoppen?';
  }

  @override
  String get stackConfirmStopBody => 'De diensten ervan werken voor niemand meer totdat iemand hem opnieuw start.';

  @override
  String stackConfirmRestart(String stack) {
    return '$stack herstarten?';
  }

  @override
  String get stackConfirmRestartBody => 'De diensten ervan stoppen even tijdens het herstarten.';

  @override
  String stackJobRunning(String stack) {
    return 'Bezig met $stack…';
  }

  @override
  String stackJobDone(String stack) {
    return '$stack is klaar.';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return 'Actie op $stack mislukt: $error';
  }

  @override
  String couldNotOpen(String url) {
    return 'Kan $url niet openen';
  }

  @override
  String get tcpOnly => 'Geen webpagina';

  @override
  String get stackIot => 'IoT-stack';

  @override
  String get stackAi => 'AI-stack';

  @override
  String get stackApi => 'API-gateway';

  @override
  String get serviceGrafanaDesc => 'Dashboards en grafieken';

  @override
  String get serviceNodeRedDesc => 'Flow-automatisering';

  @override
  String get serviceInfluxDesc => 'Geschiedenis van sensorgegevens';

  @override
  String get serviceMqttDesc => 'Berichtenbroker voor apparaten';

  @override
  String get serviceOllamaDesc => 'Lokale AI-modellen';

  @override
  String get serviceLettaDesc => 'AI-agents met geheugen';

  @override
  String get serviceN8nDesc => 'Workflowautomatisering';

  @override
  String get serviceEiRunnerDesc => 'AI op het apparaat (Edge Impulse)';

  @override
  String get serviceApiDesc => 'Eén toegangspunt voor alle stacks';

  @override
  String get serviceSwaggerDesc => 'Interactieve API-documentatie';

  @override
  String get clientsIntro =>
      'De status van elke implementatie komt van de API ervan of, als die niet reageert, van het testen van de poorten van de diensten. Verbinden schakelt dit dashboard, en alle verbindingsinstellingen, over naar die implementatie.';

  @override
  String get clientsTitle => 'Klantimplementaties';

  @override
  String get noDeployments => 'Geen implementaties';

  @override
  String get noDeploymentsMsg => 'Voeg een klantimplementatie toe met naam en host om die hier te bewaken.';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known actief';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known actief (via poorten)';
  }

  @override
  String get currentBadge => 'Verbonden';

  @override
  String get editTooltip => 'Bewerken';

  @override
  String get removeTooltip => 'Verwijderen';

  @override
  String get removeCurrentTooltip => 'Verbind met een andere implementatie om deze te verwijderen';

  @override
  String get addDeployment => 'Implementatie toevoegen';

  @override
  String get editDeployment => 'Implementatie bewerken';

  @override
  String get clientName => 'Klantnaam';

  @override
  String get apiUrlOptional => 'API-URL (optioneel)';

  @override
  String get apiUrlHelp => 'Alleen als de API niet op poort 8000 van de host draait';

  @override
  String get edgeDemoSwitch => 'Demogegevens';

  @override
  String get edgeNoMetrics => 'Geen apparaatmetingen';

  @override
  String edgeFetchFailed(String url, String error) {
    return 'Kan $url niet lezen: $error\n\nLaat de metingen-URL in Instellingen wijzen naar een endpoint dat de JSON uit de README teruggeeft.';
  }

  @override
  String get edgeUnavailable => 'Apparaatmetingen zijn op dit moment niet beschikbaar. Probeer het zo opnieuw.';

  @override
  String get edgeSubtitle => 'Live metingen van je apparaat, elke 2 seconden.';

  @override
  String get useDemoData => 'Demogegevens gebruiken';

  @override
  String get edgeStale => 'Verouderd';

  @override
  String get edgeDemoLabel => 'Demogegevens';

  @override
  String get edgeSynthetic => 'Verzonnen metingen om te testen';

  @override
  String get edgeLive => 'Live';

  @override
  String get metricInference => 'Reactietijd van de AI';

  @override
  String get factDisk => 'Gebruikte opslag';

  @override
  String get factLoad => 'Gemiddelde belasting';

  @override
  String get factUptime => 'Actief sinds';

  @override
  String sparkStart(int minutes) {
    return '$minutes min geleden';
  }

  @override
  String get sparkNow => 'Nu';

  @override
  String get agentModel => 'Model';

  @override
  String get agentAgent => 'Agent';

  @override
  String get assistantUnavailable => 'Assistent niet beschikbaar';

  @override
  String get assistantUnavailableMsg => 'De assistent reageert op dit moment niet. Probeer het later opnieuw.';

  @override
  String get assistantNotSetUp => 'Er is geen assistent ingesteld';

  @override
  String get assistantNotSetUpMsg => 'Vraag je beheerder er een in te stellen.';

  @override
  String get assistantChat => 'Vraag het je assistent';

  @override
  String get assistantChatMsg =>
      'Hij weet hoe je systeem er nu voor staat, dus je kunt vragen stellen over je apparaten, gegevens en diensten.';

  @override
  String get assistantSuggestStatus => 'Werkt alles normaal?';

  @override
  String get assistantSuggestDevice => 'Hoe zwaar wordt mijn apparaat nu belast?';

  @override
  String get assistantSuggestHelp => 'Waarmee kun je me helpen?';

  @override
  String get assistantSharedModel => 'Iedereen in deze implementatie praat met dit model.';

  @override
  String get assistantSharedAgent => 'Iedereen in deze implementatie praat met deze agent.';

  @override
  String assistantSaveFailed(String error) {
    return 'Kan de assistent niet wijzigen: $error';
  }

  @override
  String get assistantErrorUnavailable => 'De assistent reageert op dit moment niet. Probeer het zo opnieuw.';

  @override
  String get assistantErrorChanged => 'De assistent is gewijzigd. Begin een nieuw gesprek om verder te gaan.';

  @override
  String get assistantErrorGeneric => 'Dat lukte niet. Probeer het opnieuw.';

  @override
  String get assistantInputUnavailable => 'De assistent is op dit moment niet beschikbaar';

  @override
  String get sendTooltip => 'Versturen';

  @override
  String get stopTooltip => 'Stoppen';

  @override
  String agentUnreachable(String backend) {
    return '$backend reageert niet';
  }

  @override
  String get agentNoModels => 'Geen modellen geïnstalleerd';

  @override
  String get agentNoModelsMsg =>
      'Download er eerst een op het apparaat, bijv. `docker exec p4n4-ollama ollama pull llama3.2`.';

  @override
  String get agentNoAgents => 'Nog geen agents';

  @override
  String get agentNoAgentsMsg => 'Maak een agent aan in de Letta ADE en probeer het opnieuw.';

  @override
  String agentOllamaMsg(String platform) {
    return 'Berichten gaan via $platform-api naar Ollama, met de huidige status van je systeem. De geschiedenis blijft alleen in deze sessie bewaard.';
  }

  @override
  String get agentLettaMsg => 'Letta-agents houden hun eigen geheugen bij tussen sessies.';

  @override
  String get agentMessageHint => 'Stel een vraag… (Shift+Enter voor een nieuwe regel)';

  @override
  String get agentSelectFirst => 'Kies eerst een model of agent';

  @override
  String get agentStopped => '(gestopt)';

  @override
  String get agentThinking => 'Denkt na…';

  @override
  String agentStepLookup(String what) {
    return 'Bekijkt $what';
  }

  @override
  String get agentStepData => 'Bekijkt de gegevens';

  @override
  String get agentWriting => 'Schrijft het antwoord…';

  @override
  String agentElapsed(int seconds) {
    return '$seconds s';
  }

  @override
  String agentWaitLast(int seconds) {
    return 'Het laatste antwoord duurde $seconds s.';
  }

  @override
  String get agentWaitHint => 'Antwoorden kunnen tot een minuut duren.';

  @override
  String get bubbleYou => 'Jij';

  @override
  String get bubbleAgent => 'Assistent';

  @override
  String get bubbleError => 'Er ging iets mis';

  @override
  String get grafanaDashboards => 'Grafieken';

  @override
  String get reloadTooltip => 'Opnieuw laden';

  @override
  String get backTooltip => 'Terug';

  @override
  String get openInBrowser => 'Openen in browser';

  @override
  String embedUnavailable(String platform) {
    return 'De ingesloten weergave is niet beschikbaar op $platform';
  }

  @override
  String get embedUnavailableMsg =>
      'De WebView van Flutter ondersteunt Android, iOS en macOS. Op dit platform opent Grafana in je standaardbrowser.';

  @override
  String get openGrafana => 'Grafana openen';

  @override
  String get grafanaUnreachable => 'Grafana reageert niet';

  @override
  String get dashboardsUnavailable => 'Grafieken niet beschikbaar';

  @override
  String get dashboardsUnavailableMsg =>
      'De grafieken kunnen op dit moment niet worden geladen. Probeer het later opnieuw.';

  @override
  String get viewerClose => 'Terug naar diensten';

  @override
  String viewerLoading(String service) {
    return '$service laden…';
  }

  @override
  String viewerBlankHint(String service) {
    return 'Leeg? $service staat misschien niet toe dat het in de app wordt getoond.';
  }

  @override
  String get viewerDismissHint => 'Sluiten';

  @override
  String openService(String service) {
    return '$service openen';
  }

  @override
  String viewerDownTitle(String service) {
    return '$service is uitgevallen';
  }

  @override
  String get viewerDownMsg =>
      'De container draait niet. Start of herstart hem vanaf het tabblad Diensten en probeer het opnieuw.';

  @override
  String get viewerDownMsgPlain => 'Hij draait nu niet. Probeer het straks opnieuw.';

  @override
  String viewerUnsupportedMsg(String service) {
    return 'De WebView van Flutter ondersteunt Android, iOS en macOS. Op dit platform opent $service in je standaardbrowser.';
  }

  @override
  String viewerBlockedTitle(String service) {
    return '$service kan hier niet worden getoond';
  }

  @override
  String viewerBlockedMsg(String service) {
    return '$service staat niet toe dat het binnen een andere site wordt getoond. Bied het aan via de proxy van het dashboard (zelfde origin) of open het in de browser.';
  }

  @override
  String viewerInsecureMsg(String service) {
    return 'Het dashboard draait op HTTPS en $service alleen op HTTP, dus de browser toont het hier niet. Bied het aan via de proxy van het dashboard of open het in de browser.';
  }

  @override
  String viewerBlockedMsgPlain(String service) {
    return '$service kan niet in de app worden getoond. Open het in je browser.';
  }

  @override
  String viewerUnreachable(String service) {
    return '$service onbereikbaar';
  }

  @override
  String viewerUnavailable(String service) {
    return '$service is niet beschikbaar';
  }

  @override
  String get viewerUnavailableMsg => 'Kan nu niet worden geladen. Probeer het straks opnieuw.';

  @override
  String viewerSlowTitle(String service) {
    return '$service duurt even';
  }

  @override
  String viewerSlowMsg(String service) {
    return 'Blijft het leeg, dan staat $service misschien niet toe dat het in de app wordt getoond. Je kunt het in je browser openen.';
  }

  @override
  String get viewerSlowDetails =>
      'Pagina\'s met X-Frame-Options of een frame-ancestors-beleid blijven leeg in een frame. Bied de dienst aan via de proxy van het dashboard (/svc/<id>/) om hem in te sluiten.';

  @override
  String get viewerKeepWaiting => 'Blijven wachten';

  @override
  String couldNotOpenService(String service) {
    return 'Kon $service niet openen';
  }

  @override
  String serviceUrlField(String service) {
    return 'URL van $service';
  }

  @override
  String cameraDefaultName(int n) {
    return 'Camera $n';
  }

  @override
  String get resumeTooltip => 'Hervatten';

  @override
  String get pauseTooltip => 'Pauzeren';

  @override
  String get reconnectTooltip => 'Opnieuw verbinden';

  @override
  String get singleCamera => 'Eén camera';

  @override
  String get allCameras => 'Alle camera\'s';

  @override
  String get editCamera => 'Camera bewerken';

  @override
  String get addCamera => 'Camera toevoegen';

  @override
  String get addCameraButton => 'Camera toevoegen';

  @override
  String get noCameras => 'Geen camera\'s';

  @override
  String get noCamerasTechnical =>
      'Voeg de URL toe van een MJPEG-stream, een JPEG-momentopname of een videobestand van je edge-camera, of een van de camera\'s van dit apparaat.';

  @override
  String get noCamerasNormie => 'Er is nog geen camera ingesteld. Vraag je beheerder er een toe te voegen.';

  @override
  String get noCamerasConfigured => 'Geen camera\'s ingesteld';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count camera\'s', one: '1 camera');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '\'$name\' heeft een ongeldige URL';
  }

  @override
  String get cameraUrl => 'Stream-, momentopname- of video-URL, of apparaatcamera';

  @override
  String get cameraUrlError => 'Voer een http://- of https://-URL, device:back of device:front in';

  @override
  String get cameraExamples => 'bijv.';

  @override
  String get cameraReconnecting => 'Opnieuw verbinden…';

  @override
  String get cameraStreamEnded => 'De stream is beëindigd';

  @override
  String get cameraUnavailable => 'Camera niet beschikbaar';

  @override
  String get cameraLive => 'Live';

  @override
  String get cameraVideo => 'Video';

  @override
  String get backCamera => 'Achtercamera';

  @override
  String get frontCamera => 'Voorcamera';

  @override
  String get deviceCameraMissing => 'Dit apparaat heeft die camera niet';

  @override
  String get deviceCameraOneAtATime => 'Dit apparaat toont één camera tegelijk';

  @override
  String get deviceCameraShow => 'Deze tonen';

  @override
  String deviceCameraUnsupported(String platform) {
    return 'Apparaatcamera\'s werken niet in de app op $platform';
  }

  @override
  String get videoDemoSwitch => 'Democamera\'s';

  @override
  String get videoGridDefault => 'Openen met alle camera\'s';

  @override
  String get alertSound => 'Meldingsgeluid';

  @override
  String get alertDismiss => 'Melding sluiten';

  @override
  String get visionPerson => 'Persoon';

  @override
  String visionPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personen',
      one: '1 persoon',
      zero: 'Niemand in beeld',
    );
    return '$_temp0';
  }

  @override
  String get sectionChats => 'Chats';

  @override
  String get chatsNote =>
      'Chats die aan de bot van het project gekoppeld zijn, krijgen de meldingen zodra ze gebeuren en kunnen de bot vragen over het project stellen. In een gekoppelde groep kan iedereen dat.';

  @override
  String get chatsLink => 'Chat koppelen';

  @override
  String chatsLinkHow(String bot) {
    return 'Open de link op de telefoon die de bot gaat gebruiken, of stuur deze opdracht naar $bot. Voeg voor een groep eerst de bot aan de groep toe en stuur de opdracht daar.';
  }

  @override
  String get chatsTheBot => 'de bot';

  @override
  String chatsCodeExpires(String time) {
    return 'Werkt één keer, tot $time.';
  }

  @override
  String get chatsCopyLink => 'Link kopiëren';

  @override
  String get chatsCopyCommand => 'Opdracht kopiëren';

  @override
  String get chatsNone => 'Nog geen chats gekoppeld.';

  @override
  String chatsLinkedBy(String date, String who) {
    return 'Gekoppeld op $date door $who';
  }

  @override
  String chatsLinkedOn(String date) {
    return 'Gekoppeld op $date';
  }

  @override
  String chatsMuted(String codes) {
    return 'Gedempt: $codes';
  }

  @override
  String get chatsUnlink => 'Ontkoppelen';

  @override
  String chatsUnlinkTitle(String name) {
    return '$name ontkoppelen?';
  }

  @override
  String get chatsUnlinkBody =>
      'De chat krijgt geen meldingen meer en de bot antwoordt niet meer. De chat krijgt een bericht.';

  @override
  String chatsLoadFailed(String error) {
    return 'Chats konden niet worden geladen: $error';
  }

  @override
  String get chatsMock => 'Testmodus: de bot logt zijn berichten in plaats van ze te versturen.';

  @override
  String get chatsOff => 'Uit: de bot heeft geen token.';

  @override
  String get useDemoCameras => 'Democamera\'s gebruiken';

  @override
  String get videoDemoCredits =>
      'Demobeelden: clips van MDN (CC0); Big Buck Bunny en Sintel © Blender Foundation (CC BY 3.0).';

  @override
  String videoUnsupported(String platform) {
    return 'Videobestanden worden niet afgespeeld in de app op $platform';
  }

  @override
  String get settingsSearch => 'Instellingen zoeken';

  @override
  String settingsNoMatch(String query) {
    return 'Niets gevonden voor \'$query\'';
  }

  @override
  String get groupPersonal => 'Persoonlijk';

  @override
  String get groupDeployment => 'Implementatie';

  @override
  String get groupAdmin => 'Beheer';

  @override
  String get sectionAccessibility => 'Toegankelijkheid';

  @override
  String get sectionLanguageRegion => 'Taal en regio';

  @override
  String get sectionEndpoints => 'Endpoints';

  @override
  String get themeHeading => 'Thema';

  @override
  String get textSize => 'Tekstgrootte';

  @override
  String textSizeValue(String size) {
    return 'Tekst $size';
  }

  @override
  String get textSizePreview => 'Zo ziet tekst eruit in het hele dashboard.';

  @override
  String get textSizeSmaller => 'Kleinere tekst';

  @override
  String get textSizeLarger => 'Grotere tekst';

  @override
  String get resetToDefault => 'Herstellen';

  @override
  String get highContrast => 'Hoog contrast';

  @override
  String get reduceMotion => 'Beweging beperken';

  @override
  String get onInDeviceSettings => 'Ingeschakeld in de instellingen van je apparaat.';

  @override
  String languageDevice(String language) {
    return 'Zoals het apparaat ($language)';
  }

  @override
  String get searchLanguages => 'Talen zoeken';

  @override
  String get formatsHeading => 'Notaties';

  @override
  String get temperatureUnit => 'Temperatuur';

  @override
  String get unitAuto => 'Auto';

  @override
  String get timeFormat => 'Tijd';

  @override
  String get time12h => '12 uur';

  @override
  String get time24h => '24 uur';

  @override
  String tourWelcome(String appName) {
    return 'Welkom bij $appName! Dit zijn de basics.';
  }

  @override
  String get tourNavigation =>
      'Hier staan je schermen. Start laat zien hoe alles gaat; tik op een ander scherm om het te openen.';

  @override
  String get tourTheme => 'Wissel tussen een lichte en een donkere weergave, of volg je apparaat.';

  @override
  String get tourSettings =>
      'Taal, tekstgrootte en meer vind je in Instellingen. Daar kun je deze rondleiding ook herhalen.';

  @override
  String get tourSignOut => 'Meld je hier af als je klaar bent.';

  @override
  String tourProgress(Object current, Object total) {
    return '$current van $total';
  }

  @override
  String get tourNext => 'Volgende';

  @override
  String get tourBack => 'Terug';

  @override
  String get tourDone => 'Begrepen';

  @override
  String get tourSkip => 'Rondleiding overslaan';

  @override
  String get takeTour => 'Rondleiding starten';

  @override
  String get takeTourSubtitle => 'Een snelle blik op het dashboard';

  @override
  String get navFeed => 'Activiteit';

  @override
  String get feedEmpty => 'Nog niets';

  @override
  String get feedEmptyMsg => 'Gebeurtenissen en meldingen verschijnen hier zodra ze plaatsvinden.';

  @override
  String get feedNotSetUp => 'Geen activiteit';

  @override
  String get feedNotSetUpMsg => 'Deze installatie publiceert geen activiteit.';

  @override
  String get feedNotSetUpTechnical => 'Het project heeft geen feed: voeg dashboard.feed toe aan zijn .p4n4.json.';

  @override
  String get feedUnavailable => 'Kan de activiteit niet lezen';

  @override
  String get feedUnavailableMsg => 'Controleer of de diensten van de winkel draaien en probeer het opnieuw.';

  @override
  String feedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count te controleren',
      one: '1 te controleren',
    );
    return '$_temp0';
  }

  @override
  String get feedFilterAll => 'Alles';

  @override
  String get feedFilterAlerts => 'Meldingen';

  @override
  String get feedFilterPending => 'Te controleren';

  @override
  String get feedOlder => 'Ouder';

  @override
  String feedActionFailed(String error) {
    return 'Mislukt: $error';
  }

  @override
  String get feedDemoData => 'Demogegevens';

  @override
  String get feedStatusPending => 'Te controleren';

  @override
  String get feedStatusAttended => 'Afgehandeld';

  @override
  String get feedStatusConfirmed => 'Bevestigd';

  @override
  String get feedStatusDismissed => 'Genegeerd';

  @override
  String feedPosition(int index, int count) {
    return '$index van $count';
  }

  @override
  String get feedPrevious => 'Vorige';

  @override
  String get feedNext => 'Volgende';

  @override
  String get feedKeys => 'Toetsen: 1, 2… de acties · J / K volgende / vorige · Esc terug';

  @override
  String get feedPicture => 'De afbeelding bij de melding';

  @override
  String get feedPictureFailed => 'De afbeelding kon niet worden geladen.';

  @override
  String get changePassword => 'Wachtwoord wijzigen';

  @override
  String get changePasswordSubtitle => 'Meldt je af op je andere apparaten';

  @override
  String get changePasswordTitle => 'Kies een nieuw wachtwoord';

  @override
  String get changePasswordBody => 'Een beheerder vraagt je om eerst je eigen wachtwoord te kiezen.';

  @override
  String get fieldCurrentPassword => 'Huidig wachtwoord';

  @override
  String get fieldNewPassword => 'Nieuw wachtwoord';

  @override
  String get fieldRepeatPassword => 'Herhaal nieuw wachtwoord';

  @override
  String get passwordsDontMatch => 'De wachtwoorden komen niet overeen';

  @override
  String get passwordCurrentWrong => 'Het huidige wachtwoord klopt niet';

  @override
  String get passwordChanged => 'Wachtwoord gewijzigd';

  @override
  String get signOutUserTooltip => 'Overal afmelden';

  @override
  String signOutUserTitle(String user) {
    return '$user overal afmelden?';
  }

  @override
  String get signOutUserBody => 'Diegene moet zich op elk apparaat opnieuw aanmelden. Het wachtwoord blijft hetzelfde.';

  @override
  String get signOutSelfBody =>
      'Je moet je hier en op je andere apparaten opnieuw aanmelden. Je wachtwoord blijft hetzelfde.';

  @override
  String userLastSignIn(String when) {
    return 'Laatst aangemeld: $when';
  }

  @override
  String get userNeverSignedIn => 'Nooit aangemeld';

  @override
  String get userMustChangePassword => 'Moet een nieuw wachtwoord kiezen';

  @override
  String get mustChangeAtFirstSignIn => 'Bij de eerste aanmelding een eigen wachtwoord kiezen';

  @override
  String get mustChangeAtNextSignIn => 'Bij de volgende aanmelding een nieuw wachtwoord kiezen';

  @override
  String get sectionAudit => 'Auditlog';

  @override
  String get auditNote => 'Wie wat heeft gewijzigd in deze omgeving, nieuwste eerst';

  @override
  String auditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count wijzigingen', one: '1 wijziging');
    return '$_temp0, nieuwste eerst';
  }

  @override
  String get auditEmpty => 'Er is nog niets gewijzigd';

  @override
  String auditLoadFailed(String error) {
    return 'Kan het auditlog niet laden: $error';
  }

  @override
  String get auditLoadMore => 'Meer laden';

  @override
  String get sectionBanner => 'Banner';

  @override
  String get bannerNone => 'Geen banner';

  @override
  String get bannerShowing => 'Zichtbaar op elk apparaat tot je hem weghaalt';

  @override
  String bannerShowingUntil(String when) {
    return 'Zichtbaar op elk apparaat tot $when';
  }

  @override
  String get bannerText => 'Bericht';

  @override
  String get bannerHint => 'Onderhoud vandaag 15–16 uur';

  @override
  String get bannerInfo => 'Info';

  @override
  String get bannerWarning => 'Waarschuwing';

  @override
  String get bannerUntilCleared => 'Tot weggehaald';

  @override
  String bannerForHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: '$hours uur', one: '1 uur');
    return '$_temp0';
  }

  @override
  String get bannerClear => 'Weghalen';

  @override
  String get bannerShow => 'Tonen';

  @override
  String get viewStartTab => 'Opent op';

  @override
  String get viewHomeCards => 'Start toont';

  @override
  String get homeCardStatus => 'Status';

  @override
  String get homeCardDevice => 'Apparaatmetingen';

  @override
  String get homeCardPage => 'Projectpagina';

  @override
  String get viewGrafanaPage => 'Grafana-pagina';

  @override
  String get viewGrafanaPageHelp => 'Leeg: de pagina van de omgeving';

  @override
  String get viewCameras => 'Camera\'s';

  @override
  String get viewCameraOverlay => 'Vision-overlay';

  @override
  String get viewAlerts => 'Meldingen die verschijnen';

  @override
  String get alertsAll => 'Alle';

  @override
  String get alertsReview => 'Alleen te beoordelen';

  @override
  String get alertsOff => 'Geen';

  @override
  String get viewAlertSound => 'Geluid bij te beoordelen meldingen';

  @override
  String get sectionDevice => 'Dit apparaat';

  @override
  String get deviceKiosk => 'Kioskmodus';

  @override
  String get kioskModeHelp =>
      'Zet dit apparaat vast op een kijkersaccount: niet afmelden, geen instellingen, en het begint opnieuw als niemand het gebruikt';

  @override
  String get kioskNeedsAccounts => 'Vereist aanmelden met p4n4-api-accounts';

  @override
  String get kioskIdleReset => 'Opnieuw beginnen bij inactiviteit';

  @override
  String get idleSignOut => 'Beheerders en power users afmelden bij inactiviteit';

  @override
  String get idleNever => 'Nooit';

  @override
  String idleAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Na $count minuten', one: 'Na 1 minuut');
    return '$_temp0';
  }

  @override
  String get startKioskTitle => 'Kioskmodus aanzetten';

  @override
  String get startKioskBody =>
      'Meld dit apparaat aan met een kijkersaccount. Hier kan niemand zich afmelden of instellingen wijzigen, en het begint opnieuw als niemand het gebruikt.';

  @override
  String get kioskTurnOn => 'Aanzetten';

  @override
  String get leaveKiosk => 'Kioskmodus verlaten';

  @override
  String get leaveKioskBody =>
      'Meld je aan met een beheerdersaccount. Het apparaat blijft dan aangemeld als die beheerder.';

  @override
  String get kioskNeedsViewer => 'Dat is geen kijkersaccount.';

  @override
  String get kioskNeedsAdmin => 'Dat is geen beheerdersaccount.';

  @override
  String get startTabDefault => 'Standaard';

  @override
  String get chartHistory => 'Grafiekgeschiedenis';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minuten', one: '1 minuut');
    return '$_temp0';
  }

  @override
  String get defaultCamera => 'Standaardcamera';

  @override
  String get defaultCameraFirst => 'De eerste';

  @override
  String logsTitle(String name) {
    return 'Logs van $name';
  }

  @override
  String logsFailed(String error) {
    return 'Gestopt: $error';
  }

  @override
  String get logsEnded => 'De logstroom is beëindigd';

  @override
  String get logsFollowing => 'Nieuwe regels worden gevolgd';

  @override
  String get copyTooltip => 'Kopiëren';

  @override
  String get copied => 'Gekopieerd';

  @override
  String get logsFilter => 'Filteren';

  @override
  String get logsEmpty => 'Nog geen logregels';

  @override
  String get logsNoMatch => 'Geen regels passen bij het filter';

  @override
  String get logsLatest => 'Naar de nieuwste regel';

  @override
  String get logsMenu => 'Logs';

  @override
  String get serviceConfirmRestartBody => 'Hij stopt even voor iedereen die hem gebruikt.';

  @override
  String serviceUptime(String time) {
    return 'actief sinds $time';
  }

  @override
  String get serviceUnhealthy => 'Niet gezond';

  @override
  String get serviceStarting => 'Start op';

  @override
  String serviceActions(String name) {
    return 'Acties voor $name';
  }

  @override
  String get sectionDevices => 'Apparaten';

  @override
  String devicesNote(String platform) {
    return 'Apparaten die metingen naar $platform-api sturen, elk met een eigen sleutel.';
  }

  @override
  String get devicesOnlyAdmins => 'Alleen beheerders kunnen apparaten wijzigen.';

  @override
  String devicesLoadFailed(String error) {
    return 'Kan de apparaten niet laden: $error';
  }

  @override
  String get devicesNone => 'Nog geen apparaten geregistreerd.';

  @override
  String get deviceDisabled => 'Uitgeschakeld';

  @override
  String deviceLastSeen(String time) {
    return 'Laatst gezien $time';
  }

  @override
  String get deviceNeverSeen => 'Nooit gezien';

  @override
  String deviceKey(String prefix) {
    return 'Sleutel $prefix…';
  }

  @override
  String get deviceDisable => 'Uitschakelen: het kan zich niet meer aanmelden';

  @override
  String get deviceEnable => 'Inschakelen';

  @override
  String get rotateKey => 'Nieuwe sleutel';

  @override
  String rotateKeyTitle(String name) {
    return 'Nieuwe sleutel voor $name?';
  }

  @override
  String get rotateKeyBody => 'De huidige sleutel werkt meteen niet meer. Zet de nieuwe op het apparaat.';

  @override
  String removeDeviceTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get removeDeviceBody => 'De sleutel werkt meteen niet meer, en het kan geen metingen meer sturen.';

  @override
  String get removeDeviceTooltip => 'Apparaat verwijderen';

  @override
  String get showMore => 'Meer tonen';

  @override
  String get addDevice => 'Apparaat toevoegen';

  @override
  String get editDevice => 'Apparaat bewerken';

  @override
  String get deviceId => 'Apparaat-ID';

  @override
  String get deviceIdHelp => 'Letters, cijfers, punten, streepjes en underscores; later niet te wijzigen';

  @override
  String get deviceName => 'Naam';

  @override
  String get deviceDescription => 'Beschrijving';

  @override
  String deviceKeyTitle(String id) {
    return 'Sleutel voor $id';
  }

  @override
  String get deviceKeyBody => 'Kopieer hem nu naar het apparaat: hij wordt niet opnieuw getoond.';

  @override
  String get done => 'Klaar';

  @override
  String get contactSupport => 'Contact met support';

  @override
  String summaryDownFor(String time) {
    return 'Al $time uitgevallen';
  }

  @override
  String deviceUpdatedAt(String time) {
    return 'Bijgewerkt om $time';
  }

  @override
  String deviceStaleSince(String time) {
    return 'Kan niet vernieuwen · metingen van $time';
  }

  @override
  String get sectionThresholds => 'Drempels';

  @override
  String get thresholdServiceDown => 'Dienst uitgevallen';

  @override
  String get sensorsTitle => 'Sensoren';

  @override
  String get sensorsSubtitle => 'Live metingen van de apparaten. Tik op een meting voor de geschiedenis.';

  @override
  String sensorsUnavailable(String error) {
    return 'Geen live metingen: $error';
  }

  @override
  String get sensorsNoBroker => 'Nog niet verbonden met de MQTT-broker';

  @override
  String get sensorsWaiting => 'Wachten op metingen…';

  @override
  String sensorReadAt(String time) {
    return 'Gemeten om $time';
  }

  @override
  String get rangeHour => 'Uur';

  @override
  String get rangeDay => 'Dag';

  @override
  String get rangeWeek => 'Week';

  @override
  String sensorHistoryFailed(String error) {
    return 'Kan de geschiedenis niet laden: $error';
  }

  @override
  String get sensorHistoryEmpty => 'Geen metingen opgeslagen in deze periode';

  @override
  String sensorMin(String value) {
    return 'Laagste $value';
  }

  @override
  String sensorMax(String value) {
    return 'Hoogste $value';
  }

  @override
  String get modelTitle => 'Model';

  @override
  String get modelSubtitle => 'De inferentie-runner op het edge-apparaat';

  @override
  String get modelNoRunner => 'Geen inferentie-runner in deze implementatie, of hij antwoordt niet.';

  @override
  String modelFailed(String error) {
    return 'Kan de runner niet bereiken: $error';
  }

  @override
  String get modelInferences => 'Inferenties';

  @override
  String get modelLastLatency => 'Laatste latentie';

  @override
  String get modelLastAt => 'Laatste';

  @override
  String get modelRecent => 'Recente resultaten';

  @override
  String get classifyTitle => 'Probeer het';

  @override
  String get classifyValues => 'Invoerwaarden';

  @override
  String classifyExpects(int expected, int count) {
    return '$count van $expected waarden';
  }

  @override
  String get classify => 'Classificeren';

  @override
  String classifyAnomaly(String score) {
    return 'anomalie $score';
  }

  @override
  String get classifyNotNumbers => 'Voer getallen in, gescheiden door komma\'s of spaties.';

  @override
  String get commandTitle => 'Een opdracht sturen';

  @override
  String get commandSubtitle => 'Publiceert één MQTT-bericht, bijv. op het opdracht-topic van een apparaat';

  @override
  String get commandTopic => 'Topic';

  @override
  String get commandPayload => 'Bericht';

  @override
  String get commandPayloadHelp => 'Tekst of JSON';

  @override
  String get commandRetain => 'Bewaren (retain)';

  @override
  String commandSent(String topic, int bytes) {
    return 'Verstuurd naar $topic ($bytes bytes)';
  }

  @override
  String commandTopicNotAllowed(String topic) {
    return 'Deze implementatie staat publiceren op $topic niet toe (P4N4_API_MQTT_PUBLISH_ALLOW en _DENY in p4n4-api).';
  }

  @override
  String commandNoBroker(String error) {
    return 'p4n4-api is niet verbonden met de broker: $error';
  }

  @override
  String get commandNotAllowed => 'Alleen operators en beheerders kunnen opdrachten sturen.';

  @override
  String commandFailed(String error) {
    return 'Niet verstuurd: $error';
  }

  @override
  String thresholdsNote(String deployment) {
    return 'Wanneer de metingen van $deployment als hoog of kritiek gelden, op dit apparaat.';
  }

  @override
  String thresholdLevels(String high, String critical) {
    return 'Hoog vanaf $high · kritiek vanaf $critical';
  }

  @override
  String get thresholdServiceDownHelp => 'Een dienst die niet meer antwoordt is eerst een waarschuwing, daarna kritiek';

  @override
  String get thresholdsReset => 'Terug naar de standaardwaarden';

  @override
  String get fleetNoReadings => 'Geen apparaatmetingen';

  @override
  String get incidentUnreachable => 'Alles';

  @override
  String incidentOngoing(String service, String start, String length) {
    return '$service uitgevallen sinds $start ($length)';
  }

  @override
  String incidentEnded(String service, String start, String end) {
    return '$service uitgevallen $start–$end';
  }

  @override
  String get incidentHistory => 'Storingsgeschiedenis';

  @override
  String incidentHistoryOf(String name) {
    return '$name: storingen';
  }

  @override
  String get incidentNone => 'Geen storingen gezien vanaf dit apparaat.';

  @override
  String get incidentNote => 'Gezien vanaf dit apparaat terwijl het de status van deze implementatie toonde.';

  @override
  String serviceDownFor(String time) {
    return 'Offline · $time';
  }

  @override
  String get answerStyle => 'Antwoordstijl';

  @override
  String get styleStandard => 'Standaard';

  @override
  String get styleBrief => 'Kort';

  @override
  String get styleSteps => 'Stap voor stap';

  @override
  String get styleSimple => 'Eenvoudige woorden';

  @override
  String get styleCustom => 'Eigen instructies';

  @override
  String get styleCustomLabel => 'Hoe moet de assistent antwoorden?';

  @override
  String get styleCustomHelp => 'Meegestuurd met elke vraag vanaf dit apparaat';

  @override
  String get videoGridLight => 'Licht raster voor trage verbindingen';

  @override
  String get videoGridLightHelp => 'In het raster elke 2 seconden een nieuw beeld in plaats van live beweging';

  @override
  String cameraFrameEvery(int seconds) {
    return 'elke $seconds s';
  }

  @override
  String get clearList => 'Wissen';
}
