// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navClients => 'Clients';

  @override
  String get navServices => 'Services';

  @override
  String get navEdge => 'Device';

  @override
  String get navAgent => 'Assistant';

  @override
  String get navGrafana => 'Charts';

  @override
  String get navVideo => 'Cameras';

  @override
  String previewingView(String view) {
    return 'You\'re seeing the dashboard as a $view sees it';
  }

  @override
  String get backToAdmin => 'Back to admin';

  @override
  String themeTooltip(String mode) {
    return 'Theme: $mode';
  }

  @override
  String get themeSystem => 'Match device';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get signOutTooltip => 'Sign out';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePower => 'Power user';

  @override
  String get roleNormie => 'Viewer';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get reset => 'Reset';

  @override
  String get delete => 'Delete';

  @override
  String get clear => 'New conversation';

  @override
  String get open => 'Open';

  @override
  String get connect => 'Connect';

  @override
  String get signOut => 'Sign out';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get healthOnline => 'Online';

  @override
  String get healthOffline => 'Offline';

  @override
  String get healthChecking => 'Checking…';

  @override
  String get healthUnknown => 'Unknown';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldHost => 'Host';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldView => 'View';

  @override
  String hostHelp(String platform) {
    return 'Machine running the $platform stacks. From the Android emulator use 10.0.2.2.';
  }

  @override
  String apiBaseUrl(String platform) {
    return '$platform-api base URL';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return '$platform-api base URL (optional)';
  }

  @override
  String get sessionExpired => 'Your session has expired. Sign in again.';

  @override
  String get signInTag => 'Sign in';

  @override
  String get signInConnecting => 'Connecting…';

  @override
  String get signInWelcome => 'Welcome back';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signInWrongCredentials => 'Wrong username or password.';

  @override
  String get signInRateLimited => 'Too many attempts. Wait a minute and try again.';

  @override
  String signInApiFailed(String platform) {
    return 'Can\'t reach $platform-api. Check the server and try again.';
  }

  @override
  String get signInChooseTitle => 'Choose how to continue';

  @override
  String signInAuthOffNote(String platform) {
    return '$platform-api runs without sign-in (P4N4_API_AUTH=off), so anyone can pick a role.';
  }

  @override
  String get signInOfflineTitle => 'Continue without signing in';

  @override
  String signInOfflineNote(String platform) {
    return 'Without $platform-api, service status comes from port checks and the role is your choice.';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return 'Can\'t reach $platform-api';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return 'Signing in needs $platform-api at $url. Check that it\'s running and reachable from this device, or change the server below.';
  }

  @override
  String get signInOfflineButton => 'Continue without signing in';

  @override
  String get signInDevAccounts => 'Dev accounts';

  @override
  String signInDevAccountsNote(String platform) {
    return 'Needs $platform-api with P4N4_API_DEV_USERS=true';
  }

  @override
  String signInServer(String url) {
    return 'Server: $url';
  }

  @override
  String get signInChangeServer => 'Change';

  @override
  String get roleAdminTitle => 'Administrator';

  @override
  String get roleAdminDesc => 'Everything, plus client deployments, stack controls, users and diagnostics.';

  @override
  String get rolePowerTitle => 'Power user';

  @override
  String get rolePowerDesc => 'Every service and setting, without managing deployments or users.';

  @override
  String get roleNormieTitle => 'Viewer';

  @override
  String get roleNormieDesc => 'System health, charts, cameras and the assistant. Look, but don\'t change settings.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get sectionConnection => 'Connection';

  @override
  String get sectionEdgeMetrics => 'Device readings';

  @override
  String get sectionGrafana => 'Charts';

  @override
  String get sectionVideo => 'Cameras';

  @override
  String get sectionViews => 'Views';

  @override
  String get sectionUsers => 'Users';

  @override
  String get sectionDiagnostics => 'Diagnostics';

  @override
  String get sectionAccount => 'Account';

  @override
  String get sectionAbout => 'About';

  @override
  String get languageSystem => 'Match device';

  @override
  String get fieldDeployment => 'Deployment';

  @override
  String get resetConnection => 'Reset connection to defaults';

  @override
  String get metricsUrl => 'Metrics URL';

  @override
  String get demoData => 'Demo data';

  @override
  String get grafanaBaseUrl => 'Grafana base URL';

  @override
  String get dashboardPath => 'Dashboard path';

  @override
  String get kioskMode => 'Kiosk mode';

  @override
  String viewsSaveFailed(String error) {
    return 'Couldn\'t save the views: $error';
  }

  @override
  String get tabOrder => 'Tab order';

  @override
  String get resetTabOrder => 'Reset order';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String previewView(String view) {
    return 'See as $view';
  }

  @override
  String signedInAs(String user) {
    return 'Signed in as $user';
  }

  @override
  String get signedInWithoutAccount => 'Signed in without an account';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · $platform-api account';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · picked at sign-in';
  }

  @override
  String get licenses => 'Licenses';

  @override
  String usersNote(String platform) {
    return 'Accounts on this deployment\'s $platform-api. Changing a view applies on the user\'s next refresh; resetting a password signs them out.';
  }

  @override
  String usersLoadFailed(String error) {
    return 'Can\'t load users: $error';
  }

  @override
  String get usersOnlyAdmins => 'Only admins can manage users.';

  @override
  String userYou(String user) {
    return '$user (you)';
  }

  @override
  String get resetPasswordTooltip => 'Reset password';

  @override
  String get removeUserTooltip => 'Remove user';

  @override
  String get addUserButton => 'Add user';

  @override
  String get addUserTitle => 'Add user';

  @override
  String get passwordMinLength => 'At least 10 characters';

  @override
  String removeUserTitle(String user) {
    return 'Remove $user?';
  }

  @override
  String get removeUserBody => 'They are signed out everywhere and can\'t sign in again.';

  @override
  String newPasswordTitle(String user) {
    return 'New password for $user';
  }

  @override
  String get newPasswordHelp => 'Signs them out everywhere';

  @override
  String get diagDeployment => 'Deployment';

  @override
  String get diagSignIn => 'Sign-in';

  @override
  String get diagView => 'View';

  @override
  String get diagAuthMode => 'Auth mode';

  @override
  String get diagAccessToken => 'Access token';

  @override
  String get diagRefreshToken => 'Refresh token';

  @override
  String get diagSecureStorage => 'Secure storage';

  @override
  String get diagServices => 'Services';

  @override
  String get diagChecking => 'checking…';

  @override
  String get diagNotChecked => 'not checked';

  @override
  String get diagNoAccount => 'no account';

  @override
  String get diagNone => 'none';

  @override
  String get diagStored => 'stored';

  @override
  String get diagAvailable => 'available';

  @override
  String get diagUnavailable => 'unavailable (memory only)';

  @override
  String diagServicesViaApi(int online, int known) {
    return '$online of $known up via API';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return '$online of $known up via port probes';
  }

  @override
  String get tokenNone => 'none (fetched on the next request)';

  @override
  String tokenExpired(String time) {
    return 'expired at $time';
  }

  @override
  String tokenValid(String time, int minutes) {
    return 'valid until $time ($minutes min)';
  }

  @override
  String get tokenUnreadable => 'present (unreadable)';

  @override
  String get checkSignIn => 'Check sign-in';

  @override
  String get checkServices => 'Check services';

  @override
  String get copySettings => 'Copy settings';

  @override
  String get settingsDump => 'Settings dump';

  @override
  String get secretsHidden => 'Secrets hidden';

  @override
  String get goToTag => 'Go to';

  @override
  String get summaryChecking => 'Checking your system…';

  @override
  String get summaryCheckingSub => 'This takes a few seconds.';

  @override
  String get summaryUnavailable => 'Service status unavailable';

  @override
  String get summaryUnavailableSub =>
      'Your system is responding but didn\'t report service status. Contact your administrator if this persists.';

  @override
  String get summaryUnreachable => 'We can\'t reach your system';

  @override
  String get summaryUnreachableSub => 'Check that the device is on and connected.';

  @override
  String get summaryOk => 'Everything is working';

  @override
  String get summaryOkSub => 'Your system is running normally.';

  @override
  String get summaryAttention => 'Something needs attention';

  @override
  String get summaryAttentionSub =>
      'Part of your system isn\'t working right now. If it doesn\'t recover in a few minutes, contact your administrator.';

  @override
  String summaryAffected(String features) {
    return 'Affected: $features';
  }

  @override
  String summaryUpdated(String time) {
    return 'Checked at $time';
  }

  @override
  String get featureAssistant => 'Assistant';

  @override
  String get featureCharts => 'Charts';

  @override
  String get featureHistory => 'Data history';

  @override
  String get featureSensors => 'Sensor data';

  @override
  String get featureAutomations => 'Automations';

  @override
  String get featureDeviceAi => 'On-device AI';

  @override
  String get featureConnection => 'System connection';

  @override
  String get yourDevice => 'Your device';

  @override
  String get deviceUnavailable => 'Device readings aren\'t available right now.';

  @override
  String get deviceLoading => 'Loading readings…';

  @override
  String get readingProcessor => 'Processor';

  @override
  String get readingMemory => 'Memory';

  @override
  String get readingTemperature => 'Temperature';

  @override
  String get levelNormal => 'Normal';

  @override
  String get levelHigh => 'High';

  @override
  String get levelCritical => 'Very high';

  @override
  String get levelWarm => 'Warm';

  @override
  String get levelHot => 'Hot';

  @override
  String get deviceDetails => 'Details';

  @override
  String get shortcutServicesDesc => 'Open the apps running on your system.';

  @override
  String get shortcutDeviceDesc => 'How hard your device is working, live.';

  @override
  String get shortcutAssistantDesc => 'Ask about your system in plain words.';

  @override
  String get shortcutDashboardsDesc => 'Charts and history from your sensors.';

  @override
  String get shortcutCameraDesc => 'Watch your live camera feeds.';

  @override
  String servicesApiUnreachable(String platform) {
    return 'Can\'t reach $platform-api, so status comes from checking each service\'s port.';
  }

  @override
  String get servicesTitle => 'Services';

  @override
  String servicesSubtitle(String host) {
    return 'The apps running on $host. Open one to use it directly.';
  }

  @override
  String get servicesSubtitlePlain => 'The apps running on your system. Open one to use it.';

  @override
  String servicesLiveFrom(String authority) {
    return 'Live status from $authority';
  }

  @override
  String servicesContacting(String authority) {
    return 'Contacting $authority…';
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
  String get stackControls => 'Stack actions';

  @override
  String get stackStart => 'Start';

  @override
  String get stackRestart => 'Restart';

  @override
  String get stackStop => 'Stop';

  @override
  String stackConfirmStop(String stack) {
    return 'Stop the $stack?';
  }

  @override
  String get stackConfirmStopBody => 'Its services go offline for everyone until someone starts it again.';

  @override
  String stackConfirmRestart(String stack) {
    return 'Restart the $stack?';
  }

  @override
  String get stackConfirmRestartBody => 'Its services go offline for a moment while they restart.';

  @override
  String stackJobRunning(String stack) {
    return 'Working on the $stack…';
  }

  @override
  String stackJobDone(String stack) {
    return 'The $stack is done.';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return 'The $stack action failed: $error';
  }

  @override
  String couldNotOpen(String url) {
    return 'Could not open $url';
  }

  @override
  String get tcpOnly => 'No web page';

  @override
  String get stackIot => 'IoT stack';

  @override
  String get stackAi => 'AI stack';

  @override
  String get stackEdge => 'Edge stack';

  @override
  String get stackApi => 'API gateway';

  @override
  String get serviceGrafanaDesc => 'Dashboards and charts';

  @override
  String get serviceNodeRedDesc => 'Flow automation';

  @override
  String get serviceInfluxDesc => 'Sensor data history';

  @override
  String get serviceMqttDesc => 'Message broker for devices';

  @override
  String get serviceOllamaDesc => 'Local AI models';

  @override
  String get serviceLettaDesc => 'AI agents with memory';

  @override
  String get serviceN8nDesc => 'Workflow automation';

  @override
  String get serviceEiRunnerDesc => 'On-device AI (Edge Impulse)';

  @override
  String get serviceApiDesc => 'One entry point for every stack';

  @override
  String get serviceSwaggerDesc => 'Interactive API docs';

  @override
  String get clientsIntro =>
      'Each deployment\'s status comes from its API, or from checking service ports when the API is down. Connect switches this dashboard, and every connection setting, to that deployment.';

  @override
  String get clientsTitle => 'Client deployments';

  @override
  String get noDeployments => 'No deployments';

  @override
  String get noDeploymentsMsg => 'Add a client deployment by name and host to monitor it here.';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known up';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known up (probed)';
  }

  @override
  String get currentBadge => 'Connected';

  @override
  String get editTooltip => 'Edit';

  @override
  String get removeTooltip => 'Remove';

  @override
  String get removeCurrentTooltip => 'Connect to another deployment to remove this one';

  @override
  String get addDeployment => 'Add deployment';

  @override
  String get editDeployment => 'Edit deployment';

  @override
  String get clientName => 'Client name';

  @override
  String get apiUrlOptional => 'API URL (optional)';

  @override
  String get apiUrlHelp => 'Only if the API isn\'t on port 8000 of the host';

  @override
  String get edgeDemoSwitch => 'Demo data';

  @override
  String get edgeNoMetrics => 'No readings from the device';

  @override
  String edgeFetchFailed(String url, String error) {
    return 'Couldn\'t read $url: $error\n\nPoint the metrics URL in Settings at an endpoint returning the JSON described in the README.';
  }

  @override
  String get edgeUnavailable => 'Device readings are unavailable right now. Try again shortly.';

  @override
  String get edgeSubtitle => 'Live readings from your device, updated every 2 seconds.';

  @override
  String get useDemoData => 'Use demo data';

  @override
  String get edgeStale => 'Not updating';

  @override
  String get edgeDemoLabel => 'Demo data';

  @override
  String get edgeSynthetic => 'Made-up readings for previewing';

  @override
  String get edgeLive => 'Live';

  @override
  String get metricInference => 'AI response time';

  @override
  String get factDisk => 'Storage used';

  @override
  String get factLoad => 'Load average';

  @override
  String get factUptime => 'Running for';

  @override
  String get sparkStart => '2 min ago';

  @override
  String get sparkNow => 'Now';

  @override
  String get agentModel => 'Model';

  @override
  String get agentAgent => 'Agent';

  @override
  String get assistantUnavailable => 'Assistant unavailable';

  @override
  String get assistantUnavailableMsg => 'The assistant isn\'t answering right now. Try again in a little while.';

  @override
  String get assistantNotSetUp => 'No assistant set up';

  @override
  String get assistantNotSetUpMsg => 'Ask your administrator to set one up.';

  @override
  String get assistantChat => 'Ask your assistant';

  @override
  String get assistantChatMsg =>
      'It knows how your system is doing right now, so you can ask about your devices, data and services.';

  @override
  String get assistantSuggestStatus => 'Is everything running normally?';

  @override
  String get assistantSuggestDevice => 'How busy is my device right now?';

  @override
  String get assistantSuggestHelp => 'What can you help me with?';

  @override
  String get assistantSharedModel => 'Everyone on this deployment chats with this model.';

  @override
  String get assistantSharedAgent => 'Everyone on this deployment chats with this agent.';

  @override
  String assistantSaveFailed(String error) {
    return 'Couldn\'t change the assistant: $error';
  }

  @override
  String get assistantErrorUnavailable => 'The assistant isn\'t answering right now. Try again in a moment.';

  @override
  String get assistantErrorChanged => 'The assistant was changed. Start a new conversation to keep chatting.';

  @override
  String get assistantErrorGeneric => 'That didn\'t work. Try again.';

  @override
  String get assistantInputUnavailable => 'The assistant isn\'t available right now';

  @override
  String get sendTooltip => 'Send';

  @override
  String get stopTooltip => 'Stop';

  @override
  String agentUnreachable(String backend) {
    return '$backend isn\'t answering';
  }

  @override
  String get agentNoModels => 'No models installed';

  @override
  String get agentNoModelsMsg =>
      'Download one on the device first, e.g. `docker exec p4n4-ollama ollama pull llama3.2`.';

  @override
  String get agentNoAgents => 'No agents yet';

  @override
  String get agentNoAgentsMsg => 'Create an agent in the Letta ADE, then retry.';

  @override
  String agentOllamaMsg(String platform) {
    return 'Messages go to Ollama through $platform-api, with your system\'s current status. History stays in this session only.';
  }

  @override
  String get agentLettaMsg => 'Letta agents keep their own memory across sessions.';

  @override
  String get agentMessageHint => 'Ask a question… (Shift+Enter for a new line)';

  @override
  String get agentSelectFirst => 'Choose a model or agent first';

  @override
  String get agentStopped => '(stopped)';

  @override
  String get bubbleYou => 'You';

  @override
  String get bubbleAgent => 'Assistant';

  @override
  String get bubbleError => 'Something went wrong';

  @override
  String get grafanaDashboards => 'Charts';

  @override
  String get reloadTooltip => 'Reload';

  @override
  String get backTooltip => 'Back';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String embedUnavailable(String platform) {
    return 'Embedded view not available on $platform';
  }

  @override
  String get embedUnavailableMsg =>
      'Flutter\'s WebView supports Android, iOS and macOS. On this platform Grafana opens in your default browser.';

  @override
  String get openGrafana => 'Open Grafana';

  @override
  String get grafanaUnreachable => 'Grafana unreachable';

  @override
  String get dashboardsUnavailable => 'Charts unavailable';

  @override
  String get dashboardsUnavailableMsg => 'Charts can\'t be loaded right now. Try again in a little while.';

  @override
  String cameraDefaultName(int n) {
    return 'Camera $n';
  }

  @override
  String get resumeTooltip => 'Resume';

  @override
  String get pauseTooltip => 'Pause';

  @override
  String get reconnectTooltip => 'Reconnect';

  @override
  String get singleCamera => 'Single camera';

  @override
  String get allCameras => 'All cameras';

  @override
  String get editCamera => 'Edit camera';

  @override
  String get addCamera => 'Add camera';

  @override
  String get addCameraButton => 'Add camera';

  @override
  String get noCameras => 'No cameras';

  @override
  String get noCamerasTechnical => 'Add the URL of an MJPEG stream, JPEG snapshot or video file from your edge camera.';

  @override
  String get noCamerasNormie => 'No camera has been set up yet. Ask your administrator to add one.';

  @override
  String get noCamerasConfigured => 'No cameras set up';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count cameras', one: '1 camera');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '\"$name\" has an invalid URL';
  }

  @override
  String get cameraUrl => 'Stream, snapshot or video URL';

  @override
  String get cameraUrlError => 'Enter an http:// or https:// URL';

  @override
  String get cameraExamples => 'e.g.';

  @override
  String get cameraReconnecting => 'Reconnecting…';

  @override
  String get cameraStreamEnded => 'Stream ended';

  @override
  String get cameraUnavailable => 'Camera unavailable';

  @override
  String get cameraLive => 'Live';

  @override
  String get cameraVideo => 'Video';

  @override
  String get videoDemoSwitch => 'Demo cameras';

  @override
  String get useDemoCameras => 'Use demo cameras';

  @override
  String get videoDemoCredits =>
      'Demo footage: clips from MDN (CC0); Big Buck Bunny and Sintel © Blender Foundation (CC BY 3.0).';

  @override
  String videoUnsupported(String platform) {
    return 'Video files don\'t play in the app on $platform';
  }

  @override
  String get settingsSearch => 'Search settings';

  @override
  String settingsNoMatch(String query) {
    return 'Nothing matches \"$query\"';
  }

  @override
  String get groupPersonal => 'Personal';

  @override
  String get groupDeployment => 'Deployment';

  @override
  String get groupAdmin => 'Administration';

  @override
  String get sectionAccessibility => 'Accessibility';

  @override
  String get sectionLanguageRegion => 'Language & region';

  @override
  String get sectionEndpoints => 'Endpoints';

  @override
  String get themeHeading => 'Theme';

  @override
  String get textSize => 'Text size';

  @override
  String textSizeValue(String size) {
    return 'Text $size';
  }

  @override
  String get textSizePreview => 'This is how text looks across the dashboard.';

  @override
  String get textSizeSmaller => 'Smaller text';

  @override
  String get textSizeLarger => 'Larger text';

  @override
  String get resetToDefault => 'Reset';

  @override
  String get highContrast => 'High contrast';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get onInDeviceSettings => 'On in your device\'s settings.';

  @override
  String languageDevice(String language) {
    return 'Match device ($language)';
  }

  @override
  String get searchLanguages => 'Search languages';

  @override
  String get formatsHeading => 'Formats';

  @override
  String get temperatureUnit => 'Temperature';

  @override
  String get unitAuto => 'Auto';

  @override
  String get timeFormat => 'Time';

  @override
  String get time12h => '12-hour';

  @override
  String get time24h => '24-hour';

  @override
  String tourWelcome(String appName) {
    return 'Welcome to $appName! Here\'s a quick look around.';
  }

  @override
  String get tourNavigation =>
      'Your screens are here. Home shows how everything is doing; tap another screen to open it.';

  @override
  String get tourTheme => 'Switch between a light and a dark look, or match your device.';

  @override
  String get tourSettings => 'Language, text size and more are in Settings. You can take this tour again from there.';

  @override
  String get tourSignOut => 'Sign out here when you\'re done.';

  @override
  String tourProgress(Object current, Object total) {
    return '$current of $total';
  }

  @override
  String get tourNext => 'Next';

  @override
  String get tourBack => 'Back';

  @override
  String get tourDone => 'Got it';

  @override
  String get tourSkip => 'Skip tour';

  @override
  String get takeTour => 'Take the tour';

  @override
  String get takeTourSubtitle => 'A quick look around the dashboard';
}
