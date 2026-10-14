// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navHome => 'Accueil';

  @override
  String get navClients => 'Clients';

  @override
  String get navServices => 'Services';

  @override
  String get navEdge => 'Appareil';

  @override
  String get navAgent => 'Assistant';

  @override
  String get navGrafana => 'Graphiques';

  @override
  String get navVideo => 'Caméras';

  @override
  String previewingView(String view) {
    return 'Vous voyez le tableau de bord comme un profil $view';
  }

  @override
  String get backToAdmin => 'Revenir en admin';

  @override
  String themeTooltip(String mode) {
    return 'Thème : $mode';
  }

  @override
  String get themeSystem => 'Comme l\'appareil';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsTooltip => 'Réglages';

  @override
  String get signOutTooltip => 'Se déconnecter';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePower => 'Avancé';

  @override
  String get roleNormie => 'Lecteur';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get add => 'Ajouter';

  @override
  String get remove => 'Supprimer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get delete => 'Effacer';

  @override
  String get clear => 'Nouvelle conversation';

  @override
  String get open => 'Ouvrir';

  @override
  String get connect => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get refreshStatus => 'Actualiser l\'état';

  @override
  String get healthOnline => 'En ligne';

  @override
  String get healthOffline => 'Hors ligne';

  @override
  String get healthChecking => 'Vérification…';

  @override
  String get healthUnknown => 'Inconnu';

  @override
  String get fieldUsername => 'Nom d\'utilisateur';

  @override
  String get fieldPassword => 'Mot de passe';

  @override
  String get fieldHost => 'Hôte';

  @override
  String get fieldName => 'Nom';

  @override
  String get fieldView => 'Profil';

  @override
  String hostHelp(String platform) {
    return 'La machine qui exécute les stacks $platform. Depuis l\'émulateur Android, utilisez 10.0.2.2.';
  }

  @override
  String apiBaseUrl(String platform) {
    return 'URL de base de $platform-api';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return 'URL de base de $platform-api (facultatif)';
  }

  @override
  String get sessionExpired => 'Votre session a expiré. Reconnectez-vous.';

  @override
  String get signInTag => 'Connexion';

  @override
  String get signInConnecting => 'Connexion…';

  @override
  String get signInWelcome => 'Bienvenue';

  @override
  String get signInButton => 'Se connecter';

  @override
  String get signInWrongCredentials => 'Nom d\'utilisateur ou mot de passe incorrect.';

  @override
  String get signInRateLimited => 'Trop de tentatives. Patientez une minute puis réessayez.';

  @override
  String signInApiFailed(String platform) {
    return 'Impossible de joindre $platform-api. Vérifiez le serveur puis réessayez.';
  }

  @override
  String get signInChooseTitle => 'Choisissez comment continuer';

  @override
  String signInAuthOffNote(String platform) {
    return '$platform-api fonctionne sans connexion (P4N4_API_AUTH=off) : chacun peut donc choisir un profil.';
  }

  @override
  String get signInOfflineTitle => 'Continuer sans se connecter';

  @override
  String signInOfflineNote(String platform) {
    return 'Sans $platform-api, l\'état des services est obtenu en testant les ports, et vous choisissez vous-même le profil.';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return 'Impossible de joindre $platform-api';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return 'La connexion nécessite $platform-api à l\'adresse $url. Vérifiez qu\'il est démarré et accessible depuis cet appareil, ou changez de serveur ci-dessous.';
  }

  @override
  String get signInOfflineButton => 'Continuer sans se connecter';

  @override
  String get signInDevAccounts => 'Comptes de développement';

  @override
  String signInDevAccountsNote(String platform) {
    return 'Nécessite $platform-api avec P4N4_API_DEV_USERS=true';
  }

  @override
  String signInServer(String url) {
    return 'Serveur : $url';
  }

  @override
  String get signInChangeServer => 'Changer';

  @override
  String get roleAdminTitle => 'Administrateur';

  @override
  String get roleAdminDesc =>
      'Tout, plus les déploiements clients, le contrôle des stacks, les utilisateurs et le diagnostic.';

  @override
  String get rolePowerTitle => 'Utilisateur avancé';

  @override
  String get rolePowerDesc => 'Tous les services et réglages, sans gérer les déploiements ni les utilisateurs.';

  @override
  String get roleNormieTitle => 'Lecteur';

  @override
  String get roleNormieDesc =>
      'État du système, graphiques, caméras et assistant. Consultation sans modifier les réglages.';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get sectionLanguage => 'Langue';

  @override
  String get sectionConnection => 'Connexion';

  @override
  String get sectionEdgeMetrics => 'Mesures de l\'appareil';

  @override
  String get sectionGrafana => 'Graphiques';

  @override
  String get sectionVideo => 'Caméras';

  @override
  String get sectionViews => 'Profils';

  @override
  String get sectionUsers => 'Utilisateurs';

  @override
  String get sectionDiagnostics => 'Diagnostic';

  @override
  String get sectionAccount => 'Compte';

  @override
  String get sectionAbout => 'À propos';

  @override
  String get languageSystem => 'Comme l\'appareil';

  @override
  String get fieldDeployment => 'Déploiement';

  @override
  String get resetConnection => 'Rétablir la connexion par défaut';

  @override
  String get metricsUrl => 'URL des mesures';

  @override
  String get demoData => 'Données de démonstration';

  @override
  String get grafanaBaseUrl => 'URL de base de Grafana';

  @override
  String get dashboardPath => 'Chemin du tableau de bord';

  @override
  String get kioskMode => 'Mode kiosque';

  @override
  String viewsSaveFailed(String error) {
    return 'Impossible d\'enregistrer les profils : $error';
  }

  @override
  String get tabOrder => 'Ordre des onglets';

  @override
  String get resetTabOrder => 'Rétablir l\'ordre';

  @override
  String get dragToReorder => 'Faites glisser pour réordonner';

  @override
  String previewView(String view) {
    return 'Voir en tant que $view';
  }

  @override
  String signedInAs(String user) {
    return 'Connecté en tant que $user';
  }

  @override
  String get signedInWithoutAccount => 'Connecté sans compte';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · compte $platform-api';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · choisi à la connexion';
  }

  @override
  String get licenses => 'Licences';

  @override
  String usersNote(String platform) {
    return 'Les comptes $platform-api de ce déploiement. Un changement de profil s\'applique à la prochaine actualisation de l\'utilisateur ; réinitialiser un mot de passe le déconnecte.';
  }

  @override
  String usersLoadFailed(String error) {
    return 'Impossible de charger les utilisateurs : $error';
  }

  @override
  String get usersOnlyAdmins => 'Seuls les administrateurs peuvent gérer les utilisateurs.';

  @override
  String userYou(String user) {
    return '$user (vous)';
  }

  @override
  String get resetPasswordTooltip => 'Réinitialiser le mot de passe';

  @override
  String get removeUserTooltip => 'Supprimer l\'utilisateur';

  @override
  String get addUserButton => 'Ajouter un utilisateur';

  @override
  String get addUserTitle => 'Ajouter un utilisateur';

  @override
  String get passwordMinLength => 'Au moins 10 caractères';

  @override
  String removeUserTitle(String user) {
    return 'Supprimer $user ?';
  }

  @override
  String get removeUserBody => 'Cette personne sera déconnectée partout et ne pourra plus se reconnecter.';

  @override
  String newPasswordTitle(String user) {
    return 'Nouveau mot de passe pour $user';
  }

  @override
  String get newPasswordHelp => 'Le déconnecte partout';

  @override
  String get diagDeployment => 'Déploiement';

  @override
  String get diagSignIn => 'Connexion';

  @override
  String get diagView => 'Profil';

  @override
  String get diagAuthMode => 'Mode d\'authentification';

  @override
  String get diagAccessToken => 'Jeton d\'accès';

  @override
  String get diagRefreshToken => 'Jeton de renouvellement';

  @override
  String get diagSecureStorage => 'Stockage sécurisé';

  @override
  String get diagServices => 'Services';

  @override
  String get diagChecking => 'vérification…';

  @override
  String get diagNotChecked => 'non vérifié';

  @override
  String get diagNoAccount => 'aucun compte';

  @override
  String get diagNone => 'aucun';

  @override
  String get diagStored => 'enregistré';

  @override
  String get diagAvailable => 'disponible';

  @override
  String get diagUnavailable => 'indisponible (en mémoire uniquement)';

  @override
  String diagServicesViaApi(int online, int known) {
    return '$online sur $known actifs selon l\'API';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return '$online sur $known actifs selon les ports';
  }

  @override
  String get tokenNone => 'aucun (obtenu à la prochaine requête)';

  @override
  String tokenExpired(String time) {
    return 'expiré à $time';
  }

  @override
  String tokenValid(String time, int minutes) {
    return 'valable jusqu\'à $time ($minutes min)';
  }

  @override
  String get tokenUnreadable => 'présent (illisible)';

  @override
  String get checkSignIn => 'Vérifier la connexion';

  @override
  String get checkServices => 'Vérifier les services';

  @override
  String get copySettings => 'Copier les réglages';

  @override
  String get settingsDump => 'Export des réglages';

  @override
  String get secretsHidden => 'Secrets masqués';

  @override
  String get summaryChecking => 'Vérification de votre système…';

  @override
  String get summaryCheckingSub => 'Cela prend quelques secondes.';

  @override
  String get summaryUnavailable => 'État des services indisponible';

  @override
  String get summaryUnavailableSub =>
      'Votre système répond, mais n\'a pas indiqué l\'état de ses services. Contactez votre administrateur si cela persiste.';

  @override
  String get summaryUnreachable => 'Impossible de joindre votre système';

  @override
  String get summaryUnreachableSub => 'Vérifiez que l\'appareil est allumé et connecté.';

  @override
  String get summaryOk => 'Tout fonctionne';

  @override
  String get summaryOkSub => 'Votre système fonctionne normalement.';

  @override
  String get summaryAttention => 'Un point demande votre attention';

  @override
  String get summaryAttentionSub =>
      'Une partie de votre système ne fonctionne pas pour le moment. Si elle ne revient pas d\'ici quelques minutes, contactez votre administrateur.';

  @override
  String summaryAffected(String features) {
    return 'Concerné : $features';
  }

  @override
  String summaryUpdated(String time) {
    return 'Vérifié à $time';
  }

  @override
  String get featureAssistant => 'Assistant';

  @override
  String get featureCharts => 'Graphiques';

  @override
  String get featureHistory => 'Historique des données';

  @override
  String get featureSensors => 'Données des capteurs';

  @override
  String get featureAutomations => 'Automatisations';

  @override
  String get featureDeviceAi => 'IA sur l\'appareil';

  @override
  String get featureConnection => 'Connexion au système';

  @override
  String get yourDevice => 'Votre appareil';

  @override
  String get deviceUnavailable => 'Les mesures de l\'appareil ne sont pas disponibles pour le moment.';

  @override
  String get deviceLoading => 'Chargement des mesures…';

  @override
  String get readingProcessor => 'Processeur';

  @override
  String get readingMemory => 'Mémoire';

  @override
  String get readingTemperature => 'Température';

  @override
  String get levelNormal => 'Normal';

  @override
  String get levelHigh => 'Élevé';

  @override
  String get levelCritical => 'Très élevé';

  @override
  String get levelWarm => 'Tiède';

  @override
  String get levelHot => 'Chaud';

  @override
  String get deviceDetails => 'Détails';

  @override
  String servicesApiUnreachable(String platform) {
    return '$platform-api ne répond pas : l\'état est donc obtenu en testant le port de chaque service.';
  }

  @override
  String get servicesTitle => 'Services';

  @override
  String servicesSubtitle(String host) {
    return 'Les applications qui tournent sur $host. Ouvrez-en une pour l\'utiliser directement.';
  }

  @override
  String get servicesSubtitlePlain =>
      'Les applications qui tournent sur votre système. Ouvrez-en une pour l\'utiliser.';

  @override
  String servicesLiveFrom(String authority) {
    return 'État en direct depuis $authority';
  }

  @override
  String servicesContacting(String authority) {
    return 'Connexion à $authority…';
  }

  @override
  String serviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count services', one: '1 service');
    return '$_temp0';
  }

  @override
  String endpointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count endpoints', one: '1 endpoint');
    return '$_temp0';
  }

  @override
  String get stackControls => 'Actions du stack';

  @override
  String get stackStart => 'Démarrer';

  @override
  String get stackRestart => 'Redémarrer';

  @override
  String get stackStop => 'Arrêter';

  @override
  String stackConfirmStop(String stack) {
    return 'Arrêter le $stack ?';
  }

  @override
  String get stackConfirmStopBody =>
      'Ses services cessent de fonctionner pour tout le monde jusqu\'à ce que quelqu\'un le redémarre.';

  @override
  String stackConfirmRestart(String stack) {
    return 'Redémarrer le $stack ?';
  }

  @override
  String get stackConfirmRestartBody => 'Ses services s\'interrompent un instant pendant le redémarrage.';

  @override
  String stackJobRunning(String stack) {
    return 'Opération en cours sur le $stack…';
  }

  @override
  String stackJobDone(String stack) {
    return 'Le $stack a terminé.';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return 'L\'action sur le $stack a échoué : $error';
  }

  @override
  String couldNotOpen(String url) {
    return 'Impossible d\'ouvrir $url';
  }

  @override
  String get tcpOnly => 'Pas de page web';

  @override
  String get stackIot => 'Stack IoT';

  @override
  String get stackAi => 'Stack IA';

  @override
  String get stackEdge => 'Stack Edge';

  @override
  String get stackApi => 'Passerelle API';

  @override
  String get serviceGrafanaDesc => 'Tableaux de bord et graphiques';

  @override
  String get serviceNodeRedDesc => 'Automatisation de flux';

  @override
  String get serviceInfluxDesc => 'Historique des données des capteurs';

  @override
  String get serviceMqttDesc => 'Broker de messages pour les appareils';

  @override
  String get serviceOllamaDesc => 'Modèles d\'IA locaux';

  @override
  String get serviceLettaDesc => 'Agents d\'IA avec mémoire';

  @override
  String get serviceN8nDesc => 'Automatisation des workflows';

  @override
  String get serviceEiRunnerDesc => 'IA sur l\'appareil (Edge Impulse)';

  @override
  String get serviceApiDesc => 'Point d\'entrée unique pour tous les stacks';

  @override
  String get serviceSwaggerDesc => 'Documentation interactive de l\'API';

  @override
  String get clientsIntro =>
      'L\'état de chaque déploiement provient de son API ou, si elle ne répond pas, du test des ports de ses services. Se connecter bascule ce tableau de bord, et tous les réglages de connexion, sur ce déploiement.';

  @override
  String get clientsTitle => 'Déploiements clients';

  @override
  String get noDeployments => 'Aucun déploiement';

  @override
  String get noDeploymentsMsg => 'Ajoutez un déploiement client avec son nom et son hôte pour le superviser ici.';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known actifs';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known actifs (par les ports)';
  }

  @override
  String get currentBadge => 'Connecté';

  @override
  String get editTooltip => 'Modifier';

  @override
  String get removeTooltip => 'Supprimer';

  @override
  String get removeCurrentTooltip => 'Connectez-vous à un autre déploiement pour supprimer celui-ci';

  @override
  String get addDeployment => 'Ajouter un déploiement';

  @override
  String get editDeployment => 'Modifier le déploiement';

  @override
  String get clientName => 'Nom du client';

  @override
  String get apiUrlOptional => 'URL de l\'API (facultatif)';

  @override
  String get apiUrlHelp => 'Seulement si l\'API n\'est pas sur le port 8000 de l\'hôte';

  @override
  String get edgeDemoSwitch => 'Données de démonstration';

  @override
  String get edgeNoMetrics => 'Aucune mesure de l\'appareil';

  @override
  String edgeFetchFailed(String url, String error) {
    return 'Impossible de lire $url : $error\n\nFaites pointer l\'URL des mesures, dans Réglages, vers un endpoint qui renvoie le JSON décrit dans le README.';
  }

  @override
  String get edgeUnavailable =>
      'Les mesures de l\'appareil ne sont pas disponibles pour le moment. Réessayez dans un instant.';

  @override
  String get edgeSubtitle => 'Mesures en direct de votre appareil, toutes les 2 secondes.';

  @override
  String get useDemoData => 'Utiliser les données de démonstration';

  @override
  String get edgeStale => 'Pas à jour';

  @override
  String get edgeDemoLabel => 'Données de démonstration';

  @override
  String get edgeSynthetic => 'Mesures inventées pour les tests';

  @override
  String get edgeLive => 'En direct';

  @override
  String get metricInference => 'Temps de réponse de l\'IA';

  @override
  String get factDisk => 'Stockage utilisé';

  @override
  String get factLoad => 'Charge moyenne';

  @override
  String get factUptime => 'En marche depuis';

  @override
  String get sparkStart => 'il y a 2 min';

  @override
  String get sparkNow => 'Maintenant';

  @override
  String get agentModel => 'Modèle';

  @override
  String get agentAgent => 'Agent';

  @override
  String get assistantUnavailable => 'Assistant indisponible';

  @override
  String get assistantUnavailableMsg => 'L\'assistant ne répond pas pour le moment. Réessayez un peu plus tard.';

  @override
  String get assistantNotSetUp => 'Aucun assistant n\'est configuré';

  @override
  String get assistantNotSetUpMsg => 'Demandez à votre administrateur d\'en configurer un.';

  @override
  String get assistantChat => 'Posez une question à votre assistant';

  @override
  String get assistantChatMsg =>
      'Il connaît l\'état actuel de votre système : vous pouvez l\'interroger sur vos appareils, vos données et vos services.';

  @override
  String get assistantSuggestStatus => 'Est-ce que tout fonctionne normalement ?';

  @override
  String get assistantSuggestDevice => 'À quel point mon appareil est-il sollicité en ce moment ?';

  @override
  String get assistantSuggestHelp => 'En quoi pouvez-vous m\'aider ?';

  @override
  String get assistantSharedModel => 'Tout le monde sur ce déploiement parle à ce modèle.';

  @override
  String get assistantSharedAgent => 'Tout le monde sur ce déploiement parle à cet agent.';

  @override
  String assistantSaveFailed(String error) {
    return 'Impossible de changer d\'assistant : $error';
  }

  @override
  String get assistantErrorUnavailable => 'L\'assistant ne répond pas pour le moment. Réessayez dans un instant.';

  @override
  String get assistantErrorChanged => 'L\'assistant a changé. Commencez une nouvelle conversation pour continuer.';

  @override
  String get assistantErrorGeneric => 'Cela n\'a pas fonctionné. Réessayez.';

  @override
  String get assistantInputUnavailable => 'L\'assistant n\'est pas disponible pour le moment';

  @override
  String get sendTooltip => 'Envoyer';

  @override
  String get stopTooltip => 'Arrêter';

  @override
  String agentUnreachable(String backend) {
    return '$backend ne répond pas';
  }

  @override
  String get agentNoModels => 'Aucun modèle installé';

  @override
  String get agentNoModelsMsg =>
      'Téléchargez-en d\'abord un sur l\'appareil, par ex. `docker exec p4n4-ollama ollama pull llama3.2`.';

  @override
  String get agentNoAgents => 'Pas encore d\'agents';

  @override
  String get agentNoAgentsMsg => 'Créez un agent dans l\'ADE de Letta, puis réessayez.';

  @override
  String agentOllamaMsg(String platform) {
    return 'Les messages sont envoyés à Ollama via $platform-api, avec l\'état actuel de votre système. L\'historique n\'est conservé que pendant cette session.';
  }

  @override
  String get agentLettaMsg => 'Les agents Letta conservent leur propre mémoire d\'une session à l\'autre.';

  @override
  String get agentMessageHint => 'Posez une question… (Maj+Entrée pour aller à la ligne)';

  @override
  String get agentSelectFirst => 'Choisissez d\'abord un modèle ou un agent';

  @override
  String get agentStopped => '(arrêté)';

  @override
  String get agentThinking => 'Réflexion…';

  @override
  String agentStepLookup(String what) {
    return 'Consultation de $what';
  }

  @override
  String get agentStepData => 'Consultation des données';

  @override
  String get agentWriting => 'Rédaction de la réponse…';

  @override
  String agentElapsed(int seconds) {
    return '$seconds s';
  }

  @override
  String agentWaitLast(int seconds) {
    return 'La dernière réponse a pris $seconds s.';
  }

  @override
  String get agentWaitHint => 'Les réponses peuvent prendre jusqu\'à une minute.';

  @override
  String get bubbleYou => 'Vous';

  @override
  String get bubbleAgent => 'Assistant';

  @override
  String get bubbleError => 'Un problème est survenu';

  @override
  String get grafanaDashboards => 'Graphiques';

  @override
  String get reloadTooltip => 'Recharger';

  @override
  String get backTooltip => 'Retour';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String embedUnavailable(String platform) {
    return 'La vue intégrée n\'est pas disponible sur $platform';
  }

  @override
  String get embedUnavailableMsg =>
      'La WebView de Flutter fonctionne sur Android, iOS et macOS. Sur cette plateforme, Grafana s\'ouvre dans votre navigateur par défaut.';

  @override
  String get openGrafana => 'Ouvrir Grafana';

  @override
  String get grafanaUnreachable => 'Grafana ne répond pas';

  @override
  String get dashboardsUnavailable => 'Graphiques indisponibles';

  @override
  String get dashboardsUnavailableMsg =>
      'Les graphiques ne peuvent pas être chargés pour le moment. Réessayez un peu plus tard.';

  @override
  String cameraDefaultName(int n) {
    return 'Caméra $n';
  }

  @override
  String get resumeTooltip => 'Reprendre';

  @override
  String get pauseTooltip => 'Pause';

  @override
  String get reconnectTooltip => 'Reconnecter';

  @override
  String get singleCamera => 'Une caméra';

  @override
  String get allCameras => 'Toutes les caméras';

  @override
  String get editCamera => 'Modifier la caméra';

  @override
  String get addCamera => 'Ajouter une caméra';

  @override
  String get addCameraButton => 'Ajouter une caméra';

  @override
  String get noCameras => 'Aucune caméra';

  @override
  String get noCamerasTechnical =>
      'Ajoutez l\'URL d\'un flux MJPEG, d\'une capture JPEG ou d\'un fichier vidéo de votre caméra edge, ou l\'une des caméras de cet appareil.';

  @override
  String get noCamerasNormie =>
      'Aucune caméra n\'est encore configurée. Demandez à votre administrateur d\'en ajouter une.';

  @override
  String get noCamerasConfigured => 'Aucune caméra configurée';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count caméras', one: '1 caméra');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '« $name » a une URL non valide';
  }

  @override
  String get cameraUrl => 'URL de flux, de capture ou de vidéo, ou caméra de l\'appareil';

  @override
  String get cameraUrlError => 'Saisissez une URL http:// ou https://, device:back ou device:front';

  @override
  String get cameraExamples => 'par ex.';

  @override
  String get cameraReconnecting => 'Reconnexion…';

  @override
  String get cameraStreamEnded => 'Le flux s\'est terminé';

  @override
  String get cameraUnavailable => 'Caméra indisponible';

  @override
  String get cameraLive => 'En direct';

  @override
  String get cameraVideo => 'Vidéo';

  @override
  String get backCamera => 'Caméra arrière';

  @override
  String get frontCamera => 'Caméra avant';

  @override
  String get deviceCameraMissing => 'Cet appareil n\'a pas cette caméra';

  @override
  String get deviceCameraOneAtATime => 'Cet appareil affiche une seule de ses caméras à la fois';

  @override
  String get deviceCameraShow => 'Afficher celle-ci';

  @override
  String deviceCameraUnsupported(String platform) {
    return 'Les caméras de l\'appareil ne fonctionnent pas dans l\'application sur $platform';
  }

  @override
  String get videoDemoSwitch => 'Caméras de démonstration';

  @override
  String get useDemoCameras => 'Utiliser les caméras de démonstration';

  @override
  String get videoDemoCredits =>
      'Images de démonstration : clips de MDN (CC0) ; Big Buck Bunny et Sintel © Blender Foundation (CC BY 3.0).';

  @override
  String videoUnsupported(String platform) {
    return 'Les fichiers vidéo ne se lisent pas dans l\'application sur $platform';
  }

  @override
  String get settingsSearch => 'Rechercher dans les réglages';

  @override
  String settingsNoMatch(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get groupPersonal => 'Personnel';

  @override
  String get groupDeployment => 'Déploiement';

  @override
  String get groupAdmin => 'Administration';

  @override
  String get sectionAccessibility => 'Accessibilité';

  @override
  String get sectionLanguageRegion => 'Langue et région';

  @override
  String get sectionEndpoints => 'Endpoints';

  @override
  String get themeHeading => 'Thème';

  @override
  String get textSize => 'Taille du texte';

  @override
  String textSizeValue(String size) {
    return 'Texte $size';
  }

  @override
  String get textSizePreview => 'Voici à quoi ressemble le texte dans tout le tableau de bord.';

  @override
  String get textSizeSmaller => 'Texte plus petit';

  @override
  String get textSizeLarger => 'Texte plus grand';

  @override
  String get resetToDefault => 'Réinitialiser';

  @override
  String get highContrast => 'Contraste élevé';

  @override
  String get reduceMotion => 'Réduire les animations';

  @override
  String get onInDeviceSettings => 'Activé dans les réglages de votre appareil.';

  @override
  String languageDevice(String language) {
    return 'Comme l\'appareil ($language)';
  }

  @override
  String get searchLanguages => 'Rechercher une langue';

  @override
  String get formatsHeading => 'Formats';

  @override
  String get temperatureUnit => 'Température';

  @override
  String get unitAuto => 'Auto';

  @override
  String get timeFormat => 'Heure';

  @override
  String get time12h => '12 heures';

  @override
  String get time24h => '24 heures';

  @override
  String tourWelcome(String appName) {
    return 'Bienvenue dans $appName ! Voici l\'essentiel.';
  }

  @override
  String get tourNavigation =>
      'Voici vos écrans. Accueil montre comment tout se passe ; touchez un autre écran pour l\'ouvrir.';

  @override
  String get tourTheme => 'Passez d\'un affichage clair à un affichage sombre, ou suivez celui de votre appareil.';

  @override
  String get tourSettings =>
      'La langue, la taille du texte et plus encore se trouvent dans Réglages. Vous pouvez y relancer cette visite.';

  @override
  String get tourSignOut => 'Déconnectez-vous ici quand vous avez terminé.';

  @override
  String tourProgress(Object current, Object total) {
    return '$current sur $total';
  }

  @override
  String get tourNext => 'Suivant';

  @override
  String get tourBack => 'Retour';

  @override
  String get tourDone => 'Compris';

  @override
  String get tourSkip => 'Passer la visite';

  @override
  String get takeTour => 'Faire la visite';

  @override
  String get takeTourSubtitle => 'Un rapide tour du tableau de bord';

  @override
  String get navFeed => 'Activité';

  @override
  String get feedEmpty => 'Rien pour l\'instant';

  @override
  String get feedEmptyMsg => 'Les événements et les alertes apparaissent ici au fur et à mesure.';

  @override
  String get feedNotSetUp => 'Aucune activité';

  @override
  String get feedNotSetUpMsg => 'Cette installation ne publie pas d\'activité.';

  @override
  String get feedNotSetUpTechnical => 'Le projet n\'a pas de feed : ajoutez dashboard.feed à son .p4n4.json.';

  @override
  String get feedUnavailable => 'Impossible de lire l\'activité';

  @override
  String get feedUnavailableMsg => 'Vérifiez que les services de la boutique sont démarrés, puis réessayez.';

  @override
  String feedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count à vérifier', one: '1 à vérifier');
    return '$_temp0';
  }

  @override
  String get feedFilterAll => 'Tout';

  @override
  String get feedFilterAlerts => 'Alertes';

  @override
  String get feedFilterPending => 'À vérifier';

  @override
  String get feedOlder => 'Plus anciens';

  @override
  String feedActionFailed(String error) {
    return 'Impossible : $error';
  }

  @override
  String get feedDemoData => 'Données de démonstration';

  @override
  String get feedStatusPending => 'À vérifier';

  @override
  String get feedStatusAttended => 'Traitée';

  @override
  String get feedStatusDismissed => 'Ignorée';
}
