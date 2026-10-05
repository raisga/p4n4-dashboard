import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es')];

  /// Navigation destination
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get navClients;

  /// No description provided for @navServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navServices;

  /// No description provided for @navEdge.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get navEdge;

  /// No description provided for @navAgent.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAgent;

  /// No description provided for @navGrafana.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get navGrafana;

  /// No description provided for @navVideo.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get navVideo;

  /// Banner while an admin previews another view; {view} is a role name
  ///
  /// In en, this message translates to:
  /// **'You\'re seeing the dashboard as a {view} sees it'**
  String previewingView(String view);

  /// No description provided for @backToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Back to admin'**
  String get backToAdmin;

  /// {mode} is themeSystem, themeLight or themeDark
  ///
  /// In en, this message translates to:
  /// **'Theme: {mode}'**
  String themeTooltip(String mode);

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @signOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutTooltip;

  /// The administrator view; shown in badges and menus
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// The power-user view
  ///
  /// In en, this message translates to:
  /// **'Power user'**
  String get rolePower;

  /// The non-technical, read-only view (role 'normie' in the API)
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleNormie;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get clear;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// Service status
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get healthOnline;

  /// No description provided for @healthOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get healthOffline;

  /// No description provided for @healthChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get healthChecking;

  /// No description provided for @healthUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get healthUnknown;

  /// No description provided for @fieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get fieldUsername;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get fieldHost;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// A user's dashboard view (role)
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get fieldView;

  /// {platform} is the brand's platform name, e.g. p4n4
  ///
  /// In en, this message translates to:
  /// **'Machine running the {platform} stacks. From the Android emulator use 10.0.2.2.'**
  String hostHelp(String platform);

  /// No description provided for @apiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'{platform}-api base URL'**
  String apiBaseUrl(String platform);

  /// No description provided for @apiBaseUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'{platform}-api base URL (optional)'**
  String apiBaseUrlOptional(String platform);

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again.'**
  String get sessionExpired;

  /// Section tag above the sign-in forms
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTag;

  /// No description provided for @signInConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get signInConnecting;

  /// No description provided for @signInWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInWelcome;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @signInWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password.'**
  String get signInWrongCredentials;

  /// No description provided for @signInRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again.'**
  String get signInRateLimited;

  /// No description provided for @signInApiFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {platform}-api. Check the server and try again.'**
  String signInApiFailed(String platform);

  /// No description provided for @signInChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how to continue'**
  String get signInChooseTitle;

  /// No description provided for @signInAuthOffNote.
  ///
  /// In en, this message translates to:
  /// **'{platform}-api runs without sign-in (P4N4_API_AUTH=off), so anyone can pick a role.'**
  String signInAuthOffNote(String platform);

  /// No description provided for @signInOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue without signing in'**
  String get signInOfflineTitle;

  /// No description provided for @signInOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Without {platform}-api, service status comes from port checks and the role is your choice.'**
  String signInOfflineNote(String platform);

  /// No description provided for @signInUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {platform}-api'**
  String signInUnreachableTitle(String platform);

  /// No description provided for @signInUnreachableBody.
  ///
  /// In en, this message translates to:
  /// **'Signing in needs {platform}-api at {url}. Check that it\'s running and reachable from this device, or change the server below.'**
  String signInUnreachableBody(String platform, String url);

  /// No description provided for @signInOfflineButton.
  ///
  /// In en, this message translates to:
  /// **'Continue without signing in'**
  String get signInOfflineButton;

  /// No description provided for @signInDevAccounts.
  ///
  /// In en, this message translates to:
  /// **'Dev accounts'**
  String get signInDevAccounts;

  /// No description provided for @signInDevAccountsNote.
  ///
  /// In en, this message translates to:
  /// **'Needs {platform}-api with P4N4_API_DEV_USERS=true'**
  String signInDevAccountsNote(String platform);

  /// No description provided for @signInServer.
  ///
  /// In en, this message translates to:
  /// **'Server: {url}'**
  String signInServer(String url);

  /// No description provided for @signInChangeServer.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get signInChangeServer;

  /// No description provided for @roleAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdminTitle;

  /// No description provided for @roleAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Everything, plus client deployments, stack controls, users and diagnostics.'**
  String get roleAdminDesc;

  /// No description provided for @rolePowerTitle.
  ///
  /// In en, this message translates to:
  /// **'Power user'**
  String get rolePowerTitle;

  /// No description provided for @rolePowerDesc.
  ///
  /// In en, this message translates to:
  /// **'Every service and setting, without managing deployments or users.'**
  String get rolePowerDesc;

  /// No description provided for @roleNormieTitle.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleNormieTitle;

  /// No description provided for @roleNormieDesc.
  ///
  /// In en, this message translates to:
  /// **'System health, charts, cameras and the assistant. Look, but don\'t change settings.'**
  String get roleNormieDesc;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @sectionConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get sectionConnection;

  /// No description provided for @sectionEdgeMetrics.
  ///
  /// In en, this message translates to:
  /// **'Device readings'**
  String get sectionEdgeMetrics;

  /// No description provided for @sectionGrafana.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get sectionGrafana;

  /// No description provided for @sectionVideo.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get sectionVideo;

  /// No description provided for @sectionViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get sectionViews;

  /// No description provided for @sectionUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get sectionUsers;

  /// No description provided for @sectionDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get sectionDiagnostics;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// Follow the device language
  ///
  /// In en, this message translates to:
  /// **'Match device'**
  String get languageSystem;

  /// No description provided for @fieldDeployment.
  ///
  /// In en, this message translates to:
  /// **'Deployment'**
  String get fieldDeployment;

  /// No description provided for @resetConnection.
  ///
  /// In en, this message translates to:
  /// **'Reset connection to defaults'**
  String get resetConnection;

  /// No description provided for @metricsUrl.
  ///
  /// In en, this message translates to:
  /// **'Metrics URL'**
  String get metricsUrl;

  /// No description provided for @demoData.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get demoData;

  /// No description provided for @grafanaBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Grafana base URL'**
  String get grafanaBaseUrl;

  /// No description provided for @dashboardPath.
  ///
  /// In en, this message translates to:
  /// **'Dashboard path'**
  String get dashboardPath;

  /// No description provided for @kioskMode.
  ///
  /// In en, this message translates to:
  /// **'Kiosk mode'**
  String get kioskMode;

  /// No description provided for @viewsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the views: {error}'**
  String viewsSaveFailed(String error);

  /// Settings → Views: heading of the drag-to-reorder tab list
  ///
  /// In en, this message translates to:
  /// **'Tab order'**
  String get tabOrder;

  /// No description provided for @resetTabOrder.
  ///
  /// In en, this message translates to:
  /// **'Reset order'**
  String get resetTabOrder;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// Button that shows the dashboard as another view would; {view} is a role name
  ///
  /// In en, this message translates to:
  /// **'See as {view}'**
  String previewView(String view);

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {user}'**
  String signedInAs(String user);

  /// No description provided for @signedInWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Signed in without an account'**
  String get signedInWithoutAccount;

  /// No description provided for @accountViewApi.
  ///
  /// In en, this message translates to:
  /// **'{view} · {platform}-api account'**
  String accountViewApi(String view, String platform);

  /// No description provided for @accountViewLocal.
  ///
  /// In en, this message translates to:
  /// **'{view} · picked at sign-in'**
  String accountViewLocal(String view);

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @usersNote.
  ///
  /// In en, this message translates to:
  /// **'Accounts on this deployment\'s {platform}-api. Changing a view applies on the user\'s next refresh; resetting a password signs them out.'**
  String usersNote(String platform);

  /// No description provided for @usersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t load users: {error}'**
  String usersLoadFailed(String error);

  /// No description provided for @usersOnlyAdmins.
  ///
  /// In en, this message translates to:
  /// **'Only admins can manage users.'**
  String get usersOnlyAdmins;

  /// No description provided for @userYou.
  ///
  /// In en, this message translates to:
  /// **'{user} (you)'**
  String userYou(String user);

  /// No description provided for @resetPasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTooltip;

  /// No description provided for @removeUserTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove user'**
  String get removeUserTooltip;

  /// No description provided for @addUserButton.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUserButton;

  /// No description provided for @addUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUserTitle;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters'**
  String get passwordMinLength;

  /// No description provided for @removeUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {user}?'**
  String removeUserTitle(String user);

  /// No description provided for @removeUserBody.
  ///
  /// In en, this message translates to:
  /// **'They are signed out everywhere and can\'t sign in again.'**
  String get removeUserBody;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New password for {user}'**
  String newPasswordTitle(String user);

  /// No description provided for @newPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Signs them out everywhere'**
  String get newPasswordHelp;

  /// Diagnostics row label
  ///
  /// In en, this message translates to:
  /// **'Deployment'**
  String get diagDeployment;

  /// No description provided for @diagSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get diagSignIn;

  /// No description provided for @diagView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get diagView;

  /// No description provided for @diagAuthMode.
  ///
  /// In en, this message translates to:
  /// **'Auth mode'**
  String get diagAuthMode;

  /// No description provided for @diagAccessToken.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get diagAccessToken;

  /// No description provided for @diagRefreshToken.
  ///
  /// In en, this message translates to:
  /// **'Refresh token'**
  String get diagRefreshToken;

  /// No description provided for @diagSecureStorage.
  ///
  /// In en, this message translates to:
  /// **'Secure storage'**
  String get diagSecureStorage;

  /// No description provided for @diagServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get diagServices;

  /// No description provided for @diagChecking.
  ///
  /// In en, this message translates to:
  /// **'checking…'**
  String get diagChecking;

  /// No description provided for @diagNotChecked.
  ///
  /// In en, this message translates to:
  /// **'not checked'**
  String get diagNotChecked;

  /// No description provided for @diagNoAccount.
  ///
  /// In en, this message translates to:
  /// **'no account'**
  String get diagNoAccount;

  /// No description provided for @diagNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get diagNone;

  /// No description provided for @diagStored.
  ///
  /// In en, this message translates to:
  /// **'stored'**
  String get diagStored;

  /// No description provided for @diagAvailable.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get diagAvailable;

  /// No description provided for @diagUnavailable.
  ///
  /// In en, this message translates to:
  /// **'unavailable (memory only)'**
  String get diagUnavailable;

  /// No description provided for @diagServicesViaApi.
  ///
  /// In en, this message translates to:
  /// **'{online} of {known} up via API'**
  String diagServicesViaApi(int online, int known);

  /// No description provided for @diagServicesViaProbes.
  ///
  /// In en, this message translates to:
  /// **'{online} of {known} up via port probes'**
  String diagServicesViaProbes(int online, int known);

  /// No description provided for @tokenNone.
  ///
  /// In en, this message translates to:
  /// **'none (fetched on the next request)'**
  String get tokenNone;

  /// No description provided for @tokenExpired.
  ///
  /// In en, this message translates to:
  /// **'expired at {time}'**
  String tokenExpired(String time);

  /// No description provided for @tokenValid.
  ///
  /// In en, this message translates to:
  /// **'valid until {time} ({minutes} min)'**
  String tokenValid(String time, int minutes);

  /// No description provided for @tokenUnreadable.
  ///
  /// In en, this message translates to:
  /// **'present (unreadable)'**
  String get tokenUnreadable;

  /// No description provided for @checkSignIn.
  ///
  /// In en, this message translates to:
  /// **'Check sign-in'**
  String get checkSignIn;

  /// No description provided for @checkServices.
  ///
  /// In en, this message translates to:
  /// **'Check services'**
  String get checkServices;

  /// No description provided for @copySettings.
  ///
  /// In en, this message translates to:
  /// **'Copy settings'**
  String get copySettings;

  /// No description provided for @settingsDump.
  ///
  /// In en, this message translates to:
  /// **'Settings dump'**
  String get settingsDump;

  /// No description provided for @secretsHidden.
  ///
  /// In en, this message translates to:
  /// **'Secrets hidden'**
  String get secretsHidden;

  /// No description provided for @goToTag.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get goToTag;

  /// No description provided for @summaryChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your system…'**
  String get summaryChecking;

  /// No description provided for @summaryCheckingSub.
  ///
  /// In en, this message translates to:
  /// **'This takes a few seconds.'**
  String get summaryCheckingSub;

  /// No description provided for @summaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service status unavailable'**
  String get summaryUnavailable;

  /// No description provided for @summaryUnavailableSub.
  ///
  /// In en, this message translates to:
  /// **'Your system is responding but didn\'t report service status. Contact your administrator if this persists.'**
  String get summaryUnavailableSub;

  /// No description provided for @summaryUnreachable.
  ///
  /// In en, this message translates to:
  /// **'We can\'t reach your system'**
  String get summaryUnreachable;

  /// No description provided for @summaryUnreachableSub.
  ///
  /// In en, this message translates to:
  /// **'Check that the device is on and connected.'**
  String get summaryUnreachableSub;

  /// No description provided for @summaryOk.
  ///
  /// In en, this message translates to:
  /// **'Everything is working'**
  String get summaryOk;

  /// No description provided for @summaryOkSub.
  ///
  /// In en, this message translates to:
  /// **'Your system is running normally.'**
  String get summaryOkSub;

  /// No description provided for @summaryAttention.
  ///
  /// In en, this message translates to:
  /// **'Something needs attention'**
  String get summaryAttention;

  /// No description provided for @summaryAttentionSub.
  ///
  /// In en, this message translates to:
  /// **'Part of your system isn\'t working right now. If it doesn\'t recover in a few minutes, contact your administrator.'**
  String get summaryAttentionSub;

  /// No description provided for @summaryAffected.
  ///
  /// In en, this message translates to:
  /// **'Affected: {features}'**
  String summaryAffected(String features);

  /// No description provided for @summaryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Checked at {time}'**
  String summaryUpdated(String time);

  /// No description provided for @featureAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get featureAssistant;

  /// No description provided for @featureCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get featureCharts;

  /// No description provided for @featureHistory.
  ///
  /// In en, this message translates to:
  /// **'Data history'**
  String get featureHistory;

  /// No description provided for @featureSensors.
  ///
  /// In en, this message translates to:
  /// **'Sensor data'**
  String get featureSensors;

  /// No description provided for @featureAutomations.
  ///
  /// In en, this message translates to:
  /// **'Automations'**
  String get featureAutomations;

  /// No description provided for @featureDeviceAi.
  ///
  /// In en, this message translates to:
  /// **'On-device AI'**
  String get featureDeviceAi;

  /// No description provided for @featureConnection.
  ///
  /// In en, this message translates to:
  /// **'System connection'**
  String get featureConnection;

  /// No description provided for @yourDevice.
  ///
  /// In en, this message translates to:
  /// **'Your device'**
  String get yourDevice;

  /// No description provided for @deviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device readings aren\'t available right now.'**
  String get deviceUnavailable;

  /// No description provided for @deviceLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading readings…'**
  String get deviceLoading;

  /// No description provided for @readingProcessor.
  ///
  /// In en, this message translates to:
  /// **'Processor'**
  String get readingProcessor;

  /// No description provided for @readingMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get readingMemory;

  /// No description provided for @readingTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get readingTemperature;

  /// No description provided for @levelNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get levelNormal;

  /// No description provided for @levelHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get levelHigh;

  /// No description provided for @levelCritical.
  ///
  /// In en, this message translates to:
  /// **'Very high'**
  String get levelCritical;

  /// No description provided for @levelWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get levelWarm;

  /// No description provided for @levelHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get levelHot;

  /// No description provided for @deviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get deviceDetails;

  /// No description provided for @shortcutServicesDesc.
  ///
  /// In en, this message translates to:
  /// **'Open the apps running on your system.'**
  String get shortcutServicesDesc;

  /// No description provided for @shortcutDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'How hard your device is working, live.'**
  String get shortcutDeviceDesc;

  /// No description provided for @shortcutAssistantDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask about your system in plain words.'**
  String get shortcutAssistantDesc;

  /// No description provided for @shortcutDashboardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Charts and history from your sensors.'**
  String get shortcutDashboardsDesc;

  /// No description provided for @shortcutCameraDesc.
  ///
  /// In en, this message translates to:
  /// **'Watch your live camera feeds.'**
  String get shortcutCameraDesc;

  /// No description provided for @servicesApiUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {platform}-api, so status comes from checking each service\'s port.'**
  String servicesApiUnreachable(String platform);

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// No description provided for @servicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The apps running on {host}. Open one to use it directly.'**
  String servicesSubtitle(String host);

  /// No description provided for @servicesSubtitlePlain.
  ///
  /// In en, this message translates to:
  /// **'The apps running on your system. Open one to use it.'**
  String get servicesSubtitlePlain;

  /// No description provided for @servicesLiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Live status from {authority}'**
  String servicesLiveFrom(String authority);

  /// No description provided for @servicesContacting.
  ///
  /// In en, this message translates to:
  /// **'Contacting {authority}…'**
  String servicesContacting(String authority);

  /// No description provided for @serviceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 service} other{{count} services}}'**
  String serviceCount(int count);

  /// No description provided for @endpointCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 endpoint} other{{count} endpoints}}'**
  String endpointCount(int count);

  /// No description provided for @stackControls.
  ///
  /// In en, this message translates to:
  /// **'Stack actions'**
  String get stackControls;

  /// No description provided for @stackStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get stackStart;

  /// No description provided for @stackRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get stackRestart;

  /// No description provided for @stackStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stackStop;

  /// No description provided for @stackConfirmStop.
  ///
  /// In en, this message translates to:
  /// **'Stop the {stack}?'**
  String stackConfirmStop(String stack);

  /// No description provided for @stackConfirmStopBody.
  ///
  /// In en, this message translates to:
  /// **'Its services go offline for everyone until someone starts it again.'**
  String get stackConfirmStopBody;

  /// No description provided for @stackConfirmRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart the {stack}?'**
  String stackConfirmRestart(String stack);

  /// No description provided for @stackConfirmRestartBody.
  ///
  /// In en, this message translates to:
  /// **'Its services go offline for a moment while they restart.'**
  String get stackConfirmRestartBody;

  /// No description provided for @stackJobRunning.
  ///
  /// In en, this message translates to:
  /// **'Working on the {stack}…'**
  String stackJobRunning(String stack);

  /// No description provided for @stackJobDone.
  ///
  /// In en, this message translates to:
  /// **'The {stack} is done.'**
  String stackJobDone(String stack);

  /// No description provided for @stackJobFailed.
  ///
  /// In en, this message translates to:
  /// **'The {stack} action failed: {error}'**
  String stackJobFailed(String stack, String error);

  /// No description provided for @couldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String couldNotOpen(String url);

  /// No description provided for @tcpOnly.
  ///
  /// In en, this message translates to:
  /// **'No web page'**
  String get tcpOnly;

  /// No description provided for @stackIot.
  ///
  /// In en, this message translates to:
  /// **'IoT stack'**
  String get stackIot;

  /// No description provided for @stackAi.
  ///
  /// In en, this message translates to:
  /// **'AI stack'**
  String get stackAi;

  /// No description provided for @stackEdge.
  ///
  /// In en, this message translates to:
  /// **'Edge stack'**
  String get stackEdge;

  /// No description provided for @stackApi.
  ///
  /// In en, this message translates to:
  /// **'API gateway'**
  String get stackApi;

  /// No description provided for @serviceGrafanaDesc.
  ///
  /// In en, this message translates to:
  /// **'Dashboards and charts'**
  String get serviceGrafanaDesc;

  /// No description provided for @serviceNodeRedDesc.
  ///
  /// In en, this message translates to:
  /// **'Flow automation'**
  String get serviceNodeRedDesc;

  /// No description provided for @serviceInfluxDesc.
  ///
  /// In en, this message translates to:
  /// **'Sensor data history'**
  String get serviceInfluxDesc;

  /// No description provided for @serviceMqttDesc.
  ///
  /// In en, this message translates to:
  /// **'Message broker for devices'**
  String get serviceMqttDesc;

  /// No description provided for @serviceOllamaDesc.
  ///
  /// In en, this message translates to:
  /// **'Local AI models'**
  String get serviceOllamaDesc;

  /// No description provided for @serviceLettaDesc.
  ///
  /// In en, this message translates to:
  /// **'AI agents with memory'**
  String get serviceLettaDesc;

  /// No description provided for @serviceN8nDesc.
  ///
  /// In en, this message translates to:
  /// **'Workflow automation'**
  String get serviceN8nDesc;

  /// No description provided for @serviceEiRunnerDesc.
  ///
  /// In en, this message translates to:
  /// **'On-device AI (Edge Impulse)'**
  String get serviceEiRunnerDesc;

  /// No description provided for @serviceApiDesc.
  ///
  /// In en, this message translates to:
  /// **'One entry point for every stack'**
  String get serviceApiDesc;

  /// No description provided for @serviceSwaggerDesc.
  ///
  /// In en, this message translates to:
  /// **'Interactive API docs'**
  String get serviceSwaggerDesc;

  /// No description provided for @clientsIntro.
  ///
  /// In en, this message translates to:
  /// **'Each deployment\'s status comes from its API, or from checking service ports when the API is down. Connect switches this dashboard, and every connection setting, to that deployment.'**
  String get clientsIntro;

  /// No description provided for @clientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Client deployments'**
  String get clientsTitle;

  /// No description provided for @noDeployments.
  ///
  /// In en, this message translates to:
  /// **'No deployments'**
  String get noDeployments;

  /// No description provided for @noDeploymentsMsg.
  ///
  /// In en, this message translates to:
  /// **'Add a client deployment by name and host to monitor it here.'**
  String get noDeploymentsMsg;

  /// No description provided for @clientsUp.
  ///
  /// In en, this message translates to:
  /// **'{online}/{known} up'**
  String clientsUp(int online, int known);

  /// No description provided for @clientsUpProbed.
  ///
  /// In en, this message translates to:
  /// **'{online}/{known} up (probed)'**
  String clientsUpProbed(int online, int known);

  /// No description provided for @currentBadge.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get currentBadge;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @removeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeTooltip;

  /// No description provided for @removeCurrentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Connect to another deployment to remove this one'**
  String get removeCurrentTooltip;

  /// No description provided for @addDeployment.
  ///
  /// In en, this message translates to:
  /// **'Add deployment'**
  String get addDeployment;

  /// No description provided for @editDeployment.
  ///
  /// In en, this message translates to:
  /// **'Edit deployment'**
  String get editDeployment;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client name'**
  String get clientName;

  /// No description provided for @apiUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'API URL (optional)'**
  String get apiUrlOptional;

  /// No description provided for @apiUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'Only if the API isn\'t on port 8000 of the host'**
  String get apiUrlHelp;

  /// No description provided for @edgeDemoSwitch.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get edgeDemoSwitch;

  /// No description provided for @edgeNoMetrics.
  ///
  /// In en, this message translates to:
  /// **'No readings from the device'**
  String get edgeNoMetrics;

  /// No description provided for @edgeFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read {url}: {error}\n\nPoint the metrics URL in Settings at an endpoint returning the JSON described in the README.'**
  String edgeFetchFailed(String url, String error);

  /// No description provided for @edgeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device readings are unavailable right now. Try again shortly.'**
  String get edgeUnavailable;

  /// No description provided for @edgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live readings from your device, updated every 2 seconds.'**
  String get edgeSubtitle;

  /// No description provided for @useDemoData.
  ///
  /// In en, this message translates to:
  /// **'Use demo data'**
  String get useDemoData;

  /// No description provided for @edgeStale.
  ///
  /// In en, this message translates to:
  /// **'Not updating'**
  String get edgeStale;

  /// No description provided for @edgeDemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get edgeDemoLabel;

  /// No description provided for @edgeSynthetic.
  ///
  /// In en, this message translates to:
  /// **'Made-up readings for previewing'**
  String get edgeSynthetic;

  /// No description provided for @edgeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get edgeLive;

  /// No description provided for @metricInference.
  ///
  /// In en, this message translates to:
  /// **'AI response time'**
  String get metricInference;

  /// No description provided for @factDisk.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get factDisk;

  /// No description provided for @factLoad.
  ///
  /// In en, this message translates to:
  /// **'Load average'**
  String get factLoad;

  /// No description provided for @factUptime.
  ///
  /// In en, this message translates to:
  /// **'Running for'**
  String get factUptime;

  /// Left end of a two-minute sparkline
  ///
  /// In en, this message translates to:
  /// **'2 min ago'**
  String get sparkStart;

  /// Right end of a sparkline
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get sparkNow;

  /// No description provided for @agentModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get agentModel;

  /// No description provided for @agentAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agentAgent;

  /// No description provided for @assistantUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Assistant unavailable'**
  String get assistantUnavailable;

  /// No description provided for @assistantUnavailableMsg.
  ///
  /// In en, this message translates to:
  /// **'The assistant isn\'t answering right now. Try again in a little while.'**
  String get assistantUnavailableMsg;

  /// No description provided for @assistantNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'No assistant set up'**
  String get assistantNotSetUp;

  /// No description provided for @assistantNotSetUpMsg.
  ///
  /// In en, this message translates to:
  /// **'Ask your administrator to set one up.'**
  String get assistantNotSetUpMsg;

  /// No description provided for @assistantChat.
  ///
  /// In en, this message translates to:
  /// **'Ask your assistant'**
  String get assistantChat;

  /// No description provided for @assistantChatMsg.
  ///
  /// In en, this message translates to:
  /// **'It knows how your system is doing right now, so you can ask about your devices, data and services.'**
  String get assistantChatMsg;

  /// No description provided for @assistantSuggestStatus.
  ///
  /// In en, this message translates to:
  /// **'Is everything running normally?'**
  String get assistantSuggestStatus;

  /// No description provided for @assistantSuggestDevice.
  ///
  /// In en, this message translates to:
  /// **'How busy is my device right now?'**
  String get assistantSuggestDevice;

  /// No description provided for @assistantSuggestHelp.
  ///
  /// In en, this message translates to:
  /// **'What can you help me with?'**
  String get assistantSuggestHelp;

  /// No description provided for @assistantSharedModel.
  ///
  /// In en, this message translates to:
  /// **'Everyone on this deployment chats with this model.'**
  String get assistantSharedModel;

  /// No description provided for @assistantSharedAgent.
  ///
  /// In en, this message translates to:
  /// **'Everyone on this deployment chats with this agent.'**
  String get assistantSharedAgent;

  /// No description provided for @assistantSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the assistant: {error}'**
  String assistantSaveFailed(String error);

  /// No description provided for @assistantErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The assistant isn\'t answering right now. Try again in a moment.'**
  String get assistantErrorUnavailable;

  /// No description provided for @assistantErrorChanged.
  ///
  /// In en, this message translates to:
  /// **'The assistant was changed. Start a new conversation to keep chatting.'**
  String get assistantErrorChanged;

  /// No description provided for @assistantErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Try again.'**
  String get assistantErrorGeneric;

  /// No description provided for @assistantInputUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The assistant isn\'t available right now'**
  String get assistantInputUnavailable;

  /// No description provided for @sendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendTooltip;

  /// No description provided for @stopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopTooltip;

  /// No description provided for @agentUnreachable.
  ///
  /// In en, this message translates to:
  /// **'{backend} isn\'t answering'**
  String agentUnreachable(String backend);

  /// No description provided for @agentNoModels.
  ///
  /// In en, this message translates to:
  /// **'No models installed'**
  String get agentNoModels;

  /// No description provided for @agentNoModelsMsg.
  ///
  /// In en, this message translates to:
  /// **'Download one on the device first, e.g. `docker exec p4n4-ollama ollama pull llama3.2`.'**
  String get agentNoModelsMsg;

  /// No description provided for @agentNoAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents yet'**
  String get agentNoAgents;

  /// No description provided for @agentNoAgentsMsg.
  ///
  /// In en, this message translates to:
  /// **'Create an agent in the Letta ADE, then retry.'**
  String get agentNoAgentsMsg;

  /// No description provided for @agentOllamaMsg.
  ///
  /// In en, this message translates to:
  /// **'Messages go to Ollama through {platform}-api, with your system\'s current status. History stays in this session only.'**
  String agentOllamaMsg(String platform);

  /// No description provided for @agentLettaMsg.
  ///
  /// In en, this message translates to:
  /// **'Letta agents keep their own memory across sessions.'**
  String get agentLettaMsg;

  /// No description provided for @agentMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a question… (Shift+Enter for a new line)'**
  String get agentMessageHint;

  /// No description provided for @agentSelectFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a model or agent first'**
  String get agentSelectFirst;

  /// No description provided for @agentStopped.
  ///
  /// In en, this message translates to:
  /// **'(stopped)'**
  String get agentStopped;

  /// Chat bubble author
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get bubbleYou;

  /// No description provided for @bubbleAgent.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get bubbleAgent;

  /// No description provided for @bubbleError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get bubbleError;

  /// No description provided for @grafanaDashboards.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get grafanaDashboards;

  /// No description provided for @reloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reloadTooltip;

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// {platform} is an OS name, e.g. linux
  ///
  /// In en, this message translates to:
  /// **'Embedded view not available on {platform}'**
  String embedUnavailable(String platform);

  /// No description provided for @embedUnavailableMsg.
  ///
  /// In en, this message translates to:
  /// **'Flutter\'s WebView supports Android, iOS and macOS. On this platform Grafana opens in your default browser.'**
  String get embedUnavailableMsg;

  /// No description provided for @openGrafana.
  ///
  /// In en, this message translates to:
  /// **'Open Grafana'**
  String get openGrafana;

  /// No description provided for @grafanaUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Grafana unreachable'**
  String get grafanaUnreachable;

  /// No description provided for @dashboardsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Charts unavailable'**
  String get dashboardsUnavailable;

  /// No description provided for @dashboardsUnavailableMsg.
  ///
  /// In en, this message translates to:
  /// **'Charts can\'t be loaded right now. Try again in a little while.'**
  String get dashboardsUnavailableMsg;

  /// No description provided for @cameraDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Camera {n}'**
  String cameraDefaultName(int n);

  /// No description provided for @resumeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeTooltip;

  /// No description provided for @pauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTooltip;

  /// No description provided for @reconnectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnectTooltip;

  /// No description provided for @singleCamera.
  ///
  /// In en, this message translates to:
  /// **'Single camera'**
  String get singleCamera;

  /// No description provided for @allCameras.
  ///
  /// In en, this message translates to:
  /// **'All cameras'**
  String get allCameras;

  /// No description provided for @editCamera.
  ///
  /// In en, this message translates to:
  /// **'Edit camera'**
  String get editCamera;

  /// No description provided for @addCamera.
  ///
  /// In en, this message translates to:
  /// **'Add camera'**
  String get addCamera;

  /// No description provided for @addCameraButton.
  ///
  /// In en, this message translates to:
  /// **'Add camera'**
  String get addCameraButton;

  /// No description provided for @noCameras.
  ///
  /// In en, this message translates to:
  /// **'No cameras'**
  String get noCameras;

  /// No description provided for @noCamerasTechnical.
  ///
  /// In en, this message translates to:
  /// **'Add the URL of an MJPEG stream, JPEG snapshot or video file from your edge camera.'**
  String get noCamerasTechnical;

  /// No description provided for @noCamerasNormie.
  ///
  /// In en, this message translates to:
  /// **'No camera has been set up yet. Ask your administrator to add one.'**
  String get noCamerasNormie;

  /// No description provided for @noCamerasConfigured.
  ///
  /// In en, this message translates to:
  /// **'No cameras set up'**
  String get noCamerasConfigured;

  /// No description provided for @cameraCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 camera} other{{count} cameras}}'**
  String cameraCount(int count);

  /// No description provided for @cameraInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has an invalid URL'**
  String cameraInvalidUrl(String name);

  /// No description provided for @cameraUrl.
  ///
  /// In en, this message translates to:
  /// **'Stream, snapshot or video URL'**
  String get cameraUrl;

  /// No description provided for @cameraUrlError.
  ///
  /// In en, this message translates to:
  /// **'Enter an http:// or https:// URL'**
  String get cameraUrlError;

  /// Prefix of the camera URL examples
  ///
  /// In en, this message translates to:
  /// **'e.g.'**
  String get cameraExamples;

  /// No description provided for @cameraReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get cameraReconnecting;

  /// No description provided for @cameraStreamEnded.
  ///
  /// In en, this message translates to:
  /// **'Stream ended'**
  String get cameraStreamEnded;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailable;

  /// No description provided for @cameraLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get cameraLive;

  /// Badge on a camera playing a video file, like "Live" on a stream
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get cameraVideo;

  /// No description provided for @videoDemoSwitch.
  ///
  /// In en, this message translates to:
  /// **'Demo cameras'**
  String get videoDemoSwitch;

  /// No description provided for @useDemoCameras.
  ///
  /// In en, this message translates to:
  /// **'Use demo cameras'**
  String get useDemoCameras;

  /// No description provided for @videoDemoCredits.
  ///
  /// In en, this message translates to:
  /// **'Demo footage: clips from MDN (CC0); Big Buck Bunny and Sintel © Blender Foundation (CC BY 3.0).'**
  String get videoDemoCredits;

  /// {platform} is an OS name, e.g. linux
  ///
  /// In en, this message translates to:
  /// **'Video files don\'t play in the app on {platform}'**
  String videoUnsupported(String platform);

  /// Hint in the search field at the top of Settings
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearch;

  /// Settings search found nothing
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\"'**
  String settingsNoMatch(String query);

  /// Settings: heading over the categories that are this device's preferences
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get groupPersonal;

  /// Settings: heading over the connection categories
  ///
  /// In en, this message translates to:
  /// **'Deployment'**
  String get groupDeployment;

  /// Settings: heading over the admin-only categories
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get groupAdmin;

  /// No description provided for @sectionAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get sectionAccessibility;

  /// No description provided for @sectionLanguageRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & region'**
  String get sectionLanguageRegion;

  /// No description provided for @sectionEndpoints.
  ///
  /// In en, this message translates to:
  /// **'Endpoints'**
  String get sectionEndpoints;

  /// No description provided for @themeHeading.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeHeading;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// Settings summary; {size} is a percentage such as 110%
  ///
  /// In en, this message translates to:
  /// **'Text {size}'**
  String textSizeValue(String size);

  /// Sample sentence shown at the chosen text size
  ///
  /// In en, this message translates to:
  /// **'This is how text looks across the dashboard.'**
  String get textSizePreview;

  /// No description provided for @textSizeSmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get textSizeSmaller;

  /// No description provided for @textSizeLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get textSizeLarger;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetToDefault;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @onInDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'On in your device\'s settings.'**
  String get onInDeviceSettings;

  /// Language picker: follow the device; {language} is the device's language in its own name
  ///
  /// In en, this message translates to:
  /// **'Match device ({language})'**
  String languageDevice(String language);

  /// No description provided for @searchLanguages.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get searchLanguages;

  /// No description provided for @formatsHeading.
  ///
  /// In en, this message translates to:
  /// **'Formats'**
  String get formatsHeading;

  /// No description provided for @temperatureUnit.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureUnit;

  /// Choose automatically (temperature unit, time format)
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get unitAuto;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeFormat;

  /// No description provided for @time12h.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get time12h;

  /// No description provided for @time24h.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get time24h;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
