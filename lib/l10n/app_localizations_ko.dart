// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get navHome => '홈';

  @override
  String get navClients => '고객';

  @override
  String get navServices => '서비스';

  @override
  String get navEdge => '기기';

  @override
  String get navAgent => '어시스턴트';

  @override
  String get navGrafana => '차트';

  @override
  String get navVideo => '카메라';

  @override
  String previewingView(String view) {
    return '$view 프로필로 대시보드를 보고 있습니다';
  }

  @override
  String get backToAdmin => '관리자로 돌아가기';

  @override
  String themeTooltip(String mode) {
    return '테마: $mode';
  }

  @override
  String get themeSystem => '기기 설정 따르기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get settingsTooltip => '설정';

  @override
  String get signOutTooltip => '로그아웃';

  @override
  String get roleAdmin => '관리자';

  @override
  String get rolePower => '고급';

  @override
  String get roleNormie => '열람자';

  @override
  String get retry => '다시 시도';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get add => '추가';

  @override
  String get remove => '제거';

  @override
  String get reset => '초기화';

  @override
  String get delete => '삭제';

  @override
  String get clear => '새 대화';

  @override
  String get open => '열기';

  @override
  String get connect => '연결';

  @override
  String get signOut => '로그아웃';

  @override
  String get refreshStatus => '상태 새로고침';

  @override
  String get healthOnline => '온라인';

  @override
  String get healthOffline => '오프라인';

  @override
  String get healthChecking => '확인 중…';

  @override
  String get healthUnknown => '알 수 없음';

  @override
  String get fieldUsername => '사용자 이름';

  @override
  String get fieldPassword => '비밀번호';

  @override
  String get fieldHost => '호스트';

  @override
  String get fieldName => '이름';

  @override
  String get fieldView => '프로필';

  @override
  String hostHelp(String platform) {
    return '$platform 스택을 실행하는 컴퓨터입니다. Android 에뮬레이터에서는 10.0.2.2를 사용하세요.';
  }

  @override
  String apiBaseUrl(String platform) {
    return '$platform-api 기본 URL';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return '$platform-api 기본 URL(선택)';
  }

  @override
  String get sessionExpired => '세션이 만료되었습니다. 다시 로그인하세요.';

  @override
  String get signInTag => '로그인';

  @override
  String get signInConnecting => '연결 중…';

  @override
  String get signInWelcome => '환영합니다';

  @override
  String get signInButton => '로그인';

  @override
  String get signInWrongCredentials => '사용자 이름 또는 비밀번호가 올바르지 않습니다.';

  @override
  String get signInRateLimited => '시도 횟수가 너무 많습니다. 1분 후 다시 시도하세요.';

  @override
  String signInApiFailed(String platform) {
    return '$platform-api에 연결할 수 없습니다. 서버를 확인하고 다시 시도하세요.';
  }

  @override
  String get signInChooseTitle => '계속할 방법을 선택하세요';

  @override
  String signInAuthOffNote(String platform) {
    return '$platform-api가 로그인 없이 실행 중이므로(P4N4_API_AUTH=off) 누구나 프로필을 선택할 수 있습니다.';
  }

  @override
  String get signInOfflineTitle => '로그인하지 않고 계속';

  @override
  String signInOfflineNote(String platform) {
    return '$platform-api가 없으면 포트를 확인해 서비스 상태를 가져오고, 프로필은 직접 선택합니다.';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return '$platform-api에 연결할 수 없습니다';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return '로그인하려면 $url의 $platform-api가 필요합니다. 실행 중이며 이 기기에서 접근할 수 있는지 확인하거나 아래에서 서버를 변경하세요.';
  }

  @override
  String get signInOfflineButton => '로그인하지 않고 계속';

  @override
  String get signInDevAccounts => '개발용 계정';

  @override
  String signInDevAccountsNote(String platform) {
    return 'P4N4_API_DEV_USERS=true로 설정된 $platform-api가 필요합니다';
  }

  @override
  String signInServer(String url) {
    return '서버: $url';
  }

  @override
  String get signInChangeServer => '변경';

  @override
  String get roleAdminTitle => '관리자';

  @override
  String get roleAdminDesc => '모든 기능과 함께 고객 배포, 스택 제어, 사용자, 진단을 관리합니다.';

  @override
  String get rolePowerTitle => '고급 사용자';

  @override
  String get rolePowerDesc => '모든 서비스와 설정을 사용하지만 배포나 사용자는 관리하지 않습니다.';

  @override
  String get roleNormieTitle => '열람자';

  @override
  String get roleNormieDesc => '시스템 상태, 차트, 카메라, 어시스턴트. 설정을 바꾸지 않고 볼 수 있습니다.';

  @override
  String get settingsTitle => '설정';

  @override
  String get sectionAppearance => '모양';

  @override
  String get sectionLanguage => '언어';

  @override
  String get sectionConnection => '연결';

  @override
  String get sectionEdgeMetrics => '기기 측정값';

  @override
  String get sectionGrafana => '차트';

  @override
  String get sectionVideo => '카메라';

  @override
  String get sectionViews => '프로필';

  @override
  String get sectionUsers => '사용자';

  @override
  String get sectionDiagnostics => '진단';

  @override
  String get sectionAccount => '계정';

  @override
  String get sectionAbout => '정보';

  @override
  String get languageSystem => '기기 설정 따르기';

  @override
  String get fieldDeployment => '배포';

  @override
  String get resetConnection => '기본 연결로 복원';

  @override
  String get metricsUrl => '측정값 URL';

  @override
  String get demoData => '데모 데이터';

  @override
  String get grafanaBaseUrl => 'Grafana 기본 URL';

  @override
  String get dashboardPath => '대시보드 경로';

  @override
  String get kioskMode => '키오스크 모드';

  @override
  String viewsSaveFailed(String error) {
    return '프로필을 저장하지 못했습니다: $error';
  }

  @override
  String get tabOrder => '탭 순서';

  @override
  String get resetTabOrder => '순서 초기화';

  @override
  String get dragToReorder => '드래그하여 순서 변경';

  @override
  String previewView(String view) {
    return '$view(으)로 보기';
  }

  @override
  String signedInAs(String user) {
    return '$user(으)로 로그인됨';
  }

  @override
  String get signedInWithoutAccount => '계정 없이 로그인됨';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · $platform-api 계정';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · 로그인할 때 선택';
  }

  @override
  String get licenses => '라이선스';

  @override
  String usersNote(String platform) {
    return '이 배포의 $platform-api 계정입니다. 프로필 변경은 사용자의 다음 새로고침 때 적용되며, 비밀번호를 재설정하면 해당 사용자는 로그아웃됩니다.';
  }

  @override
  String usersLoadFailed(String error) {
    return '사용자를 불러올 수 없습니다: $error';
  }

  @override
  String get usersOnlyAdmins => '관리자만 사용자를 관리할 수 있습니다.';

  @override
  String userYou(String user) {
    return '$user(나)';
  }

  @override
  String get resetPasswordTooltip => '비밀번호 재설정';

  @override
  String get removeUserTooltip => '사용자 제거';

  @override
  String get addUserButton => '사용자 추가';

  @override
  String get addUserTitle => '사용자 추가';

  @override
  String get passwordMinLength => '10자 이상';

  @override
  String removeUserTitle(String user) {
    return '$user을(를) 제거할까요?';
  }

  @override
  String get removeUserBody => '모든 곳에서 로그아웃되며 다시 로그인할 수 없습니다.';

  @override
  String newPasswordTitle(String user) {
    return '$user의 새 비밀번호';
  }

  @override
  String get newPasswordHelp => '모든 곳에서 로그아웃됩니다';

  @override
  String get diagDeployment => '배포';

  @override
  String get diagSignIn => '로그인';

  @override
  String get diagView => '프로필';

  @override
  String get diagAuthMode => '인증 모드';

  @override
  String get diagAccessToken => '액세스 토큰';

  @override
  String get diagRefreshToken => '갱신 토큰';

  @override
  String get diagSecureStorage => '보안 저장소';

  @override
  String get diagServices => '서비스';

  @override
  String get diagChecking => '확인 중…';

  @override
  String get diagNotChecked => '확인 안 됨';

  @override
  String get diagNoAccount => '계정 없음';

  @override
  String get diagNone => '없음';

  @override
  String get diagStored => '저장됨';

  @override
  String get diagAvailable => '사용 가능';

  @override
  String get diagUnavailable => '사용 불가(메모리에만 저장)';

  @override
  String diagServicesViaApi(int online, int known) {
    return 'API 기준 $known개 중 $online개 실행 중';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return '포트 기준 $known개 중 $online개 실행 중';
  }

  @override
  String get tokenNone => '없음(다음 요청 때 받음)';

  @override
  String tokenExpired(String time) {
    return '$time에 만료됨';
  }

  @override
  String tokenValid(String time, int minutes) {
    return '$time까지 유효($minutes분)';
  }

  @override
  String get tokenUnreadable => '있음(읽을 수 없음)';

  @override
  String get checkSignIn => '로그인 확인';

  @override
  String get checkServices => '서비스 확인';

  @override
  String get copySettings => '설정 복사';

  @override
  String get settingsDump => '설정 내보내기';

  @override
  String get secretsHidden => '비밀 정보 숨김';

  @override
  String get summaryChecking => '시스템을 확인하는 중…';

  @override
  String get summaryCheckingSub => '몇 초 정도 걸립니다.';

  @override
  String get summaryUnavailable => '서비스 상태를 확인할 수 없음';

  @override
  String get summaryUnavailableSub => '시스템은 응답하지만 서비스 상태를 보고하지 않았습니다. 계속되면 관리자에게 문의하세요.';

  @override
  String get summaryUnreachable => '시스템에 연결할 수 없습니다';

  @override
  String get summaryUnreachableSub => '기기가 켜져 있고 연결되어 있는지 확인하세요.';

  @override
  String get summaryOk => '모두 정상입니다';

  @override
  String get summaryOkSub => '시스템이 정상적으로 작동하고 있습니다.';

  @override
  String get summaryAttention => '확인이 필요한 항목이 있습니다';

  @override
  String get summaryAttentionSub => '시스템 일부가 지금 작동하지 않습니다. 몇 분 안에 복구되지 않으면 관리자에게 문의하세요.';

  @override
  String summaryAffected(String features) {
    return '영향 받음: $features';
  }

  @override
  String summaryUpdated(String time) {
    return '$time에 확인함';
  }

  @override
  String get featureAssistant => '어시스턴트';

  @override
  String get featureCharts => '차트';

  @override
  String get featureHistory => '데이터 기록';

  @override
  String get featureSensors => '센서 데이터';

  @override
  String get featureAutomations => '자동화';

  @override
  String get featureDeviceAi => '기기 내 AI';

  @override
  String get featureConnection => '시스템 연결';

  @override
  String get yourDevice => '내 기기';

  @override
  String get deviceUnavailable => '지금은 기기 측정값을 사용할 수 없습니다.';

  @override
  String get deviceLoading => '측정값을 불러오는 중…';

  @override
  String get readingProcessor => '프로세서';

  @override
  String get readingMemory => '메모리';

  @override
  String get readingTemperature => '온도';

  @override
  String get levelNormal => '정상';

  @override
  String get levelHigh => '높음';

  @override
  String get levelCritical => '매우 높음';

  @override
  String get levelWarm => '따뜻함';

  @override
  String get levelHot => '뜨거움';

  @override
  String get deviceDetails => '세부정보';

  @override
  String servicesApiUnreachable(String platform) {
    return '$platform-api가 응답하지 않아 각 서비스의 포트를 확인해 상태를 가져옵니다.';
  }

  @override
  String get servicesTitle => '서비스';

  @override
  String servicesSubtitle(String host) {
    return '$host에서 실행 중인 애플리케이션입니다. 열어서 바로 사용하세요.';
  }

  @override
  String get servicesSubtitlePlain => '시스템에서 실행 중인 애플리케이션입니다. 열어서 사용하세요.';

  @override
  String servicesLiveFrom(String authority) {
    return '$authority의 실시간 상태';
  }

  @override
  String servicesContacting(String authority) {
    return '$authority에 연결 중…';
  }

  @override
  String serviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '서비스 $count개', one: '서비스 1개');
    return '$_temp0';
  }

  @override
  String endpointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '엔드포인트 $count개', one: '엔드포인트 1개');
    return '$_temp0';
  }

  @override
  String get stackControls => '스택 작업';

  @override
  String get stackStart => '시작';

  @override
  String get stackRestart => '다시 시작';

  @override
  String get stackStop => '중지';

  @override
  String stackConfirmStop(String stack) {
    return '$stack을(를) 중지할까요?';
  }

  @override
  String get stackConfirmStopBody => '누군가 다시 시작할 때까지 모든 사용자에게 해당 서비스가 중단됩니다.';

  @override
  String stackConfirmRestart(String stack) {
    return '$stack을(를) 다시 시작할까요?';
  }

  @override
  String get stackConfirmRestartBody => '다시 시작하는 동안 해당 서비스가 잠시 중단됩니다.';

  @override
  String stackJobRunning(String stack) {
    return '$stack 작업 중…';
  }

  @override
  String stackJobDone(String stack) {
    return '$stack 작업이 끝났습니다.';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return '$stack 작업에 실패했습니다: $error';
  }

  @override
  String couldNotOpen(String url) {
    return '$url을(를) 열 수 없습니다';
  }

  @override
  String get tcpOnly => '웹 페이지 없음';

  @override
  String get stackIot => 'IoT 스택';

  @override
  String get stackAi => 'AI 스택';

  @override
  String get stackApi => 'API 게이트웨이';

  @override
  String get serviceGrafanaDesc => '대시보드와 차트';

  @override
  String get serviceNodeRedDesc => '플로 자동화';

  @override
  String get serviceInfluxDesc => '센서 데이터 기록';

  @override
  String get serviceMqttDesc => '기기용 메시지 브로커';

  @override
  String get serviceOllamaDesc => '로컬 AI 모델';

  @override
  String get serviceLettaDesc => '기억을 가진 AI 에이전트';

  @override
  String get serviceN8nDesc => '워크플로 자동화';

  @override
  String get serviceEiRunnerDesc => '기기 내 AI(Edge Impulse)';

  @override
  String get serviceApiDesc => '모든 스택의 단일 진입점';

  @override
  String get serviceSwaggerDesc => '대화형 API 문서';

  @override
  String get clientsIntro => '각 배포의 상태는 해당 API에서, 응답하지 않으면 서비스 포트 확인으로 가져옵니다. 연결하면 이 대시보드와 모든 연결 설정이 해당 배포로 전환됩니다.';

  @override
  String get clientsTitle => '고객 배포';

  @override
  String get noDeployments => '배포 없음';

  @override
  String get noDeploymentsMsg => '이름과 호스트로 고객 배포를 추가하면 여기서 모니터링할 수 있습니다.';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known 실행 중';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known 실행 중(포트 기준)';
  }

  @override
  String get currentBadge => '연결됨';

  @override
  String get editTooltip => '편집';

  @override
  String get removeTooltip => '제거';

  @override
  String get removeCurrentTooltip => '이 배포를 제거하려면 다른 배포에 연결하세요';

  @override
  String get addDeployment => '배포 추가';

  @override
  String get editDeployment => '배포 편집';

  @override
  String get clientName => '고객 이름';

  @override
  String get apiUrlOptional => 'API URL(선택)';

  @override
  String get apiUrlHelp => 'API가 호스트의 8000번 포트에 없는 경우에만';

  @override
  String get edgeDemoSwitch => '데모 데이터';

  @override
  String get edgeNoMetrics => '기기 측정값 없음';

  @override
  String edgeFetchFailed(String url, String error) {
    return '$url을(를) 읽을 수 없습니다: $error\n\n설정의 측정값 URL을 README에 설명된 JSON을 반환하는 엔드포인트로 지정하세요.';
  }

  @override
  String get edgeUnavailable => '지금은 기기 측정값을 사용할 수 없습니다. 잠시 후 다시 시도하세요.';

  @override
  String get edgeSubtitle => '기기의 실시간 측정값, 2초마다 갱신.';

  @override
  String get useDemoData => '데모 데이터 사용';

  @override
  String get edgeStale => '오래된 값';

  @override
  String get edgeDemoLabel => '데모 데이터';

  @override
  String get edgeSynthetic => '테스트용 가상 측정값';

  @override
  String get edgeLive => '실시간';

  @override
  String get metricInference => 'AI 응답 시간';

  @override
  String get factDisk => '사용 중인 저장 공간';

  @override
  String get factLoad => '평균 부하';

  @override
  String get factUptime => '가동 시간';

  @override
  String sparkStart(int minutes) {
    return '$minutes분 전';
  }

  @override
  String get sparkNow => '지금';

  @override
  String get agentModel => '모델';

  @override
  String get agentAgent => '에이전트';

  @override
  String get assistantUnavailable => '어시스턴트를 사용할 수 없음';

  @override
  String get assistantUnavailableMsg => '어시스턴트가 지금 응답하지 않습니다. 잠시 후 다시 시도하세요.';

  @override
  String get assistantNotSetUp => '설정된 어시스턴트가 없습니다';

  @override
  String get assistantNotSetUpMsg => '관리자에게 설정을 요청하세요.';

  @override
  String get assistantChat => '어시스턴트에게 물어보세요';

  @override
  String get assistantChatMsg => '시스템의 현재 상태를 알고 있으니 기기, 데이터, 서비스에 대해 물어볼 수 있습니다.';

  @override
  String get assistantSuggestStatus => '모두 정상적으로 작동하나요?';

  @override
  String get assistantSuggestDevice => '지금 내 기기는 얼마나 바쁜가요?';

  @override
  String get assistantSuggestHelp => '무엇을 도와줄 수 있나요?';

  @override
  String get assistantSharedModel => '이 배포의 모든 사용자가 이 모델과 대화합니다.';

  @override
  String get assistantSharedAgent => '이 배포의 모든 사용자가 이 에이전트와 대화합니다.';

  @override
  String assistantSaveFailed(String error) {
    return '어시스턴트를 변경할 수 없습니다: $error';
  }

  @override
  String get assistantErrorUnavailable => '어시스턴트가 지금 응답하지 않습니다. 잠시 후 다시 시도하세요.';

  @override
  String get assistantErrorChanged => '어시스턴트가 변경되었습니다. 계속하려면 새 대화를 시작하세요.';

  @override
  String get assistantErrorGeneric => '실패했습니다. 다시 시도하세요.';

  @override
  String get assistantInputUnavailable => '지금은 어시스턴트를 사용할 수 없습니다';

  @override
  String get sendTooltip => '보내기';

  @override
  String get stopTooltip => '중지';

  @override
  String agentUnreachable(String backend) {
    return '$backend이(가) 응답하지 않습니다';
  }

  @override
  String get agentNoModels => '설치된 모델 없음';

  @override
  String get agentNoModelsMsg => '먼저 기기에 모델을 내려받으세요. 예: `docker exec p4n4-ollama ollama pull llama3.2`';

  @override
  String get agentNoAgents => '아직 에이전트가 없습니다';

  @override
  String get agentNoAgentsMsg => 'Letta ADE에서 에이전트를 만든 후 다시 시도하세요.';

  @override
  String agentOllamaMsg(String platform) {
    return '메시지는 시스템의 현재 상태와 함께 $platform-api를 거쳐 Ollama로 전달됩니다. 기록은 이 세션 동안만 유지됩니다.';
  }

  @override
  String get agentLettaMsg => 'Letta 에이전트는 세션 간에 자체 기억을 유지합니다.';

  @override
  String get agentMessageHint => '질문을 입력하세요…(Shift+Enter로 줄바꿈)';

  @override
  String get agentSelectFirst => '먼저 모델이나 에이전트를 선택하세요';

  @override
  String get agentStopped => '(중지됨)';

  @override
  String get agentThinking => '생각 중…';

  @override
  String agentStepLookup(String what) {
    return '$what 확인 중';
  }

  @override
  String get agentStepData => '데이터 확인 중';

  @override
  String get agentWriting => '답변 작성 중…';

  @override
  String agentElapsed(int seconds) {
    return '$seconds초';
  }

  @override
  String agentWaitLast(int seconds) {
    return '지난 답변은 $seconds초 걸렸습니다.';
  }

  @override
  String get agentWaitHint => '답변에 최대 1분이 걸릴 수 있습니다.';

  @override
  String get bubbleYou => '나';

  @override
  String get bubbleAgent => '어시스턴트';

  @override
  String get bubbleError => '문제가 발생했습니다';

  @override
  String get grafanaDashboards => '차트';

  @override
  String get reloadTooltip => '새로고침';

  @override
  String get backTooltip => '뒤로';

  @override
  String get openInBrowser => '브라우저에서 열기';

  @override
  String embedUnavailable(String platform) {
    return '$platform에서는 내장 보기를 사용할 수 없습니다';
  }

  @override
  String get embedUnavailableMsg => 'Flutter WebView는 Android, iOS, macOS를 지원합니다. 이 플랫폼에서는 Grafana가 기본 브라우저에서 열립니다.';

  @override
  String get openGrafana => 'Grafana 열기';

  @override
  String get grafanaUnreachable => 'Grafana가 응답하지 않습니다';

  @override
  String get dashboardsUnavailable => '차트를 사용할 수 없음';

  @override
  String get dashboardsUnavailableMsg => '지금은 차트를 불러올 수 없습니다. 잠시 후 다시 시도하세요.';

  @override
  String cameraDefaultName(int n) {
    return '카메라 $n';
  }

  @override
  String get resumeTooltip => '재개';

  @override
  String get pauseTooltip => '일시정지';

  @override
  String get reconnectTooltip => '다시 연결';

  @override
  String get singleCamera => '카메라 한 대';

  @override
  String get allCameras => '모든 카메라';

  @override
  String get editCamera => '카메라 편집';

  @override
  String get addCamera => '카메라 추가';

  @override
  String get addCameraButton => '카메라 추가';

  @override
  String get noCameras => '카메라 없음';

  @override
  String get noCamerasTechnical => '엣지 카메라의 MJPEG 스트림, JPEG 스냅샷 또는 동영상 파일 URL이나 이 기기의 카메라를 추가하세요.';

  @override
  String get noCamerasNormie => '아직 설정된 카메라가 없습니다. 관리자에게 추가를 요청하세요.';

  @override
  String get noCamerasConfigured => '설정된 카메라 없음';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '카메라 $count대', one: '카메라 1대');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '\'$name\'의 URL이 올바르지 않습니다';
  }

  @override
  String get cameraUrl => '스트림, 스냅샷, 동영상 URL 또는 기기 카메라';

  @override
  String get cameraUrlError => 'http:// 또는 https:// URL, device:back, device:front 중 하나를 입력하세요';

  @override
  String get cameraExamples => '예:';

  @override
  String get cameraReconnecting => '다시 연결 중…';

  @override
  String get cameraStreamEnded => '스트림이 종료되었습니다';

  @override
  String get cameraUnavailable => '카메라를 사용할 수 없음';

  @override
  String get cameraLive => '실시간';

  @override
  String get cameraVideo => '동영상';

  @override
  String get backCamera => '후면 카메라';

  @override
  String get frontCamera => '전면 카메라';

  @override
  String get deviceCameraMissing => '이 기기에는 해당 카메라가 없습니다';

  @override
  String get deviceCameraOneAtATime => '이 기기는 한 번에 카메라 하나만 표시합니다';

  @override
  String get deviceCameraShow => '이 카메라 표시';

  @override
  String deviceCameraUnsupported(String platform) {
    return '$platform 앱에서는 기기 카메라가 작동하지 않습니다';
  }

  @override
  String get videoDemoSwitch => '데모 카메라';

  @override
  String get videoGridDefault => '모든 카메라를 표시하며 열기';

  @override
  String get alertSound => '알림 소리';

  @override
  String get alertDismiss => '알림 닫기';

  @override
  String get visionPerson => '사람';

  @override
  String visionPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count명');
    return '$_temp0';
  }

  @override
  String get sectionChats => '채팅';

  @override
  String get chatsNote => '프로젝트 봇에 연결된 채팅은 알림을 발생 즉시 받고, 봇에게 프로젝트에 대해 물어볼 수 있습니다. 연결된 그룹에서는 누구나 가능합니다.';

  @override
  String get chatsLink => '채팅 연결';

  @override
  String chatsLinkHow(String bot) {
    return '봇을 사용할 휴대폰에서 링크를 열거나 이 명령을 $bot에게 보내세요. 그룹이라면 먼저 봇을 그룹에 추가한 뒤 그곳에서 명령을 보내세요.';
  }

  @override
  String get chatsTheBot => '봇';

  @override
  String chatsCodeExpires(String time) {
    return '한 번만, $time까지 사용할 수 있습니다.';
  }

  @override
  String get chatsCopyLink => '링크 복사';

  @override
  String get chatsCopyCommand => '명령 복사';

  @override
  String get chatsNone => '아직 연결된 채팅이 없습니다.';

  @override
  String chatsLinkedBy(String date, String who) {
    return '$date에 $who님이 연결함';
  }

  @override
  String chatsLinkedOn(String date) {
    return '$date에 연결됨';
  }

  @override
  String chatsMuted(String codes) {
    return '음소거: $codes';
  }

  @override
  String get chatsUnlink => '연결 해제';

  @override
  String chatsUnlinkTitle(String name) {
    return '$name 연결을 해제할까요?';
  }

  @override
  String get chatsUnlinkBody => '더 이상 알림을 받지 않고 봇도 응답하지 않습니다. 채팅에 알려 드립니다.';

  @override
  String chatsLoadFailed(String error) {
    return '채팅을 불러오지 못했습니다: $error';
  }

  @override
  String get chatsMock => '모의 모드: 봇이 메시지를 보내지 않고 기록만 합니다.';

  @override
  String get chatsOff => '꺼짐: 봇에 토큰이 없습니다.';

  @override
  String get useDemoCameras => '데모 카메라 사용';

  @override
  String get videoDemoCredits => '데모 영상: MDN 클립(CC0), Big Buck Bunny 및 Sintel © Blender Foundation(CC BY 3.0).';

  @override
  String videoUnsupported(String platform) {
    return '$platform 앱에서는 동영상 파일이 재생되지 않습니다';
  }

  @override
  String get settingsSearch => '설정 검색';

  @override
  String settingsNoMatch(String query) {
    return '\'$query\'와(과) 일치하는 항목이 없습니다';
  }

  @override
  String get groupPersonal => '개인';

  @override
  String get groupDeployment => '배포';

  @override
  String get groupAdmin => '관리';

  @override
  String get sectionAccessibility => '접근성';

  @override
  String get sectionLanguageRegion => '언어 및 지역';

  @override
  String get sectionEndpoints => '엔드포인트';

  @override
  String get themeHeading => '테마';

  @override
  String get textSize => '글자 크기';

  @override
  String textSizeValue(String size) {
    return '글자 $size';
  }

  @override
  String get textSizePreview => '대시보드 전체의 글자가 이렇게 보입니다.';

  @override
  String get textSizeSmaller => '글자 작게';

  @override
  String get textSizeLarger => '글자 크게';

  @override
  String get resetToDefault => '초기화';

  @override
  String get highContrast => '고대비';

  @override
  String get reduceMotion => '동작 줄이기';

  @override
  String get onInDeviceSettings => '기기 설정에서 켜져 있습니다.';

  @override
  String languageDevice(String language) {
    return '기기 설정 따르기($language)';
  }

  @override
  String get searchLanguages => '언어 검색';

  @override
  String get formatsHeading => '형식';

  @override
  String get temperatureUnit => '온도';

  @override
  String get unitAuto => '자동';

  @override
  String get timeFormat => '시간';

  @override
  String get time12h => '12시간';

  @override
  String get time24h => '24시간';

  @override
  String tourWelcome(String appName) {
    return '$appName에 오신 것을 환영합니다! 기본 사항을 안내해 드릴게요.';
  }

  @override
  String get tourNavigation => '여기에 화면이 있습니다. 홈에서는 전체 상황을 볼 수 있고, 다른 화면을 탭하면 열립니다.';

  @override
  String get tourTheme => '라이트와 다크 모양을 전환하거나 기기 설정을 따릅니다.';

  @override
  String get tourSettings => '언어, 글자 크기 등은 설정에 있습니다. 거기서 이 둘러보기를 다시 볼 수도 있습니다.';

  @override
  String get tourSignOut => '끝나면 여기서 로그아웃하세요.';

  @override
  String tourProgress(Object current, Object total) {
    return '$current/$total';
  }

  @override
  String get tourNext => '다음';

  @override
  String get tourBack => '뒤로';

  @override
  String get tourDone => '확인';

  @override
  String get tourSkip => '둘러보기 건너뛰기';

  @override
  String get takeTour => '둘러보기';

  @override
  String get takeTourSubtitle => '대시보드를 빠르게 살펴보기';

  @override
  String get navFeed => '활동';

  @override
  String get feedEmpty => '아직 없음';

  @override
  String get feedEmptyMsg => '이벤트와 알림이 발생하면 여기에 표시됩니다.';

  @override
  String get feedNotSetUp => '활동 없음';

  @override
  String get feedNotSetUpMsg => '이 설치는 활동을 게시하지 않습니다.';

  @override
  String get feedNotSetUpTechnical => '프로젝트에 피드가 없습니다. .p4n4.json에 dashboard.feed를 추가하세요.';

  @override
  String get feedUnavailable => '활동을 읽을 수 없습니다';

  @override
  String get feedUnavailableMsg => '매장 서비스가 실행 중인지 확인한 후 다시 시도하세요.';

  @override
  String feedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '검토 대기 $count건', one: '검토 대기 1건');
    return '$_temp0';
  }

  @override
  String get feedFilterAll => '전체';

  @override
  String get feedFilterAlerts => '알림';

  @override
  String get feedFilterPending => '검토 대기';

  @override
  String get feedOlder => '이전';

  @override
  String feedActionFailed(String error) {
    return '실패했습니다: $error';
  }

  @override
  String get feedDemoData => '데모 데이터';

  @override
  String get feedStatusPending => '검토 대기';

  @override
  String get feedStatusAttended => '처리됨';

  @override
  String get feedStatusDismissed => '무시됨';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String get changePasswordSubtitle => '다른 기기에서는 로그아웃됩니다';

  @override
  String get changePasswordTitle => '새 비밀번호 설정';

  @override
  String get changePasswordBody => '계속하기 전에 본인 비밀번호를 설정하라고 관리자가 요청했습니다.';

  @override
  String get fieldCurrentPassword => '현재 비밀번호';

  @override
  String get fieldNewPassword => '새 비밀번호';

  @override
  String get fieldRepeatPassword => '새 비밀번호 확인';

  @override
  String get passwordsDontMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get passwordCurrentWrong => '현재 비밀번호가 올바르지 않습니다';

  @override
  String get passwordChanged => '비밀번호를 변경했습니다';

  @override
  String get signOutUserTooltip => '모든 곳에서 로그아웃';

  @override
  String signOutUserTitle(String user) {
    return '$user을(를) 모든 곳에서 로그아웃할까요?';
  }

  @override
  String get signOutUserBody => '모든 기기에서 다시 로그인해야 합니다. 비밀번호는 그대로입니다.';

  @override
  String get signOutSelfBody => '이 기기와 다른 기기에서 다시 로그인해야 합니다. 비밀번호는 그대로입니다.';

  @override
  String userLastSignIn(String when) {
    return '마지막 로그인: $when';
  }

  @override
  String get userNeverSignedIn => '로그인한 적 없음';

  @override
  String get userMustChangePassword => '새 비밀번호 설정 필요';

  @override
  String get mustChangeAtFirstSignIn => '처음 로그인할 때 본인 비밀번호 설정';

  @override
  String get mustChangeAtNextSignIn => '다음 로그인 때 새 비밀번호 설정';

  @override
  String get sectionAudit => '감사 로그';

  @override
  String get auditNote => '이 배포에서 누가 무엇을 바꿨는지, 최신순';

  @override
  String auditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '변경 $count건');
    return '$_temp0, 최신순';
  }

  @override
  String get auditEmpty => '아직 변경 사항이 없습니다';

  @override
  String auditLoadFailed(String error) {
    return '감사 로그를 불러오지 못했습니다: $error';
  }

  @override
  String get auditLoadMore => '더 보기';

  @override
  String get sectionBanner => '배너';

  @override
  String get bannerNone => '배너 없음';

  @override
  String get bannerShowing => '해제할 때까지 모든 기기에 표시 중';

  @override
  String bannerShowingUntil(String when) {
    return '$when까지 모든 기기에 표시 중';
  }

  @override
  String get bannerText => '메시지';

  @override
  String get bannerHint => '오늘 오후 3–4시 점검';

  @override
  String get bannerInfo => '안내';

  @override
  String get bannerWarning => '경고';

  @override
  String get bannerUntilCleared => '해제할 때까지';

  @override
  String bannerForHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: '$hours시간 동안');
    return '$_temp0';
  }

  @override
  String get bannerClear => '해제';

  @override
  String get bannerShow => '표시';

  @override
  String get viewStartTab => '처음 열리는 탭';

  @override
  String get viewHomeCards => '홈에 표시';

  @override
  String get homeCardStatus => '상태';

  @override
  String get homeCardDevice => '기기 측정값';

  @override
  String get homeCardPage => '프로젝트 페이지';

  @override
  String get viewGrafanaPage => 'Grafana 페이지';

  @override
  String get viewGrafanaPageHelp => '비워 두면 배포의 페이지';

  @override
  String get viewCameras => '카메라';

  @override
  String get viewCameraOverlay => '비전 오버레이';

  @override
  String get viewAlerts => '표시할 알림';

  @override
  String get alertsAll => '모두';

  @override
  String get alertsReview => '검토가 필요한 것만';

  @override
  String get alertsOff => '없음';

  @override
  String get viewAlertSound => '검토할 알림에 소리 내기';

  @override
  String get sectionDevice => '이 기기';

  @override
  String get deviceKiosk => '키오스크 모드';

  @override
  String get kioskModeHelp => '이 기기를 뷰어 계정에 고정합니다. 로그아웃이나 설정 변경이 안 되며, 아무도 쓰지 않으면 처음 상태로 돌아갑니다';

  @override
  String get kioskNeedsAccounts => 'p4n4-api 계정으로 로그인해야 합니다';

  @override
  String get kioskIdleReset => '사용하지 않으면 처음으로';

  @override
  String get idleSignOut => '사용하지 않으면 관리자와 고급 사용자 로그아웃';

  @override
  String get idleNever => '안 함';

  @override
  String idleAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count분 후');
    return '$_temp0';
  }

  @override
  String get startKioskTitle => '키오스크 모드 켜기';

  @override
  String get startKioskBody => '뷰어 계정으로 이 기기에 로그인합니다. 여기서는 로그아웃하거나 설정을 바꿀 수 없으며, 아무도 쓰지 않으면 처음 상태로 돌아갑니다.';

  @override
  String get kioskTurnOn => '켜기';

  @override
  String get leaveKiosk => '키오스크 모드 나가기';

  @override
  String get leaveKioskBody => '관리자 계정으로 로그인하세요. 이 기기는 그 관리자로 로그인된 상태가 됩니다.';

  @override
  String get kioskNeedsViewer => '뷰어 계정이 아닙니다.';

  @override
  String get kioskNeedsAdmin => '관리자 계정이 아닙니다.';

  @override
  String get startTabDefault => '기본값';

  @override
  String get chartHistory => '차트 기록';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count분');
    return '$_temp0';
  }

  @override
  String get defaultCamera => '기본 카메라';

  @override
  String get defaultCameraFirst => '첫 번째 카메라';

  @override
  String logsTitle(String name) {
    return '$name 로그';
  }

  @override
  String logsFailed(String error) {
    return '중지됨: $error';
  }

  @override
  String get logsEnded => '로그 스트림이 끝났습니다';

  @override
  String get logsFollowing => '새 줄을 따라가는 중';

  @override
  String get copyTooltip => '복사';

  @override
  String get copied => '복사됨';

  @override
  String get logsFilter => '필터';

  @override
  String get logsEmpty => '아직 로그가 없습니다';

  @override
  String get logsNoMatch => '필터와 일치하는 줄이 없습니다';

  @override
  String get logsLatest => '최신 줄로 이동';

  @override
  String get logsMenu => '로그';

  @override
  String get serviceConfirmRestartBody => '사용 중인 모든 사람에게 잠시 중단됩니다.';

  @override
  String serviceUptime(String time) {
    return '가동 $time';
  }

  @override
  String get serviceUnhealthy => '비정상';

  @override
  String get serviceStarting => '시작 중';

  @override
  String serviceActions(String name) {
    return '$name 작업';
  }

  @override
  String get sectionDevices => '장치';

  @override
  String devicesNote(String platform) {
    return '$platform-api로 측정값을 보내는 장치이며, 각각 고유한 키가 있습니다.';
  }

  @override
  String get devicesOnlyAdmins => '장치는 관리자만 변경할 수 있습니다.';

  @override
  String devicesLoadFailed(String error) {
    return '장치를 불러오지 못했습니다: $error';
  }

  @override
  String get devicesNone => '아직 등록된 장치가 없습니다.';

  @override
  String get deviceDisabled => '사용 안 함';

  @override
  String deviceLastSeen(String time) {
    return '마지막 확인 $time';
  }

  @override
  String get deviceNeverSeen => '확인된 적 없음';

  @override
  String deviceKey(String prefix) {
    return '키 $prefix…';
  }

  @override
  String get deviceDisable => '사용 안 함: 로그인할 수 없게 됩니다';

  @override
  String get deviceEnable => '사용';

  @override
  String get rotateKey => '새 키';

  @override
  String rotateKeyTitle(String name) {
    return '$name의 키를 새로 만들까요?';
  }

  @override
  String get rotateKeyBody => '현재 키는 즉시 작동하지 않습니다. 새 키를 장치에 넣으세요.';

  @override
  String removeDeviceTitle(String name) {
    return '$name을(를) 제거할까요?';
  }

  @override
  String get removeDeviceBody => '키가 즉시 작동하지 않으며 더 이상 측정값을 보낼 수 없습니다.';

  @override
  String get removeDeviceTooltip => '장치 제거';

  @override
  String get showMore => '더 보기';

  @override
  String get addDevice => '장치 추가';

  @override
  String get editDevice => '장치 편집';

  @override
  String get deviceId => '장치 ID';

  @override
  String get deviceIdHelp => '영문자, 숫자, 점, 하이픈, 밑줄. 나중에 바꿀 수 없습니다';

  @override
  String get deviceName => '이름';

  @override
  String get deviceDescription => '설명';

  @override
  String deviceKeyTitle(String id) {
    return '$id의 키';
  }

  @override
  String get deviceKeyBody => '지금 장치에 복사하세요. 다시 표시되지 않습니다.';

  @override
  String get done => '완료';

  @override
  String get contactSupport => '지원팀에 문의';

  @override
  String summaryDownFor(String time) {
    return '$time 동안 중단됨';
  }

  @override
  String deviceUpdatedAt(String time) {
    return '$time에 업데이트됨';
  }

  @override
  String deviceStaleSince(String time) {
    return '새로 고칠 수 없음 · $time의 측정값';
  }

  @override
  String get sectionThresholds => '임계값';

  @override
  String get thresholdServiceDown => '서비스 중단';

  @override
  String get sensorsTitle => '센서';

  @override
  String get sensorsSubtitle => '장치의 실시간 측정값입니다. 하나를 누르면 기록을 볼 수 있습니다.';

  @override
  String sensorsUnavailable(String error) {
    return '실시간 측정값 없음: $error';
  }

  @override
  String get sensorsNoBroker => '아직 MQTT 브로커에 연결되지 않았습니다';

  @override
  String get sensorsWaiting => '측정값을 기다리는 중…';

  @override
  String sensorReadAt(String time) {
    return '$time에 측정';
  }

  @override
  String get rangeHour => '1시간';

  @override
  String get rangeDay => '1일';

  @override
  String get rangeWeek => '1주';

  @override
  String sensorHistoryFailed(String error) {
    return '기록을 불러오지 못했습니다: $error';
  }

  @override
  String get sensorHistoryEmpty => '이 기간에 저장된 측정값이 없습니다';

  @override
  String sensorMin(String value) {
    return '최저 $value';
  }

  @override
  String sensorMax(String value) {
    return '최고 $value';
  }

  @override
  String get modelTitle => '모델';

  @override
  String get modelSubtitle => '엣지 장치의 추론 러너';

  @override
  String get modelNoRunner => '이 배포에 추론 러너가 없거나 응답하지 않습니다.';

  @override
  String modelFailed(String error) {
    return '러너에 연결할 수 없습니다: $error';
  }

  @override
  String get modelInferences => '추론 횟수';

  @override
  String get modelLastLatency => '마지막 지연 시간';

  @override
  String get modelLastAt => '마지막 추론';

  @override
  String get modelRecent => '최근 결과';

  @override
  String get classifyTitle => '사용해 보기';

  @override
  String get classifyValues => '입력 값';

  @override
  String classifyExpects(int expected, int count) {
    return '$expected개 중 $count개 값';
  }

  @override
  String get classify => '분류';

  @override
  String classifyAnomaly(String score) {
    return '이상 점수 $score';
  }

  @override
  String get classifyNotNumbers => '쉼표나 공백으로 구분한 숫자를 입력하세요.';

  @override
  String get commandTitle => '명령 보내기';

  @override
  String get commandSubtitle => 'MQTT 메시지 하나를 게시합니다(예: 장치의 명령 토픽)';

  @override
  String get commandTopic => '토픽';

  @override
  String get commandPayload => '메시지';

  @override
  String get commandPayloadHelp => '텍스트 또는 JSON';

  @override
  String get commandRetain => '보존(retain)';

  @override
  String commandSent(String topic, int bytes) {
    return '$topic(으)로 보냄($bytes바이트)';
  }

  @override
  String commandTopicNotAllowed(String topic) {
    return '이 배포에서는 $topic에 게시할 수 없습니다(p4n4-api의 P4N4_API_MQTT_PUBLISH_ALLOW 및 _DENY).';
  }

  @override
  String commandNoBroker(String error) {
    return 'p4n4-api가 브로커에 연결되어 있지 않습니다: $error';
  }

  @override
  String get commandNotAllowed => '명령은 운영자와 관리자만 보낼 수 있습니다.';

  @override
  String commandFailed(String error) {
    return '보내지 못함: $error';
  }

  @override
  String thresholdsNote(String deployment) {
    return '이 장치에서 $deployment의 측정값을 높음 또는 위험으로 표시하는 기준입니다.';
  }

  @override
  String thresholdLevels(String high, String critical) {
    return '$high부터 높음 · $critical부터 위험';
  }

  @override
  String get thresholdServiceDownHelp => '응답하지 않는 서비스는 처음에는 경고, 그 후에는 위험입니다';

  @override
  String get thresholdsReset => '기본값으로 되돌리기';

  @override
  String get fleetNoReadings => '장치 측정값 없음';

  @override
  String get incidentUnreachable => '전체';

  @override
  String incidentOngoing(String service, String start, String length) {
    return '$service $start부터 중단 중($length)';
  }

  @override
  String incidentEnded(String service, String start, String end) {
    return '$service 중단 $start–$end';
  }

  @override
  String get incidentHistory => '중단 기록';

  @override
  String incidentHistoryOf(String name) {
    return '$name: 중단';
  }

  @override
  String get incidentNone => '이 장치에서 확인된 중단이 없습니다.';

  @override
  String get incidentNote => '이 장치가 이 배포의 상태를 표시하는 동안 확인한 내용입니다.';

  @override
  String serviceDownFor(String time) {
    return '오프라인 · $time';
  }

  @override
  String get answerStyle => '답변 스타일';

  @override
  String get styleStandard => '기본';

  @override
  String get styleBrief => '짧게';

  @override
  String get styleSteps => '단계별로';

  @override
  String get styleSimple => '쉬운 말로';

  @override
  String get styleCustom => '직접 지시';

  @override
  String get styleCustomLabel => '어시스턴트가 어떻게 답해야 하나요?';

  @override
  String get styleCustomHelp => '이 장치에서 보내는 모든 질문과 함께 전송됩니다';

  @override
  String get videoGridLight => '느린 연결용 가벼운 그리드';

  @override
  String get videoGridLightHelp => '그리드에서 실시간 영상 대신 2초마다 새 이미지를 보여 줍니다';

  @override
  String cameraFrameEvery(int seconds) {
    return '$seconds초마다';
  }

  @override
  String get clearList => '지우기';
}
