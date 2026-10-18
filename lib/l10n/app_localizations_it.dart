// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navClients => 'Clienti';

  @override
  String get navServices => 'Servizi';

  @override
  String get navEdge => 'Dispositivo';

  @override
  String get navAgent => 'Assistente';

  @override
  String get navGrafana => 'Grafici';

  @override
  String get navVideo => 'Telecamere';

  @override
  String previewingView(String view) {
    return 'Stai vedendo il pannello come un profilo $view';
  }

  @override
  String get backToAdmin => 'Torna ad admin';

  @override
  String themeTooltip(String mode) {
    return 'Tema: $mode';
  }

  @override
  String get themeSystem => 'Come il dispositivo';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get settingsTooltip => 'Impostazioni';

  @override
  String get signOutTooltip => 'Esci';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePower => 'Avanzato';

  @override
  String get roleNormie => 'Lettore';

  @override
  String get retry => 'Riprova';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get add => 'Aggiungi';

  @override
  String get remove => 'Rimuovi';

  @override
  String get reset => 'Reimposta';

  @override
  String get delete => 'Elimina';

  @override
  String get clear => 'Nuova conversazione';

  @override
  String get open => 'Apri';

  @override
  String get connect => 'Connetti';

  @override
  String get signOut => 'Esci';

  @override
  String get refreshStatus => 'Aggiorna stato';

  @override
  String get healthOnline => 'Online';

  @override
  String get healthOffline => 'Offline';

  @override
  String get healthChecking => 'Verifica…';

  @override
  String get healthUnknown => 'Sconosciuto';

  @override
  String get fieldUsername => 'Nome utente';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldHost => 'Host';

  @override
  String get fieldName => 'Nome';

  @override
  String get fieldView => 'Profilo';

  @override
  String hostHelp(String platform) {
    return 'La macchina che esegue gli stack $platform. Dall\'emulatore Android usa 10.0.2.2.';
  }

  @override
  String apiBaseUrl(String platform) {
    return 'URL base di $platform-api';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return 'URL base di $platform-api (facoltativo)';
  }

  @override
  String get sessionExpired => 'La sessione è scaduta. Accedi di nuovo.';

  @override
  String get signInTag => 'Accedi';

  @override
  String get signInConnecting => 'Connessione…';

  @override
  String get signInWelcome => 'Benvenuto';

  @override
  String get signInButton => 'Accedi';

  @override
  String get signInWrongCredentials => 'Nome utente o password errati.';

  @override
  String get signInRateLimited => 'Troppi tentativi. Attendi un minuto e riprova.';

  @override
  String signInApiFailed(String platform) {
    return 'Impossibile raggiungere $platform-api. Controlla il server e riprova.';
  }

  @override
  String get signInChooseTitle => 'Scegli come continuare';

  @override
  String signInAuthOffNote(String platform) {
    return '$platform-api funziona senza accesso (P4N4_API_AUTH=off), quindi chiunque può scegliere un profilo.';
  }

  @override
  String get signInOfflineTitle => 'Continua senza accedere';

  @override
  String signInOfflineNote(String platform) {
    return 'Senza $platform-api lo stato dei servizi si ottiene verificando le porte, e il profilo lo scegli tu.';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return 'Impossibile raggiungere $platform-api';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return 'Per accedere serve $platform-api all\'indirizzo $url. Verifica che sia in esecuzione e raggiungibile da questo dispositivo, oppure cambia server qui sotto.';
  }

  @override
  String get signInOfflineButton => 'Continua senza accedere';

  @override
  String get signInDevAccounts => 'Account di sviluppo';

  @override
  String signInDevAccountsNote(String platform) {
    return 'Richiede $platform-api con P4N4_API_DEV_USERS=true';
  }

  @override
  String signInServer(String url) {
    return 'Server: $url';
  }

  @override
  String get signInChangeServer => 'Cambia';

  @override
  String get roleAdminTitle => 'Amministratore';

  @override
  String get roleAdminDesc => 'Tutto, più distribuzioni dei clienti, controllo degli stack, utenti e diagnostica.';

  @override
  String get rolePowerTitle => 'Utente avanzato';

  @override
  String get rolePowerDesc => 'Tutti i servizi e le impostazioni, senza gestire distribuzioni o utenti.';

  @override
  String get roleNormieTitle => 'Lettore';

  @override
  String get roleNormieDesc =>
      'Stato del sistema, grafici, telecamere e assistente. Consultazione senza modificare le impostazioni.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get sectionAppearance => 'Aspetto';

  @override
  String get sectionLanguage => 'Lingua';

  @override
  String get sectionConnection => 'Connessione';

  @override
  String get sectionEdgeMetrics => 'Letture del dispositivo';

  @override
  String get sectionGrafana => 'Grafici';

  @override
  String get sectionVideo => 'Telecamere';

  @override
  String get sectionViews => 'Profili';

  @override
  String get sectionUsers => 'Utenti';

  @override
  String get sectionDiagnostics => 'Diagnostica';

  @override
  String get sectionAccount => 'Account';

  @override
  String get sectionAbout => 'Informazioni';

  @override
  String get languageSystem => 'Come il dispositivo';

  @override
  String get fieldDeployment => 'Distribuzione';

  @override
  String get resetConnection => 'Ripristina la connessione predefinita';

  @override
  String get metricsUrl => 'URL delle metriche';

  @override
  String get demoData => 'Dati demo';

  @override
  String get grafanaBaseUrl => 'URL base di Grafana';

  @override
  String get dashboardPath => 'Percorso della dashboard';

  @override
  String get kioskMode => 'Modalità kiosk';

  @override
  String viewsSaveFailed(String error) {
    return 'Impossibile salvare i profili: $error';
  }

  @override
  String get tabOrder => 'Ordine delle schede';

  @override
  String get resetTabOrder => 'Ripristina l\'ordine';

  @override
  String get dragToReorder => 'Trascina per riordinare';

  @override
  String previewView(String view) {
    return 'Visualizza come $view';
  }

  @override
  String signedInAs(String user) {
    return 'Accesso effettuato come $user';
  }

  @override
  String get signedInWithoutAccount => 'Accesso senza account';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · account $platform-api';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · scelto all\'accesso';
  }

  @override
  String get licenses => 'Licenze';

  @override
  String usersNote(String platform) {
    return 'Account $platform-api di questa distribuzione. Un cambio di profilo si applica al prossimo aggiornamento dell\'utente; reimpostare una password lo disconnette.';
  }

  @override
  String usersLoadFailed(String error) {
    return 'Impossibile caricare gli utenti: $error';
  }

  @override
  String get usersOnlyAdmins => 'Solo gli amministratori possono gestire gli utenti.';

  @override
  String userYou(String user) {
    return '$user (tu)';
  }

  @override
  String get resetPasswordTooltip => 'Reimposta password';

  @override
  String get removeUserTooltip => 'Rimuovi utente';

  @override
  String get addUserButton => 'Aggiungi utente';

  @override
  String get addUserTitle => 'Aggiungi utente';

  @override
  String get passwordMinLength => 'Almeno 10 caratteri';

  @override
  String removeUserTitle(String user) {
    return 'Rimuovere $user?';
  }

  @override
  String get removeUserBody => 'Verrà disconnesso ovunque e non potrà più accedere.';

  @override
  String newPasswordTitle(String user) {
    return 'Nuova password per $user';
  }

  @override
  String get newPasswordHelp => 'Lo disconnette ovunque';

  @override
  String get diagDeployment => 'Distribuzione';

  @override
  String get diagSignIn => 'Accesso';

  @override
  String get diagView => 'Profilo';

  @override
  String get diagAuthMode => 'Modalità di autenticazione';

  @override
  String get diagAccessToken => 'Token di accesso';

  @override
  String get diagRefreshToken => 'Token di rinnovo';

  @override
  String get diagSecureStorage => 'Archiviazione sicura';

  @override
  String get diagServices => 'Servizi';

  @override
  String get diagChecking => 'verifica…';

  @override
  String get diagNotChecked => 'non verificato';

  @override
  String get diagNoAccount => 'nessun account';

  @override
  String get diagNone => 'nessuno';

  @override
  String get diagStored => 'salvato';

  @override
  String get diagAvailable => 'disponibile';

  @override
  String get diagUnavailable => 'non disponibile (solo in memoria)';

  @override
  String diagServicesViaApi(int online, int known) {
    return '$online di $known attivi secondo l\'API';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return '$online di $known attivi secondo le porte';
  }

  @override
  String get tokenNone => 'nessuno (ottenuto alla prossima richiesta)';

  @override
  String tokenExpired(String time) {
    return 'scaduto alle $time';
  }

  @override
  String tokenValid(String time, int minutes) {
    return 'valido fino alle $time ($minutes min)';
  }

  @override
  String get tokenUnreadable => 'presente (illeggibile)';

  @override
  String get checkSignIn => 'Verifica accesso';

  @override
  String get checkServices => 'Verifica servizi';

  @override
  String get copySettings => 'Copia impostazioni';

  @override
  String get settingsDump => 'Esportazione impostazioni';

  @override
  String get secretsHidden => 'Segreti nascosti';

  @override
  String get summaryChecking => 'Verifica del sistema in corso…';

  @override
  String get summaryCheckingSub => 'Ci vuole qualche secondo.';

  @override
  String get summaryUnavailable => 'Stato dei servizi non disponibile';

  @override
  String get summaryUnavailableSub =>
      'Il sistema risponde, ma non ha comunicato lo stato dei servizi. Se il problema persiste, contatta l\'amministratore.';

  @override
  String get summaryUnreachable => 'Impossibile raggiungere il sistema';

  @override
  String get summaryUnreachableSub => 'Verifica che il dispositivo sia acceso e connesso.';

  @override
  String get summaryOk => 'Tutto funziona';

  @override
  String get summaryOkSub => 'Il sistema funziona normalmente.';

  @override
  String get summaryAttention => 'Qualcosa richiede attenzione';

  @override
  String get summaryAttentionSub =>
      'Una parte del sistema non funziona al momento. Se non si ripristina entro qualche minuto, contatta l\'amministratore.';

  @override
  String summaryAffected(String features) {
    return 'Interessati: $features';
  }

  @override
  String summaryUpdated(String time) {
    return 'Verificato alle $time';
  }

  @override
  String get featureAssistant => 'Assistente';

  @override
  String get featureCharts => 'Grafici';

  @override
  String get featureHistory => 'Storico dei dati';

  @override
  String get featureSensors => 'Dati dei sensori';

  @override
  String get featureAutomations => 'Automazioni';

  @override
  String get featureDeviceAi => 'IA sul dispositivo';

  @override
  String get featureConnection => 'Connessione al sistema';

  @override
  String get yourDevice => 'Il tuo dispositivo';

  @override
  String get deviceUnavailable => 'Le letture del dispositivo non sono disponibili al momento.';

  @override
  String get deviceLoading => 'Caricamento letture…';

  @override
  String get readingProcessor => 'Processore';

  @override
  String get readingMemory => 'Memoria';

  @override
  String get readingTemperature => 'Temperatura';

  @override
  String get levelNormal => 'Normale';

  @override
  String get levelHigh => 'Alto';

  @override
  String get levelCritical => 'Molto alto';

  @override
  String get levelWarm => 'Tiepido';

  @override
  String get levelHot => 'Caldo';

  @override
  String get deviceDetails => 'Dettagli';

  @override
  String servicesApiUnreachable(String platform) {
    return '$platform-api non risponde, quindi lo stato si ottiene verificando la porta di ogni servizio.';
  }

  @override
  String get servicesTitle => 'Servizi';

  @override
  String servicesSubtitle(String host) {
    return 'Le applicazioni in esecuzione su $host. Aprine una per usarla direttamente.';
  }

  @override
  String get servicesSubtitlePlain => 'Le applicazioni in esecuzione sul tuo sistema. Aprine una per usarla.';

  @override
  String servicesLiveFrom(String authority) {
    return 'Stato in tempo reale da $authority';
  }

  @override
  String servicesContacting(String authority) {
    return 'Connessione a $authority…';
  }

  @override
  String serviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count servizi', one: '1 servizio');
    return '$_temp0';
  }

  @override
  String endpointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count endpoint', one: '1 endpoint');
    return '$_temp0';
  }

  @override
  String get stackControls => 'Azioni dello stack';

  @override
  String get stackStart => 'Avvia';

  @override
  String get stackRestart => 'Riavvia';

  @override
  String get stackStop => 'Arresta';

  @override
  String stackConfirmStop(String stack) {
    return 'Arrestare lo $stack?';
  }

  @override
  String get stackConfirmStopBody => 'I suoi servizi smettono di funzionare per tutti finché qualcuno non lo riavvia.';

  @override
  String stackConfirmRestart(String stack) {
    return 'Riavviare lo $stack?';
  }

  @override
  String get stackConfirmRestartBody => 'I suoi servizi si interrompono per un momento durante il riavvio.';

  @override
  String stackJobRunning(String stack) {
    return 'Operazione in corso sullo $stack…';
  }

  @override
  String stackJobDone(String stack) {
    return 'Lo $stack ha terminato.';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return 'L\'azione sullo $stack non è riuscita: $error';
  }

  @override
  String couldNotOpen(String url) {
    return 'Impossibile aprire $url';
  }

  @override
  String get tcpOnly => 'Nessuna pagina web';

  @override
  String get stackIot => 'Stack IoT';

  @override
  String get stackAi => 'Stack IA';

  @override
  String get stackApi => 'Gateway API';

  @override
  String get serviceGrafanaDesc => 'Dashboard e grafici';

  @override
  String get serviceNodeRedDesc => 'Automazione dei flussi';

  @override
  String get serviceInfluxDesc => 'Storico dei dati dei sensori';

  @override
  String get serviceMqttDesc => 'Broker di messaggi per i dispositivi';

  @override
  String get serviceOllamaDesc => 'Modelli di IA locali';

  @override
  String get serviceLettaDesc => 'Agenti di IA con memoria';

  @override
  String get serviceN8nDesc => 'Automazione dei workflow';

  @override
  String get serviceEiRunnerDesc => 'IA sul dispositivo (Edge Impulse)';

  @override
  String get serviceApiDesc => 'Un unico punto di accesso per tutti gli stack';

  @override
  String get serviceSwaggerDesc => 'Documentazione interattiva dell\'API';

  @override
  String get clientsIntro =>
      'Lo stato di ogni distribuzione viene dalla sua API o, se non risponde, dalla verifica delle porte dei servizi. Connettersi passa questo pannello, e tutte le impostazioni di connessione, a quella distribuzione.';

  @override
  String get clientsTitle => 'Distribuzioni dei clienti';

  @override
  String get noDeployments => 'Nessuna distribuzione';

  @override
  String get noDeploymentsMsg => 'Aggiungi una distribuzione cliente con nome e host per monitorarla qui.';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known attivi';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known attivi (tramite porte)';
  }

  @override
  String get currentBadge => 'Connesso';

  @override
  String get editTooltip => 'Modifica';

  @override
  String get removeTooltip => 'Rimuovi';

  @override
  String get removeCurrentTooltip => 'Connettiti a un\'altra distribuzione per rimuovere questa';

  @override
  String get addDeployment => 'Aggiungi distribuzione';

  @override
  String get editDeployment => 'Modifica distribuzione';

  @override
  String get clientName => 'Nome del cliente';

  @override
  String get apiUrlOptional => 'URL dell\'API (facoltativo)';

  @override
  String get apiUrlHelp => 'Solo se l\'API non è sulla porta 8000 dell\'host';

  @override
  String get edgeDemoSwitch => 'Dati demo';

  @override
  String get edgeNoMetrics => 'Nessuna lettura dal dispositivo';

  @override
  String edgeFetchFailed(String url, String error) {
    return 'Impossibile leggere $url: $error\n\nImposta l\'URL delle metriche nelle Impostazioni su un endpoint che restituisce il JSON descritto nel README.';
  }

  @override
  String get edgeUnavailable => 'Le letture del dispositivo non sono disponibili al momento. Riprova tra poco.';

  @override
  String get edgeSubtitle => 'Letture in tempo reale dal tuo dispositivo, ogni 2 secondi.';

  @override
  String get useDemoData => 'Usa dati demo';

  @override
  String get edgeStale => 'Non aggiornato';

  @override
  String get edgeDemoLabel => 'Dati demo';

  @override
  String get edgeSynthetic => 'Letture inventate per i test';

  @override
  String get edgeLive => 'In diretta';

  @override
  String get metricInference => 'Tempo di risposta dell\'IA';

  @override
  String get factDisk => 'Spazio utilizzato';

  @override
  String get factLoad => 'Carico medio';

  @override
  String get factUptime => 'In funzione da';

  @override
  String sparkStart(int minutes) {
    return '$minutes min fa';
  }

  @override
  String get sparkNow => 'Ora';

  @override
  String get agentModel => 'Modello';

  @override
  String get agentAgent => 'Agente';

  @override
  String get assistantUnavailable => 'Assistente non disponibile';

  @override
  String get assistantUnavailableMsg => 'L\'assistente non risponde al momento. Riprova più tardi.';

  @override
  String get assistantNotSetUp => 'Nessun assistente configurato';

  @override
  String get assistantNotSetUpMsg => 'Chiedi all\'amministratore di configurarne uno.';

  @override
  String get assistantChat => 'Chiedi al tuo assistente';

  @override
  String get assistantChatMsg =>
      'Conosce lo stato attuale del sistema, quindi puoi chiedergli dei tuoi dispositivi, dati e servizi.';

  @override
  String get assistantSuggestStatus => 'Funziona tutto normalmente?';

  @override
  String get assistantSuggestDevice => 'Quanto lavora il mio dispositivo in questo momento?';

  @override
  String get assistantSuggestHelp => 'In cosa puoi aiutarmi?';

  @override
  String get assistantSharedModel => 'Tutti in questa distribuzione parlano con questo modello.';

  @override
  String get assistantSharedAgent => 'Tutti in questa distribuzione parlano con questo agente.';

  @override
  String assistantSaveFailed(String error) {
    return 'Impossibile cambiare assistente: $error';
  }

  @override
  String get assistantErrorUnavailable => 'L\'assistente non risponde al momento. Riprova tra un attimo.';

  @override
  String get assistantErrorChanged => 'L\'assistente è cambiato. Inizia una nuova conversazione per continuare.';

  @override
  String get assistantErrorGeneric => 'Non ha funzionato. Riprova.';

  @override
  String get assistantInputUnavailable => 'L\'assistente non è disponibile al momento';

  @override
  String get sendTooltip => 'Invia';

  @override
  String get stopTooltip => 'Interrompi';

  @override
  String agentUnreachable(String backend) {
    return '$backend non risponde';
  }

  @override
  String get agentNoModels => 'Nessun modello installato';

  @override
  String get agentNoModelsMsg =>
      'Scaricane prima uno sul dispositivo, ad es. `docker exec p4n4-ollama ollama pull llama3.2`.';

  @override
  String get agentNoAgents => 'Ancora nessun agente';

  @override
  String get agentNoAgentsMsg => 'Crea un agente nell\'ADE di Letta e riprova.';

  @override
  String agentOllamaMsg(String platform) {
    return 'I messaggi vanno a Ollama tramite $platform-api, insieme allo stato attuale del sistema. La cronologia resta solo in questa sessione.';
  }

  @override
  String get agentLettaMsg => 'Gli agenti Letta conservano la propria memoria tra una sessione e l\'altra.';

  @override
  String get agentMessageHint => 'Fai una domanda… (Maiusc+Invio per andare a capo)';

  @override
  String get agentSelectFirst => 'Scegli prima un modello o un agente';

  @override
  String get agentStopped => '(interrotto)';

  @override
  String get agentThinking => 'Sto pensando…';

  @override
  String agentStepLookup(String what) {
    return 'Consulto $what';
  }

  @override
  String get agentStepData => 'Consulto i dati';

  @override
  String get agentWriting => 'Scrivo la risposta…';

  @override
  String agentElapsed(int seconds) {
    return '$seconds s';
  }

  @override
  String agentWaitLast(int seconds) {
    return 'L\'ultima risposta ha richiesto $seconds s.';
  }

  @override
  String get agentWaitHint => 'Le risposte possono richiedere fino a un minuto.';

  @override
  String get bubbleYou => 'Tu';

  @override
  String get bubbleAgent => 'Assistente';

  @override
  String get bubbleError => 'Qualcosa è andato storto';

  @override
  String get grafanaDashboards => 'Grafici';

  @override
  String get reloadTooltip => 'Ricarica';

  @override
  String get backTooltip => 'Indietro';

  @override
  String get openInBrowser => 'Apri nel browser';

  @override
  String embedUnavailable(String platform) {
    return 'La vista integrata non è disponibile su $platform';
  }

  @override
  String get embedUnavailableMsg =>
      'La WebView di Flutter supporta Android, iOS e macOS. Su questa piattaforma Grafana si apre nel browser predefinito.';

  @override
  String get openGrafana => 'Apri Grafana';

  @override
  String get grafanaUnreachable => 'Grafana non risponde';

  @override
  String get dashboardsUnavailable => 'Grafici non disponibili';

  @override
  String get dashboardsUnavailableMsg => 'I grafici non si possono caricare al momento. Riprova più tardi.';

  @override
  String cameraDefaultName(int n) {
    return 'Telecamera $n';
  }

  @override
  String get resumeTooltip => 'Riprendi';

  @override
  String get pauseTooltip => 'Pausa';

  @override
  String get reconnectTooltip => 'Riconnetti';

  @override
  String get singleCamera => 'Una telecamera';

  @override
  String get allCameras => 'Tutte le telecamere';

  @override
  String get editCamera => 'Modifica telecamera';

  @override
  String get addCamera => 'Aggiungi telecamera';

  @override
  String get addCameraButton => 'Aggiungi telecamera';

  @override
  String get noCameras => 'Nessuna telecamera';

  @override
  String get noCamerasTechnical =>
      'Aggiungi l\'URL di uno stream MJPEG, di un\'istantanea JPEG o di un file video della tua telecamera edge, oppure una delle telecamere di questo dispositivo.';

  @override
  String get noCamerasNormie =>
      'Non è ancora configurata nessuna telecamera. Chiedi all\'amministratore di aggiungerne una.';

  @override
  String get noCamerasConfigured => 'Nessuna telecamera configurata';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count telecamere', one: '1 telecamera');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '«$name» ha un URL non valido';
  }

  @override
  String get cameraUrl => 'URL di stream, istantanea o video, oppure telecamera del dispositivo';

  @override
  String get cameraUrlError => 'Inserisci un URL http:// o https://, device:back o device:front';

  @override
  String get cameraExamples => 'ad es.';

  @override
  String get cameraReconnecting => 'Riconnessione…';

  @override
  String get cameraStreamEnded => 'Lo stream è terminato';

  @override
  String get cameraUnavailable => 'Telecamera non disponibile';

  @override
  String get cameraLive => 'In diretta';

  @override
  String get cameraVideo => 'Video';

  @override
  String get backCamera => 'Fotocamera posteriore';

  @override
  String get frontCamera => 'Fotocamera anteriore';

  @override
  String get deviceCameraMissing => 'Questo dispositivo non ha quella telecamera';

  @override
  String get deviceCameraOneAtATime => 'Questo dispositivo mostra una sola telecamera alla volta';

  @override
  String get deviceCameraShow => 'Mostra questa';

  @override
  String deviceCameraUnsupported(String platform) {
    return 'Le telecamere del dispositivo non funzionano nell\'app su $platform';
  }

  @override
  String get videoDemoSwitch => 'Telecamere demo';

  @override
  String get videoGridDefault => 'Apri su tutte le telecamere';

  @override
  String get alertSound => 'Suono degli avvisi';

  @override
  String get alertDismiss => 'Chiudi avviso';

  @override
  String get visionPerson => 'Persona';

  @override
  String visionPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persone',
      one: '1 persona',
      zero: 'Nessuno in vista',
    );
    return '$_temp0';
  }

  @override
  String get sectionChats => 'Chat';

  @override
  String get chatsNote =>
      'Le chat collegate al bot del progetto ricevono i suoi avvisi non appena arrivano e possono fargli domande sul progetto. In un gruppo collegato, possono tutti.';

  @override
  String get chatsLink => 'Collega una chat';

  @override
  String chatsLinkHow(String bot) {
    return 'Apri il link sul telefono che userà il bot, oppure invia questo comando a $bot. Per un gruppo, aggiungi prima il bot al gruppo, poi invia lì il comando.';
  }

  @override
  String get chatsTheBot => 'il bot';

  @override
  String chatsCodeExpires(String time) {
    return 'Valido una volta, fino alle $time.';
  }

  @override
  String get chatsCopyLink => 'Copia link';

  @override
  String get chatsCopyCommand => 'Copia comando';

  @override
  String get chatsNone => 'Nessuna chat collegata.';

  @override
  String chatsLinkedBy(String date, String who) {
    return 'Collegata il $date da $who';
  }

  @override
  String chatsLinkedOn(String date) {
    return 'Collegata il $date';
  }

  @override
  String chatsMuted(String codes) {
    return 'Silenziati: $codes';
  }

  @override
  String get chatsUnlink => 'Scollega';

  @override
  String chatsUnlinkTitle(String name) {
    return 'Scollegare $name?';
  }

  @override
  String get chatsUnlinkBody => 'Non riceve più avvisi e il bot smette di risponderle. La chat viene avvisata.';

  @override
  String chatsLoadFailed(String error) {
    return 'Impossibile caricare le chat: $error';
  }

  @override
  String get chatsMock => 'Modalità simulata: il bot registra i messaggi invece di inviarli.';

  @override
  String get chatsOff => 'Spento: il bot non ha un token.';

  @override
  String get useDemoCameras => 'Usa telecamere demo';

  @override
  String get videoDemoCredits =>
      'Riprese demo: clip di MDN (CC0); Big Buck Bunny e Sintel © Blender Foundation (CC BY 3.0).';

  @override
  String videoUnsupported(String platform) {
    return 'I file video non si riproducono nell\'app su $platform';
  }

  @override
  String get settingsSearch => 'Cerca nelle impostazioni';

  @override
  String settingsNoMatch(String query) {
    return 'Nessun risultato per «$query»';
  }

  @override
  String get groupPersonal => 'Personale';

  @override
  String get groupDeployment => 'Distribuzione';

  @override
  String get groupAdmin => 'Amministrazione';

  @override
  String get sectionAccessibility => 'Accessibilità';

  @override
  String get sectionLanguageRegion => 'Lingua e area geografica';

  @override
  String get sectionEndpoints => 'Endpoint';

  @override
  String get themeHeading => 'Tema';

  @override
  String get textSize => 'Dimensione del testo';

  @override
  String textSizeValue(String size) {
    return 'Testo $size';
  }

  @override
  String get textSizePreview => 'Così appare il testo in tutto il pannello.';

  @override
  String get textSizeSmaller => 'Testo più piccolo';

  @override
  String get textSizeLarger => 'Testo più grande';

  @override
  String get resetToDefault => 'Reimposta';

  @override
  String get highContrast => 'Contrasto elevato';

  @override
  String get reduceMotion => 'Riduci movimento';

  @override
  String get onInDeviceSettings => 'Attivato nelle impostazioni del dispositivo.';

  @override
  String languageDevice(String language) {
    return 'Come il dispositivo ($language)';
  }

  @override
  String get searchLanguages => 'Cerca lingue';

  @override
  String get formatsHeading => 'Formati';

  @override
  String get temperatureUnit => 'Temperatura';

  @override
  String get unitAuto => 'Auto';

  @override
  String get timeFormat => 'Ora';

  @override
  String get time12h => '12 ore';

  @override
  String get time24h => '24 ore';

  @override
  String tourWelcome(String appName) {
    return 'Benvenuto in $appName! Ecco l\'essenziale.';
  }

  @override
  String get tourNavigation =>
      'Ecco le tue schermate. Home mostra come va tutto; tocca un\'altra schermata per aprirla.';

  @override
  String get tourTheme => 'Passa da un aspetto chiaro a uno scuro, oppure segui quello del dispositivo.';

  @override
  String get tourSettings =>
      'Lingua, dimensione del testo e altro sono nelle Impostazioni. Da lì puoi ripetere questo tour.';

  @override
  String get tourSignOut => 'Esci da qui quando hai finito.';

  @override
  String tourProgress(Object current, Object total) {
    return '$current di $total';
  }

  @override
  String get tourNext => 'Avanti';

  @override
  String get tourBack => 'Indietro';

  @override
  String get tourDone => 'Ho capito';

  @override
  String get tourSkip => 'Salta il tour';

  @override
  String get takeTour => 'Fai il tour';

  @override
  String get takeTourSubtitle => 'Un rapido giro del pannello';

  @override
  String get navFeed => 'Attività';

  @override
  String get feedEmpty => 'Ancora niente';

  @override
  String get feedEmptyMsg => 'Eventi e avvisi compaiono qui man mano che accadono.';

  @override
  String get feedNotSetUp => 'Nessuna attività';

  @override
  String get feedNotSetUpMsg => 'Questa installazione non pubblica attività.';

  @override
  String get feedNotSetUpTechnical => 'Il progetto non ha un feed: aggiungi dashboard.feed al suo .p4n4.json.';

  @override
  String get feedUnavailable => 'Impossibile leggere l\'attività';

  @override
  String get feedUnavailableMsg => 'Verifica che i servizi del negozio siano attivi e riprova.';

  @override
  String feedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count da verificare',
      one: '1 da verificare',
    );
    return '$_temp0';
  }

  @override
  String get feedFilterAll => 'Tutto';

  @override
  String get feedFilterAlerts => 'Avvisi';

  @override
  String get feedFilterPending => 'Da verificare';

  @override
  String get feedOlder => 'Precedenti';

  @override
  String feedActionFailed(String error) {
    return 'Non riuscito: $error';
  }

  @override
  String get feedDemoData => 'Dati demo';

  @override
  String get feedStatusPending => 'Da verificare';

  @override
  String get feedStatusAttended => 'Gestito';

  @override
  String get feedStatusConfirmed => 'Confermata';

  @override
  String get feedStatusDismissed => 'Ignorato';

  @override
  String feedPosition(int index, int count) {
    return '$index di $count';
  }

  @override
  String get feedPrevious => 'Precedente';

  @override
  String get feedNext => 'Successivo';

  @override
  String get feedKeys => 'Tasti: 1, 2… le azioni · J / K successivo / precedente · Esc indietro';

  @override
  String get feedPicture => 'L\'immagine dell\'avviso';

  @override
  String get feedPictureFailed => 'Impossibile caricare l\'immagine.';

  @override
  String get changePassword => 'Cambia password';

  @override
  String get changePasswordSubtitle => 'Ti disconnette dagli altri dispositivi';

  @override
  String get changePasswordTitle => 'Scegli una nuova password';

  @override
  String get changePasswordBody => 'Un amministratore ti chiede di scegliere la tua password prima di continuare.';

  @override
  String get fieldCurrentPassword => 'Password attuale';

  @override
  String get fieldNewPassword => 'Nuova password';

  @override
  String get fieldRepeatPassword => 'Ripeti la nuova password';

  @override
  String get passwordsDontMatch => 'Le password non coincidono';

  @override
  String get passwordCurrentWrong => 'La password attuale è sbagliata';

  @override
  String get passwordChanged => 'Password cambiata';

  @override
  String get signOutUserTooltip => 'Disconnetti ovunque';

  @override
  String signOutUserTitle(String user) {
    return 'Disconnettere $user ovunque?';
  }

  @override
  String get signOutUserBody => 'Dovrà accedere di nuovo su ogni dispositivo. La sua password resta la stessa.';

  @override
  String get signOutSelfBody =>
      'Dovrai accedere di nuovo qui e sugli altri dispositivi. La tua password resta la stessa.';

  @override
  String userLastSignIn(String when) {
    return 'Ultimo accesso: $when';
  }

  @override
  String get userNeverSignedIn => 'Mai effettuato l\'accesso';

  @override
  String get userMustChangePassword => 'Deve scegliere una nuova password';

  @override
  String get mustChangeAtFirstSignIn => 'Scegliere la propria password al primo accesso';

  @override
  String get mustChangeAtNextSignIn => 'Scegliere una nuova password al prossimo accesso';

  @override
  String get sectionAudit => 'Registro di controllo';

  @override
  String get auditNote => 'Chi ha cambiato cosa in questo deployment, dal più recente';

  @override
  String auditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count modifiche', one: '1 modifica');
    return '$_temp0, dalla più recente';
  }

  @override
  String get auditEmpty => 'Non è ancora cambiato nulla';

  @override
  String auditLoadFailed(String error) {
    return 'Impossibile caricare il registro di controllo: $error';
  }

  @override
  String get auditLoadMore => 'Carica altro';

  @override
  String get sectionBanner => 'Banner';

  @override
  String get bannerNone => 'Nessun banner';

  @override
  String get bannerShowing => 'Visibile su tutti i dispositivi finché non lo rimuovi';

  @override
  String bannerShowingUntil(String when) {
    return 'Visibile su tutti i dispositivi fino al $when';
  }

  @override
  String get bannerText => 'Messaggio';

  @override
  String get bannerHint => 'Manutenzione oggi dalle 15 alle 16';

  @override
  String get bannerInfo => 'Info';

  @override
  String get bannerWarning => 'Avviso';

  @override
  String get bannerUntilCleared => 'Fino alla rimozione';

  @override
  String bannerForHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: 'Per $hours ore', one: 'Per 1 ora');
    return '$_temp0';
  }

  @override
  String get bannerClear => 'Rimuovi';

  @override
  String get bannerShow => 'Mostra';

  @override
  String get viewStartTab => 'Si apre su';

  @override
  String get viewHomeCards => 'La home mostra';

  @override
  String get homeCardStatus => 'Stato';

  @override
  String get homeCardDevice => 'Letture del dispositivo';

  @override
  String get homeCardPage => 'Pagina del progetto';

  @override
  String get viewGrafanaPage => 'Pagina Grafana';

  @override
  String get viewGrafanaPageHelp => 'Vuoto: la pagina del deployment';

  @override
  String get viewCameras => 'Telecamere';

  @override
  String get viewCameraOverlay => 'Sovrapposizione visione';

  @override
  String get viewAlerts => 'Avvisi mostrati';

  @override
  String get alertsAll => 'Tutti';

  @override
  String get alertsReview => 'Solo quelli da verificare';

  @override
  String get alertsOff => 'Nessuno';

  @override
  String get viewAlertSound => 'Suono per gli avvisi da verificare';

  @override
  String get sectionDevice => 'Questo dispositivo';

  @override
  String get deviceKiosk => 'Modalità kiosk';

  @override
  String get kioskModeHelp =>
      'Blocca questo dispositivo su un account visualizzatore: niente disconnessione né impostazioni, e riparte da capo quando nessuno lo usa';

  @override
  String get kioskNeedsAccounts => 'Richiede l\'accesso con account p4n4-api';

  @override
  String get kioskIdleReset => 'Ripartire da capo se inattivo';

  @override
  String get idleSignOut => 'Disconnetti amministratori e utenti esperti se inattivi';

  @override
  String get idleNever => 'Mai';

  @override
  String idleAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Dopo $count minuti', one: 'Dopo 1 minuto');
    return '$_temp0';
  }

  @override
  String get startKioskTitle => 'Attiva la modalità kiosk';

  @override
  String get startKioskBody =>
      'Accedi su questo dispositivo con un account visualizzatore. Qui non si potrà uscire né cambiare impostazioni, e riparte da capo quando nessuno lo usa.';

  @override
  String get kioskTurnOn => 'Attiva';

  @override
  String get leaveKiosk => 'Esci dalla modalità kiosk';

  @override
  String get leaveKioskBody =>
      'Accedi con un account amministratore. Il dispositivo resterà connesso con quell\'amministratore.';

  @override
  String get kioskNeedsViewer => 'Non è un account visualizzatore.';

  @override
  String get kioskNeedsAdmin => 'Non è un account amministratore.';

  @override
  String get startTabDefault => 'Predefinita';

  @override
  String get chartHistory => 'Cronologia dei grafici';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minuti', one: '1 minuto');
    return '$_temp0';
  }

  @override
  String get defaultCamera => 'Telecamera predefinita';

  @override
  String get defaultCameraFirst => 'La prima';

  @override
  String logsTitle(String name) {
    return 'Log di $name';
  }

  @override
  String logsFailed(String error) {
    return 'Interrotto: $error';
  }

  @override
  String get logsEnded => 'Il flusso dei log è terminato';

  @override
  String get logsFollowing => 'Segue le nuove righe';

  @override
  String get copyTooltip => 'Copia';

  @override
  String get copied => 'Copiato';

  @override
  String get logsFilter => 'Filtra';

  @override
  String get logsEmpty => 'Ancora nessuna riga di log';

  @override
  String get logsNoMatch => 'Nessuna riga corrisponde al filtro';

  @override
  String get logsLatest => 'Vai alla riga più recente';

  @override
  String get logsMenu => 'Log';

  @override
  String get serviceConfirmRestartBody => 'Si ferma un attimo per tutti quelli che lo usano.';

  @override
  String serviceUptime(String time) {
    return 'attivo da $time';
  }

  @override
  String get serviceUnhealthy => 'Non integro';

  @override
  String get serviceStarting => 'In avvio';

  @override
  String serviceActions(String name) {
    return 'Azioni su $name';
  }

  @override
  String get sectionDevices => 'Dispositivi';

  @override
  String devicesNote(String platform) {
    return 'Dispositivi che inviano letture a $platform-api, ognuno con la propria chiave.';
  }

  @override
  String get devicesOnlyAdmins => 'Solo gli amministratori possono modificare i dispositivi.';

  @override
  String devicesLoadFailed(String error) {
    return 'Impossibile caricare i dispositivi: $error';
  }

  @override
  String get devicesNone => 'Nessun dispositivo ancora registrato.';

  @override
  String get deviceDisabled => 'Disattivato';

  @override
  String deviceLastSeen(String time) {
    return 'Visto l\'ultima volta $time';
  }

  @override
  String get deviceNeverSeen => 'Mai visto';

  @override
  String deviceKey(String prefix) {
    return 'Chiave $prefix…';
  }

  @override
  String get deviceDisable => 'Disattiva: non potrà accedere';

  @override
  String get deviceEnable => 'Attiva';

  @override
  String get rotateKey => 'Nuova chiave';

  @override
  String rotateKeyTitle(String name) {
    return 'Nuova chiave per $name?';
  }

  @override
  String get rotateKeyBody => 'La chiave attuale smette subito di funzionare. Metti quella nuova sul dispositivo.';

  @override
  String removeDeviceTitle(String name) {
    return 'Rimuovere $name?';
  }

  @override
  String get removeDeviceBody => 'La sua chiave smette subito di funzionare e non potrà più inviare letture.';

  @override
  String get removeDeviceTooltip => 'Rimuovi dispositivo';

  @override
  String get showMore => 'Mostra altro';

  @override
  String get addDevice => 'Aggiungi dispositivo';

  @override
  String get editDevice => 'Modifica dispositivo';

  @override
  String get deviceId => 'ID del dispositivo';

  @override
  String get deviceIdHelp => 'Lettere, cifre, punti, trattini e trattini bassi; non si può cambiare dopo';

  @override
  String get deviceName => 'Nome';

  @override
  String get deviceDescription => 'Descrizione';

  @override
  String deviceKeyTitle(String id) {
    return 'Chiave di $id';
  }

  @override
  String get deviceKeyBody => 'Copiala ora sul dispositivo: non verrà mostrata di nuovo.';

  @override
  String get done => 'Fatto';

  @override
  String get contactSupport => 'Contatta l\'assistenza';

  @override
  String summaryDownFor(String time) {
    return 'Non disponibile da $time';
  }

  @override
  String deviceUpdatedAt(String time) {
    return 'Aggiornato alle $time';
  }

  @override
  String deviceStaleSince(String time) {
    return 'Impossibile aggiornare · letture delle $time';
  }

  @override
  String get sectionThresholds => 'Soglie';

  @override
  String get thresholdServiceDown => 'Servizio non disponibile';

  @override
  String get sensorsTitle => 'Sensori';

  @override
  String get sensorsSubtitle => 'Letture in tempo reale dai dispositivi. Toccane una per lo storico.';

  @override
  String sensorsUnavailable(String error) {
    return 'Nessuna lettura in tempo reale: $error';
  }

  @override
  String get sensorsNoBroker => 'Non ancora connesso al broker MQTT';

  @override
  String get sensorsWaiting => 'In attesa di letture…';

  @override
  String sensorReadAt(String time) {
    return 'Letto alle $time';
  }

  @override
  String get rangeHour => 'Ora';

  @override
  String get rangeDay => 'Giorno';

  @override
  String get rangeWeek => 'Settimana';

  @override
  String sensorHistoryFailed(String error) {
    return 'Impossibile caricare lo storico: $error';
  }

  @override
  String get sensorHistoryEmpty => 'Nessuna lettura salvata in questo periodo';

  @override
  String sensorMin(String value) {
    return 'Minimo $value';
  }

  @override
  String sensorMax(String value) {
    return 'Massimo $value';
  }

  @override
  String get modelTitle => 'Modello';

  @override
  String get modelSubtitle => 'L\'esecutore di inferenza sul dispositivo edge';

  @override
  String get modelNoRunner => 'Nessun esecutore di inferenza in questa distribuzione, oppure non risponde.';

  @override
  String modelFailed(String error) {
    return 'Impossibile raggiungere l\'esecutore: $error';
  }

  @override
  String get modelInferences => 'Inferenze';

  @override
  String get modelLastLatency => 'Ultima latenza';

  @override
  String get modelLastAt => 'L\'ultima';

  @override
  String get modelRecent => 'Risultati recenti';

  @override
  String get classifyTitle => 'Provalo';

  @override
  String get classifyValues => 'Valori di input';

  @override
  String classifyExpects(int expected, int count) {
    return '$count di $expected valori';
  }

  @override
  String get classify => 'Classifica';

  @override
  String classifyAnomaly(String score) {
    return 'anomalia $score';
  }

  @override
  String get classifyNotNumbers => 'Inserisci numeri separati da virgole o spazi.';

  @override
  String get commandTitle => 'Invia un comando';

  @override
  String get commandSubtitle => 'Pubblica un messaggio MQTT, ad es. sul topic dei comandi di un dispositivo';

  @override
  String get commandTopic => 'Topic';

  @override
  String get commandPayload => 'Messaggio';

  @override
  String get commandPayloadHelp => 'Testo o JSON';

  @override
  String get commandRetain => 'Conserva';

  @override
  String commandSent(String topic, int bytes) {
    return 'Inviato a $topic ($bytes byte)';
  }

  @override
  String commandTopicNotAllowed(String topic) {
    return 'Questa distribuzione non permette di pubblicare su $topic (P4N4_API_MQTT_PUBLISH_ALLOW e _DENY in p4n4-api).';
  }

  @override
  String commandNoBroker(String error) {
    return 'p4n4-api non è connesso al broker: $error';
  }

  @override
  String get commandNotAllowed => 'Solo operatori e amministratori possono inviare comandi.';

  @override
  String commandFailed(String error) {
    return 'Non inviato: $error';
  }

  @override
  String thresholdsNote(String deployment) {
    return 'Quando le letture di $deployment risultano alte o critiche, su questo dispositivo.';
  }

  @override
  String thresholdLevels(String high, String critical) {
    return 'Alto da $high · critico da $critical';
  }

  @override
  String get thresholdServiceDownHelp => 'Un servizio che smette di rispondere è prima un avviso, poi critico';

  @override
  String get thresholdsReset => 'Torna ai valori predefiniti';

  @override
  String get fleetNoReadings => 'Nessuna lettura del dispositivo';

  @override
  String get incidentUnreachable => 'Tutto';

  @override
  String incidentOngoing(String service, String start, String length) {
    return '$service non disponibile dalle $start ($length)';
  }

  @override
  String incidentEnded(String service, String start, String end) {
    return '$service non disponibile $start–$end';
  }

  @override
  String get incidentHistory => 'Storico dei disservizi';

  @override
  String incidentHistoryOf(String name) {
    return '$name: disservizi';
  }

  @override
  String get incidentNone => 'Nessun disservizio visto da questo dispositivo.';

  @override
  String get incidentNote => 'Visti da questo dispositivo mentre mostrava lo stato di questa distribuzione.';

  @override
  String serviceDownFor(String time) {
    return 'Offline · $time';
  }

  @override
  String get answerStyle => 'Stile di risposta';

  @override
  String get styleStandard => 'Standard';

  @override
  String get styleBrief => 'Breve';

  @override
  String get styleSteps => 'Passo passo';

  @override
  String get styleSimple => 'Parole semplici';

  @override
  String get styleCustom => 'Istruzioni proprie';

  @override
  String get styleCustomLabel => 'Come deve rispondere l\'assistente?';

  @override
  String get styleCustomHelp => 'Inviate con ogni domanda da questo dispositivo';

  @override
  String get videoGridLight => 'Griglia leggera per connessioni lente';

  @override
  String get videoGridLightHelp => 'Nella griglia, un\'immagine nuova ogni 2 secondi invece del movimento in diretta';

  @override
  String cameraFrameEvery(int seconds) {
    return 'ogni $seconds s';
  }

  @override
  String get clearList => 'Cancella';
}
