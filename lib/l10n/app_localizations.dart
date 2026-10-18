import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pt'),
    Locale('zh'),
  ];

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
  /// **'{minutes} min ago'**
  String sparkStart(int minutes);

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

  /// Assistant reply in progress, before it looks anything up
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get agentThinking;

  /// A tool the assistant runs; {what} is the tool's label from the agent, e.g. 'the alerts'
  ///
  /// In en, this message translates to:
  /// **'Looking up {what}'**
  String agentStepLookup(String what);

  /// A tool the assistant runs, when the agent gives it no label
  ///
  /// In en, this message translates to:
  /// **'Looking up data'**
  String get agentStepData;

  /// Assistant reply in progress, after its lookups
  ///
  /// In en, this message translates to:
  /// **'Writing the answer…'**
  String get agentWriting;

  /// Seconds since the question was sent, next to the reply's progress
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String agentElapsed(int seconds);

  /// Shown when a reply takes a while, if an earlier one finished in this session
  ///
  /// In en, this message translates to:
  /// **'The last answer took {seconds} s.'**
  String agentWaitLast(int seconds);

  /// Shown when a reply takes a while and no earlier one finished in this session
  ///
  /// In en, this message translates to:
  /// **'Answers can take up to a minute.'**
  String get agentWaitHint;

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
  /// **'Add the URL of an MJPEG stream, JPEG snapshot or video file from your edge camera, or one of this device\'s cameras.'**
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
  /// **'Stream, snapshot or video URL, or device camera'**
  String get cameraUrl;

  /// No description provided for @cameraUrlError.
  ///
  /// In en, this message translates to:
  /// **'Enter an http:// or https:// URL, device:back or device:front'**
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

  /// No description provided for @backCamera.
  ///
  /// In en, this message translates to:
  /// **'Back camera'**
  String get backCamera;

  /// No description provided for @frontCamera.
  ///
  /// In en, this message translates to:
  /// **'Front camera'**
  String get frontCamera;

  /// No description provided for @deviceCameraMissing.
  ///
  /// In en, this message translates to:
  /// **'This device has no such camera'**
  String get deviceCameraMissing;

  /// No description provided for @deviceCameraOneAtATime.
  ///
  /// In en, this message translates to:
  /// **'This device shows one of its cameras at a time'**
  String get deviceCameraOneAtATime;

  /// No description provided for @deviceCameraShow.
  ///
  /// In en, this message translates to:
  /// **'Show this one'**
  String get deviceCameraShow;

  /// {platform} is an OS name, e.g. linux
  ///
  /// In en, this message translates to:
  /// **'Device cameras don\'t work in the app on {platform}'**
  String deviceCameraUnsupported(String platform);

  /// No description provided for @videoDemoSwitch.
  ///
  /// In en, this message translates to:
  /// **'Demo cameras'**
  String get videoDemoSwitch;

  /// Settings → Appearance → Video: whether the Video tab opens on every camera in a grid rather than one
  ///
  /// In en, this message translates to:
  /// **'Open on all cameras'**
  String get videoGridDefault;

  /// No description provided for @alertSound.
  ///
  /// In en, this message translates to:
  /// **'Alert sound'**
  String get alertSound;

  /// No description provided for @alertDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss alert'**
  String get alertDismiss;

  /// A person, in the key to the colours of the vision overlay's boxes
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get visionPerson;

  /// No description provided for @visionPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No one in view} =1{1 person} other{{count} people}}'**
  String visionPeople(int count);

  /// No description provided for @sectionChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get sectionChats;

  /// No description provided for @chatsNote.
  ///
  /// In en, this message translates to:
  /// **'Chats linked to the project\'s bot get its alerts as they happen, and can ask it about the project. In a linked group, everyone can.'**
  String get chatsNote;

  /// No description provided for @chatsLink.
  ///
  /// In en, this message translates to:
  /// **'Link a chat'**
  String get chatsLink;

  /// No description provided for @chatsLinkHow.
  ///
  /// In en, this message translates to:
  /// **'Open the link on the phone that will use the bot, or send this command to {bot}. For a group, add the bot to the group first, then send the command there.'**
  String chatsLinkHow(String bot);

  /// No description provided for @chatsTheBot.
  ///
  /// In en, this message translates to:
  /// **'the bot'**
  String get chatsTheBot;

  /// No description provided for @chatsCodeExpires.
  ///
  /// In en, this message translates to:
  /// **'Works once, until {time}.'**
  String chatsCodeExpires(String time);

  /// No description provided for @chatsCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get chatsCopyLink;

  /// No description provided for @chatsCopyCommand.
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get chatsCopyCommand;

  /// No description provided for @chatsNone.
  ///
  /// In en, this message translates to:
  /// **'No chats linked yet.'**
  String get chatsNone;

  /// No description provided for @chatsLinkedBy.
  ///
  /// In en, this message translates to:
  /// **'Linked {date} by {who}'**
  String chatsLinkedBy(String date, String who);

  /// No description provided for @chatsLinkedOn.
  ///
  /// In en, this message translates to:
  /// **'Linked {date}'**
  String chatsLinkedOn(String date);

  /// No description provided for @chatsMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted: {codes}'**
  String chatsMuted(String codes);

  /// No description provided for @chatsUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get chatsUnlink;

  /// No description provided for @chatsUnlinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink {name}?'**
  String chatsUnlinkTitle(String name);

  /// No description provided for @chatsUnlinkBody.
  ///
  /// In en, this message translates to:
  /// **'It stops getting alerts, and the bot stops answering it. The chat is told.'**
  String get chatsUnlinkBody;

  /// No description provided for @chatsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the chats: {error}'**
  String chatsLoadFailed(String error);

  /// No description provided for @chatsMock.
  ///
  /// In en, this message translates to:
  /// **'Mock mode: the bot logs its messages instead of sending them.'**
  String get chatsMock;

  /// No description provided for @chatsOff.
  ///
  /// In en, this message translates to:
  /// **'Off: the bot has no token.'**
  String get chatsOff;

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

  /// First step of the normie view's tour, pointing at the app name
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}! Here\'s a quick look around.'**
  String tourWelcome(String appName);

  /// No description provided for @tourNavigation.
  ///
  /// In en, this message translates to:
  /// **'Your screens are here. Home shows how everything is doing; tap another screen to open it.'**
  String get tourNavigation;

  /// No description provided for @tourTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch between a light and a dark look, or match your device.'**
  String get tourTheme;

  /// No description provided for @tourSettings.
  ///
  /// In en, this message translates to:
  /// **'Language, text size and more are in Settings. You can take this tour again from there.'**
  String get tourSettings;

  /// No description provided for @tourSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out here when you\'re done.'**
  String get tourSignOut;

  /// Tour step counter, e.g. 2 of 5
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String tourProgress(Object current, Object total);

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tourBack;

  /// No description provided for @tourDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tourDone;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get tourSkip;

  /// No description provided for @takeTour.
  ///
  /// In en, this message translates to:
  /// **'Take the tour'**
  String get takeTour;

  /// No description provided for @takeTourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick look around the dashboard'**
  String get takeTourSubtitle;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navFeed;

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get feedEmpty;

  /// No description provided for @feedEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Events and alerts show up here as they happen.'**
  String get feedEmptyMsg;

  /// No description provided for @feedNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'No activity feed'**
  String get feedNotSetUp;

  /// No description provided for @feedNotSetUpMsg.
  ///
  /// In en, this message translates to:
  /// **'This deployment doesn\'t publish one.'**
  String get feedNotSetUpMsg;

  /// No description provided for @feedNotSetUpTechnical.
  ///
  /// In en, this message translates to:
  /// **'The project has no feed: add dashboard.feed to its .p4n4.json.'**
  String get feedNotSetUpTechnical;

  /// No description provided for @feedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the activity feed'**
  String get feedUnavailable;

  /// No description provided for @feedUnavailableMsg.
  ///
  /// In en, this message translates to:
  /// **'Check that the store\'s services are running, then try again.'**
  String get feedUnavailableMsg;

  /// No description provided for @feedPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 to review} other{{count} to review}}'**
  String feedPending(int count);

  /// No description provided for @feedFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedFilterAll;

  /// No description provided for @feedFilterAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get feedFilterAlerts;

  /// No description provided for @feedFilterPending.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get feedFilterPending;

  /// No description provided for @feedOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get feedOlder;

  /// No description provided for @feedActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t do that: {error}'**
  String feedActionFailed(String error);

  /// No description provided for @feedDemoData.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get feedDemoData;

  /// No description provided for @feedStatusPending.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get feedStatusPending;

  /// No description provided for @feedStatusAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get feedStatusAttended;

  /// No description provided for @feedStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get feedStatusConfirmed;

  /// No description provided for @feedStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get feedStatusDismissed;

  /// No description provided for @feedPosition.
  ///
  /// In en, this message translates to:
  /// **'{index} of {count}'**
  String feedPosition(int index, int count);

  /// No description provided for @feedPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get feedPrevious;

  /// No description provided for @feedNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get feedNext;

  /// No description provided for @feedKeys.
  ///
  /// In en, this message translates to:
  /// **'Keys: 1, 2… take the actions · J / K next / previous · Esc back'**
  String get feedKeys;

  /// No description provided for @feedPicture.
  ///
  /// In en, this message translates to:
  /// **'The alert\'s picture'**
  String get feedPicture;

  /// No description provided for @feedPictureFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the picture.'**
  String get feedPictureFailed;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Signs you out on your other devices'**
  String get changePasswordSubtitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'An admin asks you to choose your own password before you continue.'**
  String get changePasswordBody;

  /// No description provided for @fieldCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get fieldCurrentPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fieldNewPassword;

  /// No description provided for @fieldRepeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get fieldRepeatPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @passwordCurrentWrong.
  ///
  /// In en, this message translates to:
  /// **'The current password is wrong'**
  String get passwordCurrentWrong;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @signOutUserTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign out everywhere'**
  String get signOutUserTooltip;

  /// No description provided for @signOutUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign {user} out everywhere?'**
  String signOutUserTitle(String user);

  /// No description provided for @signOutUserBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll have to sign in again on every device. Their password stays the same.'**
  String get signOutUserBody;

  /// No description provided for @signOutSelfBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll have to sign in again here and on your other devices. Your password stays the same.'**
  String get signOutSelfBody;

  /// No description provided for @userLastSignIn.
  ///
  /// In en, this message translates to:
  /// **'Last signed in {when}'**
  String userLastSignIn(String when);

  /// No description provided for @userNeverSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Never signed in'**
  String get userNeverSignedIn;

  /// No description provided for @userMustChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Must choose a new password'**
  String get userMustChangePassword;

  /// No description provided for @mustChangeAtFirstSignIn.
  ///
  /// In en, this message translates to:
  /// **'Choose their own password at first sign-in'**
  String get mustChangeAtFirstSignIn;

  /// No description provided for @mustChangeAtNextSignIn.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password at next sign-in'**
  String get mustChangeAtNextSignIn;

  /// No description provided for @sectionAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get sectionAudit;

  /// No description provided for @auditNote.
  ///
  /// In en, this message translates to:
  /// **'Who changed what on this deployment, newest first'**
  String get auditNote;

  /// No description provided for @auditCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change} other{{count} changes}}, newest first'**
  String auditCount(int count);

  /// No description provided for @auditEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing has changed yet'**
  String get auditEmpty;

  /// No description provided for @auditLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the audit log: {error}'**
  String auditLoadFailed(String error);

  /// No description provided for @auditLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get auditLoadMore;

  /// No description provided for @sectionBanner.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get sectionBanner;

  /// No description provided for @bannerNone.
  ///
  /// In en, this message translates to:
  /// **'No banner'**
  String get bannerNone;

  /// No description provided for @bannerShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing on every device until you clear it'**
  String get bannerShowing;

  /// No description provided for @bannerShowingUntil.
  ///
  /// In en, this message translates to:
  /// **'Showing on every device until {when}'**
  String bannerShowingUntil(String when);

  /// No description provided for @bannerText.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get bannerText;

  /// No description provided for @bannerHint.
  ///
  /// In en, this message translates to:
  /// **'Maintenance today 3–4 pm'**
  String get bannerHint;

  /// No description provided for @bannerInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get bannerInfo;

  /// No description provided for @bannerWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get bannerWarning;

  /// No description provided for @bannerUntilCleared.
  ///
  /// In en, this message translates to:
  /// **'Until cleared'**
  String get bannerUntilCleared;

  /// No description provided for @bannerForHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{For 1 hour} other{For {hours} hours}}'**
  String bannerForHours(int hours);

  /// No description provided for @bannerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get bannerClear;

  /// No description provided for @bannerShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get bannerShow;

  /// No description provided for @viewStartTab.
  ///
  /// In en, this message translates to:
  /// **'Opens on'**
  String get viewStartTab;

  /// No description provided for @viewHomeCards.
  ///
  /// In en, this message translates to:
  /// **'Home shows'**
  String get viewHomeCards;

  /// No description provided for @homeCardStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get homeCardStatus;

  /// No description provided for @homeCardDevice.
  ///
  /// In en, this message translates to:
  /// **'Device readings'**
  String get homeCardDevice;

  /// No description provided for @homeCardPage.
  ///
  /// In en, this message translates to:
  /// **'Project page'**
  String get homeCardPage;

  /// No description provided for @viewGrafanaPage.
  ///
  /// In en, this message translates to:
  /// **'Grafana page'**
  String get viewGrafanaPage;

  /// No description provided for @viewGrafanaPageHelp.
  ///
  /// In en, this message translates to:
  /// **'Empty: the deployment\'s page'**
  String get viewGrafanaPageHelp;

  /// No description provided for @viewCameras.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get viewCameras;

  /// No description provided for @viewCameraOverlay.
  ///
  /// In en, this message translates to:
  /// **'Vision overlay'**
  String get viewCameraOverlay;

  /// No description provided for @viewAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts that pop up'**
  String get viewAlerts;

  /// No description provided for @alertsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get alertsAll;

  /// No description provided for @alertsReview.
  ///
  /// In en, this message translates to:
  /// **'Only those to review'**
  String get alertsReview;

  /// No description provided for @alertsOff.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get alertsOff;

  /// No description provided for @viewAlertSound.
  ///
  /// In en, this message translates to:
  /// **'Chime for alerts to review'**
  String get viewAlertSound;

  /// No description provided for @sectionDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get sectionDevice;

  /// No description provided for @deviceKiosk.
  ///
  /// In en, this message translates to:
  /// **'Kiosk mode'**
  String get deviceKiosk;

  /// No description provided for @kioskModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Locks this device to a viewer account: no sign-out or settings, and it starts over when nobody uses it'**
  String get kioskModeHelp;

  /// No description provided for @kioskNeedsAccounts.
  ///
  /// In en, this message translates to:
  /// **'Needs sign-in with p4n4-api accounts'**
  String get kioskNeedsAccounts;

  /// No description provided for @kioskIdleReset.
  ///
  /// In en, this message translates to:
  /// **'Start over when idle'**
  String get kioskIdleReset;

  /// No description provided for @idleSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign admins and power users out when idle'**
  String get idleSignOut;

  /// No description provided for @idleNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get idleNever;

  /// No description provided for @idleAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{After 1 minute} other{After {count} minutes}}'**
  String idleAfterMinutes(int count);

  /// No description provided for @startKioskTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on kiosk mode'**
  String get startKioskTitle;

  /// No description provided for @startKioskBody.
  ///
  /// In en, this message translates to:
  /// **'Sign this device in with a viewer account. People here can\'t sign out or change settings, and it starts over when nobody uses it.'**
  String get startKioskBody;

  /// No description provided for @kioskTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get kioskTurnOn;

  /// No description provided for @leaveKiosk.
  ///
  /// In en, this message translates to:
  /// **'Leave kiosk mode'**
  String get leaveKiosk;

  /// No description provided for @leaveKioskBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with an admin account. This device then stays signed in as that admin.'**
  String get leaveKioskBody;

  /// No description provided for @kioskNeedsViewer.
  ///
  /// In en, this message translates to:
  /// **'That\'s not a viewer account.'**
  String get kioskNeedsViewer;

  /// No description provided for @kioskNeedsAdmin.
  ///
  /// In en, this message translates to:
  /// **'That\'s not an admin account.'**
  String get kioskNeedsAdmin;

  /// No description provided for @startTabDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get startTabDefault;

  /// No description provided for @chartHistory.
  ///
  /// In en, this message translates to:
  /// **'Chart history'**
  String get chartHistory;

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String minutesCount(int count);

  /// No description provided for @defaultCamera.
  ///
  /// In en, this message translates to:
  /// **'Default camera'**
  String get defaultCamera;

  /// No description provided for @defaultCameraFirst.
  ///
  /// In en, this message translates to:
  /// **'The first one'**
  String get defaultCameraFirst;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} logs'**
  String logsTitle(String name);

  /// No description provided for @logsFailed.
  ///
  /// In en, this message translates to:
  /// **'Stopped: {error}'**
  String logsFailed(String error);

  /// No description provided for @logsEnded.
  ///
  /// In en, this message translates to:
  /// **'The log stream ended'**
  String get logsEnded;

  /// No description provided for @logsFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following new lines'**
  String get logsFollowing;

  /// No description provided for @copyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyTooltip;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @logsFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get logsFilter;

  /// No description provided for @logsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No log lines yet'**
  String get logsEmpty;

  /// No description provided for @logsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No lines match the filter'**
  String get logsNoMatch;

  /// No description provided for @logsLatest.
  ///
  /// In en, this message translates to:
  /// **'Jump to the newest line'**
  String get logsLatest;

  /// No description provided for @logsMenu.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsMenu;

  /// No description provided for @serviceConfirmRestartBody.
  ///
  /// In en, this message translates to:
  /// **'It stops for a moment for everyone using it.'**
  String get serviceConfirmRestartBody;

  /// No description provided for @serviceUptime.
  ///
  /// In en, this message translates to:
  /// **'up {time}'**
  String serviceUptime(String time);

  /// No description provided for @serviceUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get serviceUnhealthy;

  /// No description provided for @serviceStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get serviceStarting;

  /// No description provided for @serviceActions.
  ///
  /// In en, this message translates to:
  /// **'{name} actions'**
  String serviceActions(String name);

  /// No description provided for @sectionDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get sectionDevices;

  /// No description provided for @devicesNote.
  ///
  /// In en, this message translates to:
  /// **'Devices that send readings to {platform}-api, each with its own key.'**
  String devicesNote(String platform);

  /// No description provided for @devicesOnlyAdmins.
  ///
  /// In en, this message translates to:
  /// **'Only admins can change devices.'**
  String get devicesOnlyAdmins;

  /// No description provided for @devicesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the devices: {error}'**
  String devicesLoadFailed(String error);

  /// No description provided for @devicesNone.
  ///
  /// In en, this message translates to:
  /// **'No devices registered yet.'**
  String get devicesNone;

  /// No description provided for @deviceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get deviceDisabled;

  /// No description provided for @deviceLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String deviceLastSeen(String time);

  /// No description provided for @deviceNeverSeen.
  ///
  /// In en, this message translates to:
  /// **'Never seen'**
  String get deviceNeverSeen;

  /// No description provided for @deviceKey.
  ///
  /// In en, this message translates to:
  /// **'Key {prefix}…'**
  String deviceKey(String prefix);

  /// No description provided for @deviceDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable: it can\'t sign in'**
  String get deviceDisable;

  /// No description provided for @deviceEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get deviceEnable;

  /// No description provided for @rotateKey.
  ///
  /// In en, this message translates to:
  /// **'New key'**
  String get rotateKey;

  /// No description provided for @rotateKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'New key for {name}?'**
  String rotateKeyTitle(String name);

  /// No description provided for @rotateKeyBody.
  ///
  /// In en, this message translates to:
  /// **'The current key stops working at once. Put the new one on the device.'**
  String get rotateKeyBody;

  /// No description provided for @removeDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeDeviceTitle(String name);

  /// No description provided for @removeDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Its key stops working at once, and it can\'t send readings any more.'**
  String get removeDeviceBody;

  /// No description provided for @removeDeviceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get removeDeviceTooltip;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @addDevice.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get addDevice;

  /// No description provided for @editDevice.
  ///
  /// In en, this message translates to:
  /// **'Edit device'**
  String get editDevice;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// No description provided for @deviceIdHelp.
  ///
  /// In en, this message translates to:
  /// **'Letters, digits, dots, dashes and underscores; it can\'t change later'**
  String get deviceIdHelp;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get deviceName;

  /// No description provided for @deviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get deviceDescription;

  /// No description provided for @deviceKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Key for {id}'**
  String deviceKeyTitle(String id);

  /// No description provided for @deviceKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Copy it to the device now: it isn\'t shown again.'**
  String get deviceKeyBody;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @summaryDownFor.
  ///
  /// In en, this message translates to:
  /// **'Down for {time}'**
  String summaryDownFor(String time);

  /// No description provided for @deviceUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String deviceUpdatedAt(String time);

  /// No description provided for @deviceStaleSince.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh · readings from {time}'**
  String deviceStaleSince(String time);

  /// No description provided for @sectionThresholds.
  ///
  /// In en, this message translates to:
  /// **'Thresholds'**
  String get sectionThresholds;

  /// No description provided for @thresholdServiceDown.
  ///
  /// In en, this message translates to:
  /// **'Service down'**
  String get thresholdServiceDown;

  /// No description provided for @sensorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensorsTitle;

  /// No description provided for @sensorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live readings from the devices. Tap one for its history.'**
  String get sensorsSubtitle;

  /// No description provided for @sensorsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No live readings: {error}'**
  String sensorsUnavailable(String error);

  /// No description provided for @sensorsNoBroker.
  ///
  /// In en, this message translates to:
  /// **'Not connected to the MQTT broker yet'**
  String get sensorsNoBroker;

  /// No description provided for @sensorsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for readings…'**
  String get sensorsWaiting;

  /// No description provided for @sensorReadAt.
  ///
  /// In en, this message translates to:
  /// **'Read at {time}'**
  String sensorReadAt(String time);

  /// No description provided for @rangeHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get rangeHour;

  /// No description provided for @rangeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get rangeDay;

  /// No description provided for @rangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get rangeWeek;

  /// No description provided for @sensorHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the history: {error}'**
  String sensorHistoryFailed(String error);

  /// No description provided for @sensorHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No readings stored for this period'**
  String get sensorHistoryEmpty;

  /// No description provided for @sensorMin.
  ///
  /// In en, this message translates to:
  /// **'Lowest {value}'**
  String sensorMin(String value);

  /// No description provided for @sensorMax.
  ///
  /// In en, this message translates to:
  /// **'Highest {value}'**
  String sensorMax(String value);

  /// No description provided for @modelTitle.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelTitle;

  /// No description provided for @modelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The inference runner on the edge device'**
  String get modelSubtitle;

  /// No description provided for @modelNoRunner.
  ///
  /// In en, this message translates to:
  /// **'No inference runner on this deployment, or it isn\'t answering.'**
  String get modelNoRunner;

  /// No description provided for @modelFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the runner: {error}'**
  String modelFailed(String error);

  /// No description provided for @modelInferences.
  ///
  /// In en, this message translates to:
  /// **'Inferences'**
  String get modelInferences;

  /// No description provided for @modelLastLatency.
  ///
  /// In en, this message translates to:
  /// **'Last latency'**
  String get modelLastLatency;

  /// No description provided for @modelLastAt.
  ///
  /// In en, this message translates to:
  /// **'Last one'**
  String get modelLastAt;

  /// No description provided for @modelRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent results'**
  String get modelRecent;

  /// No description provided for @classifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get classifyTitle;

  /// No description provided for @classifyValues.
  ///
  /// In en, this message translates to:
  /// **'Feature values'**
  String get classifyValues;

  /// No description provided for @classifyExpects.
  ///
  /// In en, this message translates to:
  /// **'{count} of {expected} values'**
  String classifyExpects(int expected, int count);

  /// No description provided for @classify.
  ///
  /// In en, this message translates to:
  /// **'Classify'**
  String get classify;

  /// No description provided for @classifyAnomaly.
  ///
  /// In en, this message translates to:
  /// **'anomaly {score}'**
  String classifyAnomaly(String score);

  /// No description provided for @classifyNotNumbers.
  ///
  /// In en, this message translates to:
  /// **'Enter numbers separated by commas or spaces.'**
  String get classifyNotNumbers;

  /// No description provided for @commandTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a command'**
  String get commandTitle;

  /// No description provided for @commandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Publishes one MQTT message, e.g. to a device\'s command topic'**
  String get commandSubtitle;

  /// No description provided for @commandTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get commandTopic;

  /// No description provided for @commandPayload.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get commandPayload;

  /// No description provided for @commandPayloadHelp.
  ///
  /// In en, this message translates to:
  /// **'Text, or JSON'**
  String get commandPayloadHelp;

  /// No description provided for @commandRetain.
  ///
  /// In en, this message translates to:
  /// **'Retain'**
  String get commandRetain;

  /// No description provided for @commandSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {topic} ({bytes} bytes)'**
  String commandSent(String topic, int bytes);

  /// No description provided for @commandTopicNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This deployment doesn\'t allow publishing to {topic} (P4N4_API_MQTT_PUBLISH_ALLOW and _DENY on p4n4-api).'**
  String commandTopicNotAllowed(String topic);

  /// No description provided for @commandNoBroker.
  ///
  /// In en, this message translates to:
  /// **'p4n4-api isn\'t connected to the broker: {error}'**
  String commandNoBroker(String error);

  /// No description provided for @commandNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only operators and admins can send commands.'**
  String get commandNotAllowed;

  /// No description provided for @commandFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent: {error}'**
  String commandFailed(String error);

  /// No description provided for @thresholdsNote.
  ///
  /// In en, this message translates to:
  /// **'When {deployment}\'s readings show as high or critical, on this device.'**
  String thresholdsNote(String deployment);

  /// No description provided for @thresholdLevels.
  ///
  /// In en, this message translates to:
  /// **'High from {high} · critical from {critical}'**
  String thresholdLevels(String high, String critical);

  /// No description provided for @thresholdServiceDownHelp.
  ///
  /// In en, this message translates to:
  /// **'A service that stops answering is a warning at first, then critical'**
  String get thresholdServiceDownHelp;

  /// No description provided for @thresholdsReset.
  ///
  /// In en, this message translates to:
  /// **'Back to the defaults'**
  String get thresholdsReset;

  /// No description provided for @fleetNoReadings.
  ///
  /// In en, this message translates to:
  /// **'No device readings'**
  String get fleetNoReadings;

  /// No description provided for @incidentUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get incidentUnreachable;

  /// No description provided for @incidentOngoing.
  ///
  /// In en, this message translates to:
  /// **'{service} down since {start} ({length})'**
  String incidentOngoing(String service, String start, String length);

  /// No description provided for @incidentEnded.
  ///
  /// In en, this message translates to:
  /// **'{service} down {start}–{end}'**
  String incidentEnded(String service, String start, String end);

  /// No description provided for @incidentHistory.
  ///
  /// In en, this message translates to:
  /// **'Outage history'**
  String get incidentHistory;

  /// No description provided for @incidentHistoryOf.
  ///
  /// In en, this message translates to:
  /// **'{name}: outages'**
  String incidentHistoryOf(String name);

  /// No description provided for @incidentNone.
  ///
  /// In en, this message translates to:
  /// **'No outages seen from this device.'**
  String get incidentNone;

  /// No description provided for @incidentNote.
  ///
  /// In en, this message translates to:
  /// **'Seen from this device while it showed this deployment\'s status.'**
  String get incidentNote;

  /// No description provided for @serviceDownFor.
  ///
  /// In en, this message translates to:
  /// **'Offline · {time}'**
  String serviceDownFor(String time);

  /// No description provided for @answerStyle.
  ///
  /// In en, this message translates to:
  /// **'Answer style'**
  String get answerStyle;

  /// No description provided for @styleStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get styleStandard;

  /// No description provided for @styleBrief.
  ///
  /// In en, this message translates to:
  /// **'Brief'**
  String get styleBrief;

  /// No description provided for @styleSteps.
  ///
  /// In en, this message translates to:
  /// **'Step by step'**
  String get styleSteps;

  /// No description provided for @styleSimple.
  ///
  /// In en, this message translates to:
  /// **'Plain words'**
  String get styleSimple;

  /// No description provided for @styleCustom.
  ///
  /// In en, this message translates to:
  /// **'Own instructions'**
  String get styleCustom;

  /// No description provided for @styleCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'How should the assistant answer?'**
  String get styleCustomLabel;

  /// No description provided for @styleCustomHelp.
  ///
  /// In en, this message translates to:
  /// **'Sent with every question from this device'**
  String get styleCustomHelp;

  /// No description provided for @videoGridLight.
  ///
  /// In en, this message translates to:
  /// **'Light grid for slow links'**
  String get videoGridLight;

  /// No description provided for @videoGridLightHelp.
  ///
  /// In en, this message translates to:
  /// **'In the grid, a new picture every 2 seconds instead of live motion'**
  String get videoGridLightHelp;

  /// No description provided for @cameraFrameEvery.
  ///
  /// In en, this message translates to:
  /// **'every {seconds} s'**
  String cameraFrameEvery(int seconds);

  /// No description provided for @clearList.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearList;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it', 'ja', 'ko', 'nl', 'pt', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
