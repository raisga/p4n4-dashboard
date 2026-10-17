// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navHome => 'ホーム';

  @override
  String get navClients => 'クライアント';

  @override
  String get navServices => 'サービス';

  @override
  String get navEdge => 'デバイス';

  @override
  String get navAgent => 'アシスタント';

  @override
  String get navGrafana => 'グラフ';

  @override
  String get navVideo => 'カメラ';

  @override
  String previewingView(String view) {
    return '$viewプロファイルの表示でダッシュボードを見ています';
  }

  @override
  String get backToAdmin => '管理者に戻る';

  @override
  String themeTooltip(String mode) {
    return 'テーマ：$mode';
  }

  @override
  String get themeSystem => 'デバイスに合わせる';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get settingsTooltip => '設定';

  @override
  String get signOutTooltip => 'サインアウト';

  @override
  String get roleAdmin => '管理者';

  @override
  String get rolePower => '上級';

  @override
  String get roleNormie => '閲覧者';

  @override
  String get retry => '再試行';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get add => '追加';

  @override
  String get remove => '削除';

  @override
  String get reset => 'リセット';

  @override
  String get delete => '消去';

  @override
  String get clear => '新しい会話';

  @override
  String get open => '開く';

  @override
  String get connect => '接続';

  @override
  String get signOut => 'サインアウト';

  @override
  String get refreshStatus => '状態を更新';

  @override
  String get healthOnline => 'オンライン';

  @override
  String get healthOffline => 'オフライン';

  @override
  String get healthChecking => '確認中…';

  @override
  String get healthUnknown => '不明';

  @override
  String get fieldUsername => 'ユーザー名';

  @override
  String get fieldPassword => 'パスワード';

  @override
  String get fieldHost => 'ホスト';

  @override
  String get fieldName => '名前';

  @override
  String get fieldView => 'プロファイル';

  @override
  String hostHelp(String platform) {
    return '$platform のスタックを実行しているマシンです。Android エミュレーターからは 10.0.2.2 を使います。';
  }

  @override
  String apiBaseUrl(String platform) {
    return '$platform-api のベース URL';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return '$platform-api のベース URL（任意）';
  }

  @override
  String get sessionExpired => 'セッションの有効期限が切れました。もう一度サインインしてください。';

  @override
  String get signInTag => 'サインイン';

  @override
  String get signInConnecting => '接続中…';

  @override
  String get signInWelcome => 'ようこそ';

  @override
  String get signInButton => 'サインイン';

  @override
  String get signInWrongCredentials => 'ユーザー名またはパスワードが正しくありません。';

  @override
  String get signInRateLimited => '試行回数が多すぎます。1 分待ってからもう一度お試しください。';

  @override
  String signInApiFailed(String platform) {
    return '$platform-api に接続できません。サーバーを確認してもう一度お試しください。';
  }

  @override
  String get signInChooseTitle => '続行方法を選択';

  @override
  String signInAuthOffNote(String platform) {
    return '$platform-api はサインインなしで動作しているため（P4N4_API_AUTH=off）、誰でもプロファイルを選べます。';
  }

  @override
  String get signInOfflineTitle => 'サインインせずに続行';

  @override
  String signInOfflineNote(String platform) {
    return '$platform-api がない場合、サービスの状態はポートの確認で取得し、プロファイルはご自身で選びます。';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return '$platform-api に接続できません';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return 'サインインには $url の $platform-api が必要です。起動していてこのデバイスから到達できるか確認するか、下でサーバーを変更してください。';
  }

  @override
  String get signInOfflineButton => 'サインインせずに続行';

  @override
  String get signInDevAccounts => '開発用アカウント';

  @override
  String signInDevAccountsNote(String platform) {
    return 'P4N4_API_DEV_USERS=true の $platform-api が必要です';
  }

  @override
  String signInServer(String url) {
    return 'サーバー：$url';
  }

  @override
  String get signInChangeServer => '変更';

  @override
  String get roleAdminTitle => '管理者';

  @override
  String get roleAdminDesc => 'すべての機能に加え、クライアントのデプロイ、スタックの操作、ユーザー、診断を扱えます。';

  @override
  String get rolePowerTitle => '上級ユーザー';

  @override
  String get rolePowerDesc => 'すべてのサービスと設定を扱えます。デプロイやユーザーの管理は除きます。';

  @override
  String get roleNormieTitle => '閲覧者';

  @override
  String get roleNormieDesc => 'システムの状態、グラフ、カメラ、アシスタント。設定を変えずに閲覧できます。';

  @override
  String get settingsTitle => '設定';

  @override
  String get sectionAppearance => '外観';

  @override
  String get sectionLanguage => '言語';

  @override
  String get sectionConnection => '接続';

  @override
  String get sectionEdgeMetrics => 'デバイスの計測値';

  @override
  String get sectionGrafana => 'グラフ';

  @override
  String get sectionVideo => 'カメラ';

  @override
  String get sectionViews => 'プロファイル';

  @override
  String get sectionUsers => 'ユーザー';

  @override
  String get sectionDiagnostics => '診断';

  @override
  String get sectionAccount => 'アカウント';

  @override
  String get sectionAbout => 'このアプリについて';

  @override
  String get languageSystem => 'デバイスに合わせる';

  @override
  String get fieldDeployment => 'デプロイ';

  @override
  String get resetConnection => '既定の接続に戻す';

  @override
  String get metricsUrl => '計測値の URL';

  @override
  String get demoData => 'デモデータ';

  @override
  String get grafanaBaseUrl => 'Grafana のベース URL';

  @override
  String get dashboardPath => 'ダッシュボードのパス';

  @override
  String get kioskMode => 'キオスクモード';

  @override
  String viewsSaveFailed(String error) {
    return 'プロファイルを保存できませんでした：$error';
  }

  @override
  String get tabOrder => 'タブの順序';

  @override
  String get resetTabOrder => '順序をリセット';

  @override
  String get dragToReorder => 'ドラッグして並べ替え';

  @override
  String previewView(String view) {
    return '$viewとして表示';
  }

  @override
  String signedInAs(String user) {
    return '$user としてサインイン中';
  }

  @override
  String get signedInWithoutAccount => 'アカウントなしでサインイン中';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · $platform-api アカウント';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · サインイン時に選択';
  }

  @override
  String get licenses => 'ライセンス';

  @override
  String usersNote(String platform) {
    return 'このデプロイの $platform-api アカウントです。プロファイルの変更はユーザーの次回更新時に反映され、パスワードをリセットするとそのユーザーはサインアウトされます。';
  }

  @override
  String usersLoadFailed(String error) {
    return 'ユーザーを読み込めません：$error';
  }

  @override
  String get usersOnlyAdmins => 'ユーザーを管理できるのは管理者だけです。';

  @override
  String userYou(String user) {
    return '$user（あなた）';
  }

  @override
  String get resetPasswordTooltip => 'パスワードをリセット';

  @override
  String get removeUserTooltip => 'ユーザーを削除';

  @override
  String get addUserButton => 'ユーザーを追加';

  @override
  String get addUserTitle => 'ユーザーを追加';

  @override
  String get passwordMinLength => '10 文字以上';

  @override
  String removeUserTitle(String user) {
    return '$user を削除しますか？';
  }

  @override
  String get removeUserBody => 'すべての場所でサインアウトされ、再びサインインできなくなります。';

  @override
  String newPasswordTitle(String user) {
    return '$user の新しいパスワード';
  }

  @override
  String get newPasswordHelp => 'すべての場所でサインアウトされます';

  @override
  String get diagDeployment => 'デプロイ';

  @override
  String get diagSignIn => 'サインイン';

  @override
  String get diagView => 'プロファイル';

  @override
  String get diagAuthMode => '認証モード';

  @override
  String get diagAccessToken => 'アクセストークン';

  @override
  String get diagRefreshToken => 'リフレッシュトークン';

  @override
  String get diagSecureStorage => '安全なストレージ';

  @override
  String get diagServices => 'サービス';

  @override
  String get diagChecking => '確認中…';

  @override
  String get diagNotChecked => '未確認';

  @override
  String get diagNoAccount => 'アカウントなし';

  @override
  String get diagNone => 'なし';

  @override
  String get diagStored => '保存済み';

  @override
  String get diagAvailable => '利用可能';

  @override
  String get diagUnavailable => '利用不可（メモリ内のみ）';

  @override
  String diagServicesViaApi(int online, int known) {
    return 'API によると $known 件中 $online 件が稼働中';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return 'ポートによると $known 件中 $online 件が稼働中';
  }

  @override
  String get tokenNone => 'なし（次のリクエストで取得）';

  @override
  String tokenExpired(String time) {
    return '$time に期限切れ';
  }

  @override
  String tokenValid(String time, int minutes) {
    return '$time まで有効（$minutes 分）';
  }

  @override
  String get tokenUnreadable => 'あり（読み取り不可）';

  @override
  String get checkSignIn => 'サインインを確認';

  @override
  String get checkServices => 'サービスを確認';

  @override
  String get copySettings => '設定をコピー';

  @override
  String get settingsDump => '設定のエクスポート';

  @override
  String get secretsHidden => '秘密情報は非表示';

  @override
  String get summaryChecking => 'システムを確認しています…';

  @override
  String get summaryCheckingSub => '数秒かかります。';

  @override
  String get summaryUnavailable => 'サービスの状態を取得できません';

  @override
  String get summaryUnavailableSub => 'システムは応答していますが、サービスの状態を報告していません。続く場合は管理者に連絡してください。';

  @override
  String get summaryUnreachable => 'システムに接続できません';

  @override
  String get summaryUnreachableSub => 'デバイスの電源が入っていて接続されているか確認してください。';

  @override
  String get summaryOk => 'すべて正常です';

  @override
  String get summaryOkSub => 'システムは正常に動作しています。';

  @override
  String get summaryAttention => '確認が必要な項目があります';

  @override
  String get summaryAttentionSub => 'システムの一部が現在動作していません。数分で回復しない場合は管理者に連絡してください。';

  @override
  String summaryAffected(String features) {
    return '影響あり：$features';
  }

  @override
  String summaryUpdated(String time) {
    return '$time に確認';
  }

  @override
  String get featureAssistant => 'アシスタント';

  @override
  String get featureCharts => 'グラフ';

  @override
  String get featureHistory => 'データ履歴';

  @override
  String get featureSensors => 'センサーデータ';

  @override
  String get featureAutomations => '自動化';

  @override
  String get featureDeviceAi => 'デバイス上の AI';

  @override
  String get featureConnection => 'システムへの接続';

  @override
  String get yourDevice => 'お使いのデバイス';

  @override
  String get deviceUnavailable => '現在、デバイスの計測値を取得できません。';

  @override
  String get deviceLoading => '計測値を読み込み中…';

  @override
  String get readingProcessor => 'プロセッサ';

  @override
  String get readingMemory => 'メモリ';

  @override
  String get readingTemperature => '温度';

  @override
  String get levelNormal => '正常';

  @override
  String get levelHigh => '高';

  @override
  String get levelCritical => '非常に高い';

  @override
  String get levelWarm => 'やや高温';

  @override
  String get levelHot => '高温';

  @override
  String get deviceDetails => '詳細';

  @override
  String servicesApiUnreachable(String platform) {
    return '$platform-api が応答しないため、各サービスのポートを確認して状態を取得しています。';
  }

  @override
  String get servicesTitle => 'サービス';

  @override
  String servicesSubtitle(String host) {
    return '$host で動作しているアプリケーションです。開くと直接使えます。';
  }

  @override
  String get servicesSubtitlePlain => 'システムで動作しているアプリケーションです。開くと使えます。';

  @override
  String servicesLiveFrom(String authority) {
    return '$authority からのライブ状態';
  }

  @override
  String servicesContacting(String authority) {
    return '$authority に接続中…';
  }

  @override
  String serviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 件のサービス', one: '1 件のサービス');
    return '$_temp0';
  }

  @override
  String endpointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 件のエンドポイント', one: '1 件のエンドポイント');
    return '$_temp0';
  }

  @override
  String get stackControls => 'スタックの操作';

  @override
  String get stackStart => '開始';

  @override
  String get stackRestart => '再起動';

  @override
  String get stackStop => '停止';

  @override
  String stackConfirmStop(String stack) {
    return '$stack を停止しますか？';
  }

  @override
  String get stackConfirmStopBody => '誰かが再び開始するまで、そのサービスは全員にとって停止します。';

  @override
  String stackConfirmRestart(String stack) {
    return '$stack を再起動しますか？';
  }

  @override
  String get stackConfirmRestartBody => '再起動中、そのサービスは一時的に停止します。';

  @override
  String stackJobRunning(String stack) {
    return '$stack を処理中…';
  }

  @override
  String stackJobDone(String stack) {
    return '$stack の処理が完了しました。';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return '$stack の操作に失敗しました：$error';
  }

  @override
  String couldNotOpen(String url) {
    return '$url を開けませんでした';
  }

  @override
  String get tcpOnly => 'Web ページなし';

  @override
  String get stackIot => 'IoT スタック';

  @override
  String get stackAi => 'AI スタック';

  @override
  String get stackApi => 'API ゲートウェイ';

  @override
  String get serviceGrafanaDesc => 'ダッシュボードとグラフ';

  @override
  String get serviceNodeRedDesc => 'フローの自動化';

  @override
  String get serviceInfluxDesc => 'センサーデータの履歴';

  @override
  String get serviceMqttDesc => 'デバイス向けメッセージブローカー';

  @override
  String get serviceOllamaDesc => 'ローカル AI モデル';

  @override
  String get serviceLettaDesc => '記憶を持つ AI エージェント';

  @override
  String get serviceN8nDesc => 'ワークフローの自動化';

  @override
  String get serviceEiRunnerDesc => 'デバイス上の AI（Edge Impulse）';

  @override
  String get serviceApiDesc => 'すべてのスタックへの単一の入口';

  @override
  String get serviceSwaggerDesc => '対話型 API ドキュメント';

  @override
  String get clientsIntro => '各デプロイの状態はその API から、応答しない場合はサービスのポートの確認から取得します。接続すると、このダッシュボードとすべての接続設定がそのデプロイに切り替わります。';

  @override
  String get clientsTitle => 'クライアントのデプロイ';

  @override
  String get noDeployments => 'デプロイがありません';

  @override
  String get noDeploymentsMsg => '名前とホストを指定してクライアントのデプロイを追加すると、ここで監視できます。';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known 稼働中';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known 稼働中（ポート確認）';
  }

  @override
  String get currentBadge => '接続中';

  @override
  String get editTooltip => '編集';

  @override
  String get removeTooltip => '削除';

  @override
  String get removeCurrentTooltip => 'このデプロイを削除するには、別のデプロイに接続してください';

  @override
  String get addDeployment => 'デプロイを追加';

  @override
  String get editDeployment => 'デプロイを編集';

  @override
  String get clientName => 'クライアント名';

  @override
  String get apiUrlOptional => 'API の URL（任意）';

  @override
  String get apiUrlHelp => 'API がホストのポート 8000 にない場合のみ';

  @override
  String get edgeDemoSwitch => 'デモデータ';

  @override
  String get edgeNoMetrics => 'デバイスの計測値がありません';

  @override
  String edgeFetchFailed(String url, String error) {
    return '$url を読み取れませんでした：$error\n\n設定の計測値の URL を、README に記載の JSON を返すエンドポイントに向けてください。';
  }

  @override
  String get edgeUnavailable => '現在、デバイスの計測値を取得できません。しばらくしてからもう一度お試しください。';

  @override
  String get edgeSubtitle => 'デバイスのライブ計測値（2 秒ごと）。';

  @override
  String get useDemoData => 'デモデータを使う';

  @override
  String get edgeStale => '未更新';

  @override
  String get edgeDemoLabel => 'デモデータ';

  @override
  String get edgeSynthetic => 'テスト用の架空の計測値';

  @override
  String get edgeLive => 'ライブ';

  @override
  String get metricInference => 'AI の応答時間';

  @override
  String get factDisk => '使用中のストレージ';

  @override
  String get factLoad => '平均負荷';

  @override
  String get factUptime => '稼働時間';

  @override
  String sparkStart(int minutes) {
    return '$minutes 分前';
  }

  @override
  String get sparkNow => '現在';

  @override
  String get agentModel => 'モデル';

  @override
  String get agentAgent => 'エージェント';

  @override
  String get assistantUnavailable => 'アシスタントを利用できません';

  @override
  String get assistantUnavailableMsg => 'アシスタントが現在応答していません。しばらくしてからもう一度お試しください。';

  @override
  String get assistantNotSetUp => 'アシスタントが設定されていません';

  @override
  String get assistantNotSetUpMsg => '管理者に設定を依頼してください。';

  @override
  String get assistantChat => 'アシスタントに質問';

  @override
  String get assistantChatMsg => 'システムの現在の状態を把握しているので、デバイス、データ、サービスについて質問できます。';

  @override
  String get assistantSuggestStatus => 'すべて正常に動作していますか？';

  @override
  String get assistantSuggestDevice => '今、デバイスの負荷はどのくらいですか？';

  @override
  String get assistantSuggestHelp => '何を手伝ってもらえますか？';

  @override
  String get assistantSharedModel => 'このデプロイの全員がこのモデルと話します。';

  @override
  String get assistantSharedAgent => 'このデプロイの全員がこのエージェントと話します。';

  @override
  String assistantSaveFailed(String error) {
    return 'アシスタントを変更できませんでした：$error';
  }

  @override
  String get assistantErrorUnavailable => 'アシスタントが現在応答していません。少ししてからもう一度お試しください。';

  @override
  String get assistantErrorChanged => 'アシスタントが変更されました。続けるには新しい会話を始めてください。';

  @override
  String get assistantErrorGeneric => 'うまくいきませんでした。もう一度お試しください。';

  @override
  String get assistantInputUnavailable => 'アシスタントは現在利用できません';

  @override
  String get sendTooltip => '送信';

  @override
  String get stopTooltip => '停止';

  @override
  String agentUnreachable(String backend) {
    return '$backend が応答しません';
  }

  @override
  String get agentNoModels => 'モデルがインストールされていません';

  @override
  String get agentNoModelsMsg => 'まずデバイスにモデルをダウンロードしてください。例：`docker exec p4n4-ollama ollama pull llama3.2`';

  @override
  String get agentNoAgents => 'エージェントがまだありません';

  @override
  String get agentNoAgentsMsg => 'Letta の ADE でエージェントを作成してから、もう一度お試しください。';

  @override
  String agentOllamaMsg(String platform) {
    return 'メッセージはシステムの現在の状態とともに $platform-api 経由で Ollama に送られます。履歴はこのセッションの間だけ保持されます。';
  }

  @override
  String get agentLettaMsg => 'Letta のエージェントはセッションをまたいで独自の記憶を保持します。';

  @override
  String get agentMessageHint => '質問を入力…（Shift+Enter で改行）';

  @override
  String get agentSelectFirst => '先にモデルまたはエージェントを選んでください';

  @override
  String get agentStopped => '（停止しました）';

  @override
  String get agentThinking => '考え中…';

  @override
  String agentStepLookup(String what) {
    return '$whatを確認中';
  }

  @override
  String get agentStepData => 'データを確認中';

  @override
  String get agentWriting => '回答を作成中…';

  @override
  String agentElapsed(int seconds) {
    return '$seconds 秒';
  }

  @override
  String agentWaitLast(int seconds) {
    return '前回の回答には $seconds 秒かかりました。';
  }

  @override
  String get agentWaitHint => '回答には最大 1 分ほどかかることがあります。';

  @override
  String get bubbleYou => 'あなた';

  @override
  String get bubbleAgent => 'アシスタント';

  @override
  String get bubbleError => '問題が発生しました';

  @override
  String get grafanaDashboards => 'グラフ';

  @override
  String get reloadTooltip => '再読み込み';

  @override
  String get backTooltip => '戻る';

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String embedUnavailable(String platform) {
    return '$platform では埋め込み表示を利用できません';
  }

  @override
  String get embedUnavailableMsg =>
      'Flutter の WebView は Android、iOS、macOS に対応しています。このプラットフォームでは Grafana は既定のブラウザで開きます。';

  @override
  String get openGrafana => 'Grafana を開く';

  @override
  String get grafanaUnreachable => 'Grafana が応答しません';

  @override
  String get dashboardsUnavailable => 'グラフを利用できません';

  @override
  String get dashboardsUnavailableMsg => '現在グラフを読み込めません。しばらくしてからもう一度お試しください。';

  @override
  String cameraDefaultName(int n) {
    return 'カメラ $n';
  }

  @override
  String get resumeTooltip => '再開';

  @override
  String get pauseTooltip => '一時停止';

  @override
  String get reconnectTooltip => '再接続';

  @override
  String get singleCamera => '1 台のカメラ';

  @override
  String get allCameras => 'すべてのカメラ';

  @override
  String get editCamera => 'カメラを編集';

  @override
  String get addCamera => 'カメラを追加';

  @override
  String get addCameraButton => 'カメラを追加';

  @override
  String get noCameras => 'カメラがありません';

  @override
  String get noCamerasTechnical => 'エッジカメラの MJPEG ストリーム、JPEG スナップショット、動画ファイルの URL、またはこのデバイスのカメラを追加してください。';

  @override
  String get noCamerasNormie => 'まだカメラが設定されていません。管理者に追加を依頼してください。';

  @override
  String get noCamerasConfigured => 'カメラが設定されていません';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 台のカメラ', one: '1 台のカメラ');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '「$name」の URL が無効です';
  }

  @override
  String get cameraUrl => 'ストリーム、スナップショット、動画の URL、またはデバイスのカメラ';

  @override
  String get cameraUrlError => 'http:// または https:// の URL、device:back、device:front のいずれかを入力してください';

  @override
  String get cameraExamples => '例：';

  @override
  String get cameraReconnecting => '再接続中…';

  @override
  String get cameraStreamEnded => 'ストリームが終了しました';

  @override
  String get cameraUnavailable => 'カメラを利用できません';

  @override
  String get cameraLive => 'ライブ';

  @override
  String get cameraVideo => '動画';

  @override
  String get backCamera => '背面カメラ';

  @override
  String get frontCamera => '前面カメラ';

  @override
  String get deviceCameraMissing => 'このデバイスにはそのカメラがありません';

  @override
  String get deviceCameraOneAtATime => 'このデバイスは一度に 1 台のカメラしか表示できません';

  @override
  String get deviceCameraShow => 'これを表示';

  @override
  String deviceCameraUnsupported(String platform) {
    return '$platform のアプリではデバイスのカメラは使えません';
  }

  @override
  String get videoDemoSwitch => 'デモカメラ';

  @override
  String get videoGridDefault => 'すべてのカメラを表示して開く';

  @override
  String get alertSound => 'アラート音';

  @override
  String get alertDismiss => 'アラートを閉じる';

  @override
  String get visionPerson => '人物';

  @override
  String visionPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count人');
    return '$_temp0';
  }

  @override
  String get sectionChats => 'チャット';

  @override
  String get chatsNote => 'プロジェクトのボットにリンクしたチャットは、アラートを発生と同時に受け取り、プロジェクトについてボットに質問できます。リンクしたグループでは全員が使えます。';

  @override
  String get chatsLink => 'チャットをリンク';

  @override
  String chatsLinkHow(String bot) {
    return 'ボットを使うスマートフォンでリンクを開くか、このコマンドを $bot に送ってください。グループの場合は、先にボットをグループに追加してから、そこでコマンドを送ってください。';
  }

  @override
  String get chatsTheBot => 'ボット';

  @override
  String chatsCodeExpires(String time) {
    return '1回だけ、$timeまで有効です。';
  }

  @override
  String get chatsCopyLink => 'リンクをコピー';

  @override
  String get chatsCopyCommand => 'コマンドをコピー';

  @override
  String get chatsNone => 'リンクしたチャットはまだありません。';

  @override
  String chatsLinkedBy(String date, String who) {
    return '$dateに$whoがリンク';
  }

  @override
  String chatsLinkedOn(String date) {
    return '$dateにリンク';
  }

  @override
  String chatsMuted(String codes) {
    return 'ミュート中: $codes';
  }

  @override
  String get chatsUnlink => 'リンク解除';

  @override
  String chatsUnlinkTitle(String name) {
    return '$nameのリンクを解除しますか？';
  }

  @override
  String get chatsUnlinkBody => 'アラートが届かなくなり、ボットも応答しなくなります。チャットにも通知されます。';

  @override
  String chatsLoadFailed(String error) {
    return 'チャットを読み込めませんでした: $error';
  }

  @override
  String get chatsMock => 'モックモード: ボットはメッセージを送信せずにログに記録します。';

  @override
  String get chatsOff => 'オフ: ボットにトークンがありません。';

  @override
  String get useDemoCameras => 'デモカメラを使う';

  @override
  String get videoDemoCredits => 'デモ映像：MDN のクリップ（CC0）、Big Buck Bunny と Sintel © Blender Foundation（CC BY 3.0）。';

  @override
  String videoUnsupported(String platform) {
    return '$platform のアプリでは動画ファイルを再生できません';
  }

  @override
  String get settingsSearch => '設定を検索';

  @override
  String settingsNoMatch(String query) {
    return '「$query」に一致する項目はありません';
  }

  @override
  String get groupPersonal => '個人';

  @override
  String get groupDeployment => 'デプロイ';

  @override
  String get groupAdmin => '管理';

  @override
  String get sectionAccessibility => 'アクセシビリティ';

  @override
  String get sectionLanguageRegion => '言語と地域';

  @override
  String get sectionEndpoints => 'エンドポイント';

  @override
  String get themeHeading => 'テーマ';

  @override
  String get textSize => '文字サイズ';

  @override
  String textSizeValue(String size) {
    return '文字 $size';
  }

  @override
  String get textSizePreview => 'ダッシュボード全体の文字はこのように表示されます。';

  @override
  String get textSizeSmaller => '文字を小さく';

  @override
  String get textSizeLarger => '文字を大きく';

  @override
  String get resetToDefault => 'リセット';

  @override
  String get highContrast => 'ハイコントラスト';

  @override
  String get reduceMotion => '動きを減らす';

  @override
  String get onInDeviceSettings => 'デバイスの設定でオンになっています。';

  @override
  String languageDevice(String language) {
    return 'デバイスに合わせる（$language）';
  }

  @override
  String get searchLanguages => '言語を検索';

  @override
  String get formatsHeading => '形式';

  @override
  String get temperatureUnit => '温度';

  @override
  String get unitAuto => '自動';

  @override
  String get timeFormat => '時刻';

  @override
  String get time12h => '12 時間制';

  @override
  String get time24h => '24 時間制';

  @override
  String tourWelcome(String appName) {
    return '$appName へようこそ！基本をご紹介します。';
  }

  @override
  String get tourNavigation => 'ここに画面が並んでいます。ホームでは全体の状況がわかります。ほかの画面をタップすると開きます。';

  @override
  String get tourTheme => 'ライトとダークを切り替えるか、デバイスの設定に合わせます。';

  @override
  String get tourSettings => '言語や文字サイズなどは設定にあります。このツアーもそこから再生できます。';

  @override
  String get tourSignOut => '終わったらここからサインアウトします。';

  @override
  String tourProgress(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get tourNext => '次へ';

  @override
  String get tourBack => '戻る';

  @override
  String get tourDone => 'わかりました';

  @override
  String get tourSkip => 'ツアーをスキップ';

  @override
  String get takeTour => 'ツアーを見る';

  @override
  String get takeTourSubtitle => 'ダッシュボードの簡単な紹介';

  @override
  String get navFeed => 'アクティビティ';

  @override
  String get feedEmpty => 'まだ何もありません';

  @override
  String get feedEmptyMsg => 'イベントやアラートは発生するとここに表示されます。';

  @override
  String get feedNotSetUp => 'アクティビティなし';

  @override
  String get feedNotSetUpMsg => 'このインストールはアクティビティを公開していません。';

  @override
  String get feedNotSetUpTechnical => 'プロジェクトにフィードがありません。.p4n4.json に dashboard.feed を追加してください。';

  @override
  String get feedUnavailable => 'アクティビティを読み込めません';

  @override
  String get feedUnavailableMsg => '店舗のサービスが動作しているか確認して、もう一度お試しください。';

  @override
  String feedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '確認待ち $count 件', one: '確認待ち 1 件');
    return '$_temp0';
  }

  @override
  String get feedFilterAll => 'すべて';

  @override
  String get feedFilterAlerts => 'アラート';

  @override
  String get feedFilterPending => '確認待ち';

  @override
  String get feedOlder => '以前';

  @override
  String feedActionFailed(String error) {
    return '失敗しました：$error';
  }

  @override
  String get feedDemoData => 'デモデータ';

  @override
  String get feedStatusPending => '確認待ち';

  @override
  String get feedStatusAttended => '対応済み';

  @override
  String get feedStatusDismissed => '却下';

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String get changePasswordSubtitle => 'ほかのデバイスではサインアウトされます';

  @override
  String get changePasswordTitle => '新しいパスワードを設定';

  @override
  String get changePasswordBody => '続ける前に、ご自身のパスワードを設定するよう管理者から求められています。';

  @override
  String get fieldCurrentPassword => '現在のパスワード';

  @override
  String get fieldNewPassword => '新しいパスワード';

  @override
  String get fieldRepeatPassword => '新しいパスワード (確認)';

  @override
  String get passwordsDontMatch => 'パスワードが一致しません';

  @override
  String get passwordCurrentWrong => '現在のパスワードが正しくありません';

  @override
  String get passwordChanged => 'パスワードを変更しました';

  @override
  String get signOutUserTooltip => 'すべての場所でサインアウト';

  @override
  String signOutUserTitle(String user) {
    return '$user をすべての場所でサインアウトしますか?';
  }

  @override
  String get signOutUserBody => 'すべてのデバイスで再度サインインが必要になります。パスワードは変わりません。';

  @override
  String get signOutSelfBody => 'このデバイスとほかのデバイスで再度サインインが必要になります。パスワードは変わりません。';

  @override
  String userLastSignIn(String when) {
    return '最終サインイン: $when';
  }

  @override
  String get userNeverSignedIn => 'サインイン履歴なし';

  @override
  String get userMustChangePassword => '新しいパスワードの設定が必要';

  @override
  String get mustChangeAtFirstSignIn => '初回サインイン時に自分のパスワードを設定させる';

  @override
  String get mustChangeAtNextSignIn => '次回サインイン時に新しいパスワードを設定させる';

  @override
  String get sectionAudit => '監査ログ';

  @override
  String get auditNote => 'このデプロイで誰が何を変更したか (新しい順)';

  @override
  String auditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 件の変更');
    return '$_temp0 (新しい順)';
  }

  @override
  String get auditEmpty => 'まだ変更はありません';

  @override
  String auditLoadFailed(String error) {
    return '監査ログを読み込めませんでした: $error';
  }

  @override
  String get auditLoadMore => 'さらに読み込む';

  @override
  String get sectionBanner => 'バナー';

  @override
  String get bannerNone => 'バナーなし';

  @override
  String get bannerShowing => '解除するまですべてのデバイスに表示中';

  @override
  String bannerShowingUntil(String when) {
    return '$when まですべてのデバイスに表示中';
  }

  @override
  String get bannerText => 'メッセージ';

  @override
  String get bannerHint => '本日 15〜16 時はメンテナンスです';

  @override
  String get bannerInfo => 'お知らせ';

  @override
  String get bannerWarning => '警告';

  @override
  String get bannerUntilCleared => '解除するまで';

  @override
  String bannerForHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: '$hours 時間');
    return '$_temp0';
  }

  @override
  String get bannerClear => '解除';

  @override
  String get bannerShow => '表示';

  @override
  String get viewStartTab => '最初に開くタブ';

  @override
  String get viewHomeCards => 'ホームに表示';

  @override
  String get homeCardStatus => '状態';

  @override
  String get homeCardDevice => 'デバイスの測定値';

  @override
  String get homeCardPage => 'プロジェクトページ';

  @override
  String get viewGrafanaPage => 'Grafana ページ';

  @override
  String get viewGrafanaPageHelp => '空欄: デプロイのページ';

  @override
  String get viewCameras => 'カメラ';

  @override
  String get viewCameraOverlay => 'ビジョンオーバーレイ';

  @override
  String get viewAlerts => '表示するアラート';

  @override
  String get alertsAll => 'すべて';

  @override
  String get alertsReview => '確認が必要なもののみ';

  @override
  String get alertsOff => 'なし';

  @override
  String get viewAlertSound => '確認が必要なアラートで音を鳴らす';

  @override
  String get sectionDevice => 'このデバイス';

  @override
  String get deviceKiosk => 'キオスクモード';

  @override
  String get kioskModeHelp => 'このデバイスを閲覧者アカウントに固定します。サインアウトや設定はできず、使われていないと最初の状態に戻ります';

  @override
  String get kioskNeedsAccounts => 'p4n4-api アカウントでのサインインが必要です';

  @override
  String get kioskIdleReset => '操作がないときに最初に戻す';

  @override
  String get idleSignOut => '操作がないときに管理者とパワーユーザーをサインアウト';

  @override
  String get idleNever => 'しない';

  @override
  String idleAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 分後');
    return '$_temp0';
  }

  @override
  String get startKioskTitle => 'キオスクモードをオンにする';

  @override
  String get startKioskBody => '閲覧者アカウントでこのデバイスにサインインします。ここではサインアウトや設定の変更ができず、使われていないと最初の状態に戻ります。';

  @override
  String get kioskTurnOn => 'オンにする';

  @override
  String get leaveKiosk => 'キオスクモードを終了';

  @override
  String get leaveKioskBody => '管理者アカウントでサインインしてください。このデバイスはその管理者でサインインしたままになります。';

  @override
  String get kioskNeedsViewer => '閲覧者アカウントではありません。';

  @override
  String get kioskNeedsAdmin => '管理者アカウントではありません。';

  @override
  String get startTabDefault => 'デフォルト';

  @override
  String get chartHistory => 'グラフの履歴';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 分');
    return '$_temp0';
  }

  @override
  String get defaultCamera => 'デフォルトのカメラ';

  @override
  String get defaultCameraFirst => '最初のカメラ';

  @override
  String logsTitle(String name) {
    return '$name のログ';
  }

  @override
  String logsFailed(String error) {
    return '停止しました: $error';
  }

  @override
  String get logsEnded => 'ログのストリームが終了しました';

  @override
  String get logsFollowing => '新しい行を追跡中';

  @override
  String get copyTooltip => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String get logsFilter => '絞り込み';

  @override
  String get logsEmpty => 'まだログはありません';

  @override
  String get logsNoMatch => '条件に合う行がありません';

  @override
  String get logsLatest => '最新の行へ移動';

  @override
  String get logsMenu => 'ログ';

  @override
  String get serviceConfirmRestartBody => '使用中のすべての人にとって一時的に停止します。';

  @override
  String serviceUptime(String time) {
    return '稼働 $time';
  }

  @override
  String get serviceUnhealthy => '異常';

  @override
  String get serviceStarting => '起動中';

  @override
  String serviceActions(String name) {
    return '$name の操作';
  }

  @override
  String get sectionDevices => 'デバイス';

  @override
  String devicesNote(String platform) {
    return '$platform-api に測定値を送るデバイス。それぞれ専用のキーを持ちます。';
  }

  @override
  String get devicesOnlyAdmins => 'デバイスを変更できるのは管理者だけです。';

  @override
  String devicesLoadFailed(String error) {
    return 'デバイスを読み込めませんでした: $error';
  }

  @override
  String get devicesNone => '登録済みのデバイスはまだありません。';

  @override
  String get deviceDisabled => '無効';

  @override
  String deviceLastSeen(String time) {
    return '最終確認 $time';
  }

  @override
  String get deviceNeverSeen => '未確認';

  @override
  String deviceKey(String prefix) {
    return 'キー $prefix…';
  }

  @override
  String get deviceDisable => '無効にする（サインインできなくなります）';

  @override
  String get deviceEnable => '有効にする';

  @override
  String get rotateKey => '新しいキー';

  @override
  String rotateKeyTitle(String name) {
    return '$name に新しいキーを発行しますか？';
  }

  @override
  String get rotateKeyBody => '現在のキーはすぐに使えなくなります。新しいキーをデバイスに設定してください。';

  @override
  String removeDeviceTitle(String name) {
    return '$name を削除しますか？';
  }

  @override
  String get removeDeviceBody => 'キーはすぐに使えなくなり、測定値を送れなくなります。';

  @override
  String get removeDeviceTooltip => 'デバイスを削除';

  @override
  String get showMore => 'さらに表示';

  @override
  String get addDevice => 'デバイスを追加';

  @override
  String get editDevice => 'デバイスを編集';

  @override
  String get deviceId => 'デバイス ID';

  @override
  String get deviceIdHelp => '英字、数字、ピリオド、ハイフン、アンダースコア。あとから変更できません';

  @override
  String get deviceName => '名前';

  @override
  String get deviceDescription => '説明';

  @override
  String deviceKeyTitle(String id) {
    return '$id のキー';
  }

  @override
  String get deviceKeyBody => '今すぐデバイスにコピーしてください。再表示はされません。';

  @override
  String get done => '完了';

  @override
  String get contactSupport => 'サポートに問い合わせる';

  @override
  String summaryDownFor(String time) {
    return '停止して $time';
  }

  @override
  String deviceUpdatedAt(String time) {
    return '$time に更新';
  }

  @override
  String deviceStaleSince(String time) {
    return '更新できません · $time の測定値';
  }

  @override
  String get sectionThresholds => 'しきい値';

  @override
  String get thresholdServiceDown => 'サービス停止';

  @override
  String get sensorsTitle => 'センサー';

  @override
  String get sensorsSubtitle => 'デバイスからのライブ測定値。タップすると履歴を表示します。';

  @override
  String sensorsUnavailable(String error) {
    return 'ライブ測定値がありません: $error';
  }

  @override
  String get sensorsNoBroker => 'MQTT ブローカーにまだ接続していません';

  @override
  String get sensorsWaiting => '測定値を待っています…';

  @override
  String sensorReadAt(String time) {
    return '$time に測定';
  }

  @override
  String get rangeHour => '1時間';

  @override
  String get rangeDay => '1日';

  @override
  String get rangeWeek => '1週間';

  @override
  String sensorHistoryFailed(String error) {
    return '履歴を読み込めませんでした: $error';
  }

  @override
  String get sensorHistoryEmpty => 'この期間の測定値は保存されていません';

  @override
  String sensorMin(String value) {
    return '最小 $value';
  }

  @override
  String sensorMax(String value) {
    return '最大 $value';
  }

  @override
  String get modelTitle => 'モデル';

  @override
  String get modelSubtitle => 'エッジデバイス上の推論ランナー';

  @override
  String get modelNoRunner => 'このデプロイメントには推論ランナーがないか、応答していません。';

  @override
  String modelFailed(String error) {
    return 'ランナーに接続できません: $error';
  }

  @override
  String get modelInferences => '推論回数';

  @override
  String get modelLastLatency => '直近のレイテンシ';

  @override
  String get modelLastAt => '直近の推論';

  @override
  String get modelRecent => '最近の結果';

  @override
  String get classifyTitle => '試してみる';

  @override
  String get classifyValues => '入力値';

  @override
  String classifyExpects(int expected, int count) {
    return '$expected 個中 $count 個の値';
  }

  @override
  String get classify => '分類';

  @override
  String classifyAnomaly(String score) {
    return '異常度 $score';
  }

  @override
  String get classifyNotNumbers => 'カンマか空白で区切った数値を入力してください。';

  @override
  String get commandTitle => 'コマンドを送信';

  @override
  String get commandSubtitle => 'MQTT メッセージを 1 件送信します（例: デバイスのコマンドトピック）';

  @override
  String get commandTopic => 'トピック';

  @override
  String get commandPayload => 'メッセージ';

  @override
  String get commandPayloadHelp => 'テキストまたは JSON';

  @override
  String get commandRetain => '保持（retain）';

  @override
  String commandSent(String topic, int bytes) {
    return '$topic に送信しました（$bytes バイト）';
  }

  @override
  String commandTopicNotAllowed(String topic) {
    return 'このデプロイメントでは $topic への送信は許可されていません（p4n4-api の P4N4_API_MQTT_PUBLISH_ALLOW と _DENY）。';
  }

  @override
  String commandNoBroker(String error) {
    return 'p4n4-api がブローカーに接続していません: $error';
  }

  @override
  String get commandNotAllowed => 'コマンドを送信できるのはオペレーターと管理者だけです。';

  @override
  String commandFailed(String error) {
    return '送信されませんでした: $error';
  }

  @override
  String thresholdsNote(String deployment) {
    return 'このデバイスで $deployment の測定値を高い・危険と表示する基準です。';
  }

  @override
  String thresholdLevels(String high, String critical) {
    return '$high から高い · $critical から危険';
  }

  @override
  String get thresholdServiceDownHelp => '応答しなくなったサービスは最初は警告、その後は危険になります';

  @override
  String get thresholdsReset => '既定値に戻す';

  @override
  String get fleetNoReadings => 'デバイスの測定値なし';

  @override
  String get incidentUnreachable => 'すべて';

  @override
  String incidentOngoing(String service, String start, String length) {
    return '$service が $start から停止中（$length）';
  }

  @override
  String incidentEnded(String service, String start, String end) {
    return '$service 停止 $start–$end';
  }

  @override
  String get incidentHistory => '停止の履歴';

  @override
  String incidentHistoryOf(String name) {
    return '$name: 停止';
  }

  @override
  String get incidentNone => 'このデバイスでは停止は確認されていません。';

  @override
  String get incidentNote => 'このデバイスがこのデプロイメントの状態を表示していた間に確認したものです。';

  @override
  String serviceDownFor(String time) {
    return 'オフライン · $time';
  }

  @override
  String get answerStyle => '回答スタイル';

  @override
  String get styleStandard => '標準';

  @override
  String get styleBrief => '簡潔';

  @override
  String get styleSteps => '手順ごと';

  @override
  String get styleSimple => 'やさしい言葉';

  @override
  String get styleCustom => '独自の指示';

  @override
  String get styleCustomLabel => 'アシスタントにどう答えてほしいですか？';

  @override
  String get styleCustomHelp => 'このデバイスからの質問ごとに送信されます';

  @override
  String get videoGridLight => '低速回線向けの軽量グリッド';

  @override
  String get videoGridLightHelp => 'グリッドでは動画の代わりに 2 秒ごとに新しい画像を表示します';

  @override
  String cameraFrameEvery(int seconds) {
    return '$seconds 秒ごと';
  }

  @override
  String get clearList => '消去';
}
