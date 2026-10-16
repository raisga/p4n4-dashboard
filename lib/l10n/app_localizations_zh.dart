// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navHome => '首页';

  @override
  String get navClients => '客户';

  @override
  String get navServices => '服务';

  @override
  String get navEdge => '设备';

  @override
  String get navAgent => '助手';

  @override
  String get navGrafana => '图表';

  @override
  String get navVideo => '摄像头';

  @override
  String previewingView(String view) {
    return '你正在以$view配置文件的视角查看面板';
  }

  @override
  String get backToAdmin => '返回管理员';

  @override
  String themeTooltip(String mode) {
    return '主题：$mode';
  }

  @override
  String get themeSystem => '跟随设备';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsTooltip => '设置';

  @override
  String get signOutTooltip => '退出登录';

  @override
  String get roleAdmin => '管理员';

  @override
  String get rolePower => '高级';

  @override
  String get roleNormie => '查看者';

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get add => '添加';

  @override
  String get remove => '移除';

  @override
  String get reset => '重置';

  @override
  String get delete => '删除';

  @override
  String get clear => '新对话';

  @override
  String get open => '打开';

  @override
  String get connect => '连接';

  @override
  String get signOut => '退出登录';

  @override
  String get refreshStatus => '刷新状态';

  @override
  String get healthOnline => '在线';

  @override
  String get healthOffline => '离线';

  @override
  String get healthChecking => '检查中…';

  @override
  String get healthUnknown => '未知';

  @override
  String get fieldUsername => '用户名';

  @override
  String get fieldPassword => '密码';

  @override
  String get fieldHost => '主机';

  @override
  String get fieldName => '名称';

  @override
  String get fieldView => '配置文件';

  @override
  String hostHelp(String platform) {
    return '运行 $platform 堆栈的机器。在 Android 模拟器中请使用 10.0.2.2。';
  }

  @override
  String apiBaseUrl(String platform) {
    return '$platform-api 基础 URL';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return '$platform-api 基础 URL（可选）';
  }

  @override
  String get sessionExpired => '你的会话已过期，请重新登录。';

  @override
  String get signInTag => '登录';

  @override
  String get signInConnecting => '正在连接…';

  @override
  String get signInWelcome => '欢迎';

  @override
  String get signInButton => '登录';

  @override
  String get signInWrongCredentials => '用户名或密码错误。';

  @override
  String get signInRateLimited => '尝试次数过多。请等待一分钟后重试。';

  @override
  String signInApiFailed(String platform) {
    return '无法连接 $platform-api。请检查服务器后重试。';
  }

  @override
  String get signInChooseTitle => '选择继续方式';

  @override
  String signInAuthOffNote(String platform) {
    return '$platform-api 在无需登录的模式下运行（P4N4_API_AUTH=off），因此任何人都可以选择配置文件。';
  }

  @override
  String get signInOfflineTitle => '不登录继续';

  @override
  String signInOfflineNote(String platform) {
    return '没有 $platform-api 时，服务状态通过检测端口获取，配置文件由你自行选择。';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return '无法连接 $platform-api';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return '登录需要位于 $url 的 $platform-api。请确认它正在运行且可从此设备访问，或在下方更改服务器。';
  }

  @override
  String get signInOfflineButton => '不登录继续';

  @override
  String get signInDevAccounts => '开发账号';

  @override
  String signInDevAccountsNote(String platform) {
    return '需要启用 P4N4_API_DEV_USERS=true 的 $platform-api';
  }

  @override
  String signInServer(String url) {
    return '服务器：$url';
  }

  @override
  String get signInChangeServer => '更改';

  @override
  String get roleAdminTitle => '管理员';

  @override
  String get roleAdminDesc => '拥有全部功能，另可管理客户部署、堆栈控制、用户和诊断。';

  @override
  String get rolePowerTitle => '高级用户';

  @override
  String get rolePowerDesc => '可使用所有服务和设置，但不管理部署或用户。';

  @override
  String get roleNormieTitle => '查看者';

  @override
  String get roleNormieDesc => '系统状态、图表、摄像头和助手。只查看，不更改设置。';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionAppearance => '外观';

  @override
  String get sectionLanguage => '语言';

  @override
  String get sectionConnection => '连接';

  @override
  String get sectionEdgeMetrics => '设备读数';

  @override
  String get sectionGrafana => '图表';

  @override
  String get sectionVideo => '摄像头';

  @override
  String get sectionViews => '配置文件';

  @override
  String get sectionUsers => '用户';

  @override
  String get sectionDiagnostics => '诊断';

  @override
  String get sectionAccount => '账号';

  @override
  String get sectionAbout => '关于';

  @override
  String get languageSystem => '跟随设备';

  @override
  String get fieldDeployment => '部署';

  @override
  String get resetConnection => '恢复默认连接';

  @override
  String get metricsUrl => '读数 URL';

  @override
  String get demoData => '演示数据';

  @override
  String get grafanaBaseUrl => 'Grafana 基础 URL';

  @override
  String get dashboardPath => '仪表板路径';

  @override
  String get kioskMode => '展台模式';

  @override
  String viewsSaveFailed(String error) {
    return '无法保存配置文件：$error';
  }

  @override
  String get tabOrder => '标签页顺序';

  @override
  String get resetTabOrder => '重置顺序';

  @override
  String get dragToReorder => '拖动以重新排序';

  @override
  String previewView(String view) {
    return '以$view身份查看';
  }

  @override
  String signedInAs(String user) {
    return '已以 $user 身份登录';
  }

  @override
  String get signedInWithoutAccount => '未使用账号登录';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · $platform-api 账号';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · 登录时选择';
  }

  @override
  String get licenses => '许可';

  @override
  String usersNote(String platform) {
    return '此部署中的 $platform-api 账号。配置文件的更改在用户下次刷新时生效；重置密码会使其退出登录。';
  }

  @override
  String usersLoadFailed(String error) {
    return '无法加载用户：$error';
  }

  @override
  String get usersOnlyAdmins => '只有管理员可以管理用户。';

  @override
  String userYou(String user) {
    return '$user（你）';
  }

  @override
  String get resetPasswordTooltip => '重置密码';

  @override
  String get removeUserTooltip => '移除用户';

  @override
  String get addUserButton => '添加用户';

  @override
  String get addUserTitle => '添加用户';

  @override
  String get passwordMinLength => '至少 10 个字符';

  @override
  String removeUserTitle(String user) {
    return '移除 $user？';
  }

  @override
  String get removeUserBody => '该用户将在所有地方退出登录，且无法再次登录。';

  @override
  String newPasswordTitle(String user) {
    return '$user 的新密码';
  }

  @override
  String get newPasswordHelp => '将在所有地方退出登录';

  @override
  String get diagDeployment => '部署';

  @override
  String get diagSignIn => '登录';

  @override
  String get diagView => '配置文件';

  @override
  String get diagAuthMode => '认证模式';

  @override
  String get diagAccessToken => '访问令牌';

  @override
  String get diagRefreshToken => '刷新令牌';

  @override
  String get diagSecureStorage => '安全存储';

  @override
  String get diagServices => '服务';

  @override
  String get diagChecking => '检查中…';

  @override
  String get diagNotChecked => '未检查';

  @override
  String get diagNoAccount => '无账号';

  @override
  String get diagNone => '无';

  @override
  String get diagStored => '已保存';

  @override
  String get diagAvailable => '可用';

  @override
  String get diagUnavailable => '不可用（仅存于内存）';

  @override
  String diagServicesViaApi(int online, int known) {
    return '根据 API，$known 个中有 $online 个在运行';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return '根据端口，$known 个中有 $online 个在运行';
  }

  @override
  String get tokenNone => '无（将在下次请求时获取）';

  @override
  String tokenExpired(String time) {
    return '已于 $time 过期';
  }

  @override
  String tokenValid(String time, int minutes) {
    return '有效期至 $time（$minutes 分钟）';
  }

  @override
  String get tokenUnreadable => '存在（无法读取）';

  @override
  String get checkSignIn => '检查登录';

  @override
  String get checkServices => '检查服务';

  @override
  String get copySettings => '复制设置';

  @override
  String get settingsDump => '设置导出';

  @override
  String get secretsHidden => '已隐藏密钥';

  @override
  String get summaryChecking => '正在检查你的系统…';

  @override
  String get summaryCheckingSub => '这需要几秒钟。';

  @override
  String get summaryUnavailable => '服务状态不可用';

  @override
  String get summaryUnavailableSub => '你的系统有响应，但没有报告服务状态。如果持续出现，请联系管理员。';

  @override
  String get summaryUnreachable => '无法连接你的系统';

  @override
  String get summaryUnreachableSub => '请确认设备已开机并已连接。';

  @override
  String get summaryOk => '一切正常';

  @override
  String get summaryOkSub => '你的系统运行正常。';

  @override
  String get summaryAttention => '有项目需要注意';

  @override
  String get summaryAttentionSub => '你的系统有一部分目前无法正常工作。如果几分钟内没有恢复，请联系管理员。';

  @override
  String summaryAffected(String features) {
    return '受影响：$features';
  }

  @override
  String summaryUpdated(String time) {
    return '检查于 $time';
  }

  @override
  String get featureAssistant => '助手';

  @override
  String get featureCharts => '图表';

  @override
  String get featureHistory => '数据历史';

  @override
  String get featureSensors => '传感器数据';

  @override
  String get featureAutomations => '自动化';

  @override
  String get featureDeviceAi => '设备端 AI';

  @override
  String get featureConnection => '系统连接';

  @override
  String get yourDevice => '你的设备';

  @override
  String get deviceUnavailable => '目前无法获取设备读数。';

  @override
  String get deviceLoading => '正在加载读数…';

  @override
  String get readingProcessor => '处理器';

  @override
  String get readingMemory => '内存';

  @override
  String get readingTemperature => '温度';

  @override
  String get levelNormal => '正常';

  @override
  String get levelHigh => '高';

  @override
  String get levelCritical => '非常高';

  @override
  String get levelWarm => '偏热';

  @override
  String get levelHot => '过热';

  @override
  String get deviceDetails => '详情';

  @override
  String servicesApiUnreachable(String platform) {
    return '$platform-api 没有响应，因此通过检测每个服务的端口获取状态。';
  }

  @override
  String get servicesTitle => '服务';

  @override
  String servicesSubtitle(String host) {
    return '在 $host 上运行的应用。打开一个即可直接使用。';
  }

  @override
  String get servicesSubtitlePlain => '在你的系统上运行的应用。打开一个即可使用。';

  @override
  String servicesLiveFrom(String authority) {
    return '来自 $authority 的实时状态';
  }

  @override
  String servicesContacting(String authority) {
    return '正在连接 $authority…';
  }

  @override
  String serviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个服务', one: '1 个服务');
    return '$_temp0';
  }

  @override
  String endpointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个端点', one: '1 个端点');
    return '$_temp0';
  }

  @override
  String get stackControls => '堆栈操作';

  @override
  String get stackStart => '启动';

  @override
  String get stackRestart => '重启';

  @override
  String get stackStop => '停止';

  @override
  String stackConfirmStop(String stack) {
    return '停止 $stack？';
  }

  @override
  String get stackConfirmStopBody => '在有人重新启动之前，它的服务对所有人都将停止。';

  @override
  String stackConfirmRestart(String stack) {
    return '重启 $stack？';
  }

  @override
  String get stackConfirmRestartBody => '重启期间，它的服务会短暂中断。';

  @override
  String stackJobRunning(String stack) {
    return '正在处理 $stack…';
  }

  @override
  String stackJobDone(String stack) {
    return '$stack 已完成。';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return '$stack 操作失败：$error';
  }

  @override
  String couldNotOpen(String url) {
    return '无法打开 $url';
  }

  @override
  String get tcpOnly => '无网页';

  @override
  String get stackIot => 'IoT 堆栈';

  @override
  String get stackAi => 'AI 堆栈';

  @override
  String get stackApi => 'API 网关';

  @override
  String get serviceGrafanaDesc => '仪表板和图表';

  @override
  String get serviceNodeRedDesc => '流程自动化';

  @override
  String get serviceInfluxDesc => '传感器数据历史';

  @override
  String get serviceMqttDesc => '设备消息代理';

  @override
  String get serviceOllamaDesc => '本地 AI 模型';

  @override
  String get serviceLettaDesc => '具有记忆的 AI 代理';

  @override
  String get serviceN8nDesc => '工作流自动化';

  @override
  String get serviceEiRunnerDesc => '设备端 AI（Edge Impulse）';

  @override
  String get serviceApiDesc => '所有堆栈的统一入口';

  @override
  String get serviceSwaggerDesc => '交互式 API 文档';

  @override
  String get clientsIntro => '每个部署的状态来自其 API；如果 API 没有响应，则通过检测服务端口获取。连接后，此面板及所有连接设置都会切换到该部署。';

  @override
  String get clientsTitle => '客户部署';

  @override
  String get noDeployments => '没有部署';

  @override
  String get noDeploymentsMsg => '添加带有名称和主机的客户部署，即可在此监控。';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known 在运行';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known 在运行（按端口）';
  }

  @override
  String get currentBadge => '已连接';

  @override
  String get editTooltip => '编辑';

  @override
  String get removeTooltip => '移除';

  @override
  String get removeCurrentTooltip => '请先连接到其他部署，再移除此部署';

  @override
  String get addDeployment => '添加部署';

  @override
  String get editDeployment => '编辑部署';

  @override
  String get clientName => '客户名称';

  @override
  String get apiUrlOptional => 'API URL（可选）';

  @override
  String get apiUrlHelp => '仅当 API 不在主机的 8000 端口时填写';

  @override
  String get edgeDemoSwitch => '演示数据';

  @override
  String get edgeNoMetrics => '没有设备读数';

  @override
  String edgeFetchFailed(String url, String error) {
    return '无法读取 $url：$error\n\n请在设置中将读数 URL 指向返回 README 所述 JSON 的端点。';
  }

  @override
  String get edgeUnavailable => '目前无法获取设备读数。请稍后再试。';

  @override
  String get edgeSubtitle => '设备的实时读数，每 2 秒更新。';

  @override
  String get useDemoData => '使用演示数据';

  @override
  String get edgeStale => '未更新';

  @override
  String get edgeDemoLabel => '演示数据';

  @override
  String get edgeSynthetic => '用于测试的虚构读数';

  @override
  String get edgeLive => '实时';

  @override
  String get metricInference => 'AI 响应时间';

  @override
  String get factDisk => '已用存储';

  @override
  String get factLoad => '平均负载';

  @override
  String get factUptime => '已运行';

  @override
  String sparkStart(int minutes) {
    return '$minutes 分钟前';
  }

  @override
  String get sparkNow => '现在';

  @override
  String get agentModel => '模型';

  @override
  String get agentAgent => '代理';

  @override
  String get assistantUnavailable => '助手不可用';

  @override
  String get assistantUnavailableMsg => '助手目前没有响应。请稍后再试。';

  @override
  String get assistantNotSetUp => '尚未设置助手';

  @override
  String get assistantNotSetUpMsg => '请让管理员设置一个。';

  @override
  String get assistantChat => '向你的助手提问';

  @override
  String get assistantChatMsg => '它了解你的系统当前的状态，你可以询问有关设备、数据和服务的问题。';

  @override
  String get assistantSuggestStatus => '一切运行正常吗？';

  @override
  String get assistantSuggestDevice => '我的设备现在有多忙？';

  @override
  String get assistantSuggestHelp => '你能帮我做什么？';

  @override
  String get assistantSharedModel => '此部署中的所有人都与这个模型对话。';

  @override
  String get assistantSharedAgent => '此部署中的所有人都与这个代理对话。';

  @override
  String assistantSaveFailed(String error) {
    return '无法更换助手：$error';
  }

  @override
  String get assistantErrorUnavailable => '助手目前没有响应。请稍后再试。';

  @override
  String get assistantErrorChanged => '助手已更换。请开始新对话以继续。';

  @override
  String get assistantErrorGeneric => '操作未成功。请重试。';

  @override
  String get assistantInputUnavailable => '助手目前不可用';

  @override
  String get sendTooltip => '发送';

  @override
  String get stopTooltip => '停止';

  @override
  String agentUnreachable(String backend) {
    return '$backend 没有响应';
  }

  @override
  String get agentNoModels => '未安装模型';

  @override
  String get agentNoModelsMsg => '请先在设备上下载一个模型，例如 `docker exec p4n4-ollama ollama pull llama3.2`。';

  @override
  String get agentNoAgents => '还没有代理';

  @override
  String get agentNoAgentsMsg => '请在 Letta ADE 中创建一个代理，然后重试。';

  @override
  String agentOllamaMsg(String platform) {
    return '消息会连同系统当前状态一起经 $platform-api 发送到 Ollama。历史记录仅在本次会话中保留。';
  }

  @override
  String get agentLettaMsg => 'Letta 代理会在不同会话之间保留自己的记忆。';

  @override
  String get agentMessageHint => '输入问题…（Shift+Enter 换行）';

  @override
  String get agentSelectFirst => '请先选择一个模型或代理';

  @override
  String get agentStopped => '（已停止）';

  @override
  String get agentThinking => '思考中…';

  @override
  String agentStepLookup(String what) {
    return '正在查看$what';
  }

  @override
  String get agentStepData => '正在查看数据';

  @override
  String get agentWriting => '正在撰写回答…';

  @override
  String agentElapsed(int seconds) {
    return '$seconds 秒';
  }

  @override
  String agentWaitLast(int seconds) {
    return '上一次回答用了 $seconds 秒。';
  }

  @override
  String get agentWaitHint => '回答最多可能需要一分钟。';

  @override
  String get bubbleYou => '你';

  @override
  String get bubbleAgent => '助手';

  @override
  String get bubbleError => '出了点问题';

  @override
  String get grafanaDashboards => '图表';

  @override
  String get reloadTooltip => '重新加载';

  @override
  String get backTooltip => '返回';

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String embedUnavailable(String platform) {
    return '$platform 上无法使用嵌入视图';
  }

  @override
  String get embedUnavailableMsg => 'Flutter 的 WebView 支持 Android、iOS 和 macOS。在此平台上，Grafana 会在默认浏览器中打开。';

  @override
  String get openGrafana => '打开 Grafana';

  @override
  String get grafanaUnreachable => 'Grafana 没有响应';

  @override
  String get dashboardsUnavailable => '图表不可用';

  @override
  String get dashboardsUnavailableMsg => '目前无法加载图表。请稍后再试。';

  @override
  String cameraDefaultName(int n) {
    return '摄像头 $n';
  }

  @override
  String get resumeTooltip => '继续';

  @override
  String get pauseTooltip => '暂停';

  @override
  String get reconnectTooltip => '重新连接';

  @override
  String get singleCamera => '单个摄像头';

  @override
  String get allCameras => '所有摄像头';

  @override
  String get editCamera => '编辑摄像头';

  @override
  String get addCamera => '添加摄像头';

  @override
  String get addCameraButton => '添加摄像头';

  @override
  String get noCameras => '没有摄像头';

  @override
  String get noCamerasTechnical => '添加边缘摄像头的 MJPEG 流、JPEG 快照或视频文件的 URL，或此设备上的某个摄像头。';

  @override
  String get noCamerasNormie => '尚未设置摄像头。请让管理员添加一个。';

  @override
  String get noCamerasConfigured => '未设置摄像头';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个摄像头', one: '1 个摄像头');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '“$name”的 URL 无效';
  }

  @override
  String get cameraUrl => '流、快照或视频 URL，或设备摄像头';

  @override
  String get cameraUrlError => '请输入 http:// 或 https:// URL、device:back 或 device:front';

  @override
  String get cameraExamples => '例如';

  @override
  String get cameraReconnecting => '正在重新连接…';

  @override
  String get cameraStreamEnded => '视频流已结束';

  @override
  String get cameraUnavailable => '摄像头不可用';

  @override
  String get cameraLive => '实时';

  @override
  String get cameraVideo => '视频';

  @override
  String get backCamera => '后置摄像头';

  @override
  String get frontCamera => '前置摄像头';

  @override
  String get deviceCameraMissing => '此设备没有该摄像头';

  @override
  String get deviceCameraOneAtATime => '此设备一次只能显示一个摄像头';

  @override
  String get deviceCameraShow => '显示此摄像头';

  @override
  String deviceCameraUnsupported(String platform) {
    return '$platform 上的应用无法使用设备摄像头';
  }

  @override
  String get videoDemoSwitch => '演示摄像头';

  @override
  String get videoGridDefault => '打开时显示所有摄像头';

  @override
  String get alertSound => '警报提示音';

  @override
  String get alertDismiss => '关闭警报';

  @override
  String get visionPerson => '人';

  @override
  String visionPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 人');
    return '$_temp0';
  }

  @override
  String get sectionChats => '聊天';

  @override
  String get chatsNote => '关联到项目机器人的聊天会在警报发生时立即收到，并可以向机器人询问项目情况。在已关联的群组中，所有人都可以。';

  @override
  String get chatsLink => '关联聊天';

  @override
  String chatsLinkHow(String bot) {
    return '在将使用机器人的手机上打开链接，或将此命令发送给 $bot。如果是群组，请先将机器人加入群组，再在群组中发送该命令。';
  }

  @override
  String get chatsTheBot => '机器人';

  @override
  String chatsCodeExpires(String time) {
    return '仅可使用一次，有效期至 $time。';
  }

  @override
  String get chatsCopyLink => '复制链接';

  @override
  String get chatsCopyCommand => '复制命令';

  @override
  String get chatsNone => '尚未关联任何聊天。';

  @override
  String chatsLinkedBy(String date, String who) {
    return '$date 由 $who 关联';
  }

  @override
  String chatsLinkedOn(String date) {
    return '$date 关联';
  }

  @override
  String chatsMuted(String codes) {
    return '已静音：$codes';
  }

  @override
  String get chatsUnlink => '取消关联';

  @override
  String chatsUnlinkTitle(String name) {
    return '取消关联 $name？';
  }

  @override
  String get chatsUnlinkBody => '它将不再收到警报，机器人也不再回复它。该聊天会收到通知。';

  @override
  String chatsLoadFailed(String error) {
    return '无法加载聊天：$error';
  }

  @override
  String get chatsMock => '模拟模式：机器人只记录消息，不会发送。';

  @override
  String get chatsOff => '已关闭：机器人没有令牌。';

  @override
  String get useDemoCameras => '使用演示摄像头';

  @override
  String get videoDemoCredits => '演示画面：MDN 片段（CC0）；Big Buck Bunny 和 Sintel © Blender Foundation（CC BY 3.0）。';

  @override
  String videoUnsupported(String platform) {
    return '$platform 上的应用无法播放视频文件';
  }

  @override
  String get settingsSearch => '搜索设置';

  @override
  String settingsNoMatch(String query) {
    return '没有与“$query”匹配的结果';
  }

  @override
  String get groupPersonal => '个人';

  @override
  String get groupDeployment => '部署';

  @override
  String get groupAdmin => '管理';

  @override
  String get sectionAccessibility => '辅助功能';

  @override
  String get sectionLanguageRegion => '语言和地区';

  @override
  String get sectionEndpoints => '端点';

  @override
  String get themeHeading => '主题';

  @override
  String get textSize => '文字大小';

  @override
  String textSizeValue(String size) {
    return '文字 $size';
  }

  @override
  String get textSizePreview => '这是文字在整个面板中的显示效果。';

  @override
  String get textSizeSmaller => '缩小文字';

  @override
  String get textSizeLarger => '放大文字';

  @override
  String get resetToDefault => '重置';

  @override
  String get highContrast => '高对比度';

  @override
  String get reduceMotion => '减少动态效果';

  @override
  String get onInDeviceSettings => '已在设备设置中开启。';

  @override
  String languageDevice(String language) {
    return '跟随设备（$language）';
  }

  @override
  String get searchLanguages => '搜索语言';

  @override
  String get formatsHeading => '格式';

  @override
  String get temperatureUnit => '温度';

  @override
  String get unitAuto => '自动';

  @override
  String get timeFormat => '时间';

  @override
  String get time12h => '12 小时制';

  @override
  String get time24h => '24 小时制';

  @override
  String tourWelcome(String appName) {
    return '欢迎使用 $appName！带你了解基础功能。';
  }

  @override
  String get tourNavigation => '这里是你的各个页面。首页展示整体情况；点按其他页面即可打开。';

  @override
  String get tourTheme => '在浅色和深色外观之间切换，或跟随设备设置。';

  @override
  String get tourSettings => '语言、文字大小等都在设置中。你也可以在那里重新查看本导览。';

  @override
  String get tourSignOut => '完成后在这里退出登录。';

  @override
  String tourProgress(Object current, Object total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get tourNext => '下一步';

  @override
  String get tourBack => '返回';

  @override
  String get tourDone => '知道了';

  @override
  String get tourSkip => '跳过导览';

  @override
  String get takeTour => '查看导览';

  @override
  String get takeTourSubtitle => '快速了解面板';

  @override
  String get navFeed => '动态';

  @override
  String get feedEmpty => '暂无内容';

  @override
  String get feedEmptyMsg => '事件和警报发生时会显示在这里。';

  @override
  String get feedNotSetUp => '没有动态';

  @override
  String get feedNotSetUpMsg => '此安装不发布动态。';

  @override
  String get feedNotSetUpTechnical => '该项目没有动态源：请在其 .p4n4.json 中添加 dashboard.feed。';

  @override
  String get feedUnavailable => '无法读取动态';

  @override
  String get feedUnavailableMsg => '请确认门店服务正在运行，然后重试。';

  @override
  String feedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 条待审核', one: '1 条待审核');
    return '$_temp0';
  }

  @override
  String get feedFilterAll => '全部';

  @override
  String get feedFilterAlerts => '警报';

  @override
  String get feedFilterPending => '待审核';

  @override
  String get feedOlder => '更早';

  @override
  String feedActionFailed(String error) {
    return '操作失败：$error';
  }

  @override
  String get feedDemoData => '演示数据';

  @override
  String get feedStatusPending => '待审核';

  @override
  String get feedStatusAttended => '已处理';

  @override
  String get feedStatusDismissed => '已忽略';

  @override
  String get changePassword => '更改密码';

  @override
  String get changePasswordSubtitle => '会让你在其他设备上退出登录';

  @override
  String get changePasswordTitle => '设置新密码';

  @override
  String get changePasswordBody => '管理员要求你在继续之前设置自己的密码。';

  @override
  String get fieldCurrentPassword => '当前密码';

  @override
  String get fieldNewPassword => '新密码';

  @override
  String get fieldRepeatPassword => '再次输入新密码';

  @override
  String get passwordsDontMatch => '两次输入的密码不一致';

  @override
  String get passwordCurrentWrong => '当前密码不正确';

  @override
  String get passwordChanged => '密码已更改';

  @override
  String get signOutUserTooltip => '在所有设备上退出';

  @override
  String signOutUserTitle(String user) {
    return '让 $user 在所有设备上退出登录？';
  }

  @override
  String get signOutUserBody => '对方需要在每台设备上重新登录。密码保持不变。';

  @override
  String get signOutSelfBody => '你需要在这台设备和其他设备上重新登录。密码保持不变。';

  @override
  String userLastSignIn(String when) {
    return '上次登录：$when';
  }

  @override
  String get userNeverSignedIn => '从未登录';

  @override
  String get userMustChangePassword => '需要设置新密码';

  @override
  String get mustChangeAtFirstSignIn => '首次登录时设置自己的密码';

  @override
  String get mustChangeAtNextSignIn => '下次登录时设置新密码';

  @override
  String get sectionAudit => '审计日志';

  @override
  String get auditNote => '谁在此部署中更改了什么，最新的在前';

  @override
  String auditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 项更改');
    return '$_temp0，最新的在前';
  }

  @override
  String get auditEmpty => '尚无更改';

  @override
  String auditLoadFailed(String error) {
    return '无法加载审计日志：$error';
  }

  @override
  String get auditLoadMore => '加载更多';

  @override
  String get sectionBanner => '横幅';

  @override
  String get bannerNone => '无横幅';

  @override
  String get bannerShowing => '在所有设备上显示，直到你清除';

  @override
  String bannerShowingUntil(String when) {
    return '在所有设备上显示至 $when';
  }

  @override
  String get bannerText => '消息';

  @override
  String get bannerHint => '今天 15–16 点维护';

  @override
  String get bannerInfo => '通知';

  @override
  String get bannerWarning => '警告';

  @override
  String get bannerUntilCleared => '直到清除';

  @override
  String bannerForHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: '$hours 小时');
    return '$_temp0';
  }

  @override
  String get bannerClear => '清除';

  @override
  String get bannerShow => '显示';

  @override
  String get viewStartTab => '打开时显示';

  @override
  String get viewHomeCards => '主页显示';

  @override
  String get homeCardStatus => '状态';

  @override
  String get homeCardDevice => '设备读数';

  @override
  String get homeCardPage => '项目页面';

  @override
  String get viewGrafanaPage => 'Grafana 页面';

  @override
  String get viewGrafanaPageHelp => '留空：使用部署的页面';

  @override
  String get viewCameras => '摄像头';

  @override
  String get viewCameraOverlay => '视觉叠加层';

  @override
  String get viewAlerts => '弹出的警报';

  @override
  String get alertsAll => '全部';

  @override
  String get alertsReview => '仅需审核的';

  @override
  String get alertsOff => '无';

  @override
  String get viewAlertSound => '需审核的警报响铃';

  @override
  String get sectionDevice => '此设备';

  @override
  String get deviceKiosk => '自助终端模式';

  @override
  String get kioskModeHelp => '将此设备锁定到查看者账户：无法退出登录或更改设置，无人使用时会回到初始状态';

  @override
  String get kioskNeedsAccounts => '需要使用 p4n4-api 账户登录';

  @override
  String get kioskIdleReset => '闲置时回到初始状态';

  @override
  String get idleSignOut => '闲置时让管理员和高级用户退出登录';

  @override
  String get idleNever => '从不';

  @override
  String idleAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 分钟后');
    return '$_temp0';
  }

  @override
  String get startKioskTitle => '开启自助终端模式';

  @override
  String get startKioskBody => '用查看者账户登录此设备。在这里无法退出登录或更改设置，无人使用时会回到初始状态。';

  @override
  String get kioskTurnOn => '开启';

  @override
  String get leaveKiosk => '退出自助终端模式';

  @override
  String get leaveKioskBody => '请用管理员账户登录。此设备随后会保持该管理员的登录。';

  @override
  String get kioskNeedsViewer => '这不是查看者账户。';

  @override
  String get kioskNeedsAdmin => '这不是管理员账户。';

  @override
  String get startTabDefault => '默认';

  @override
  String get chartHistory => '图表历史';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 分钟');
    return '$_temp0';
  }

  @override
  String get defaultCamera => '默认摄像头';

  @override
  String get defaultCameraFirst => '第一个';
}
