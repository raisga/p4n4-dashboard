// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navHome => 'Início';

  @override
  String get navClients => 'Clientes';

  @override
  String get navServices => 'Serviços';

  @override
  String get navEdge => 'Dispositivo';

  @override
  String get navAgent => 'Assistente';

  @override
  String get navGrafana => 'Gráficos';

  @override
  String get navVideo => 'Câmeras';

  @override
  String previewingView(String view) {
    return 'Você está vendo o painel como um perfil $view';
  }

  @override
  String get backToAdmin => 'Voltar para admin';

  @override
  String themeTooltip(String mode) {
    return 'Tema: $mode';
  }

  @override
  String get themeSystem => 'Igual ao dispositivo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get settingsTooltip => 'Configurações';

  @override
  String get signOutTooltip => 'Sair';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePower => 'Avançado';

  @override
  String get roleNormie => 'Leitor';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get add => 'Adicionar';

  @override
  String get remove => 'Remover';

  @override
  String get reset => 'Redefinir';

  @override
  String get delete => 'Excluir';

  @override
  String get clear => 'Nova conversa';

  @override
  String get open => 'Abrir';

  @override
  String get connect => 'Conectar';

  @override
  String get signOut => 'Sair';

  @override
  String get refreshStatus => 'Atualizar status';

  @override
  String get healthOnline => 'On-line';

  @override
  String get healthOffline => 'Off-line';

  @override
  String get healthChecking => 'Verificando…';

  @override
  String get healthUnknown => 'Desconhecido';

  @override
  String get fieldUsername => 'Usuário';

  @override
  String get fieldPassword => 'Senha';

  @override
  String get fieldHost => 'Host';

  @override
  String get fieldName => 'Nome';

  @override
  String get fieldView => 'Perfil';

  @override
  String hostHelp(String platform) {
    return 'A máquina que executa os stacks do $platform. No emulador Android, use 10.0.2.2.';
  }

  @override
  String apiBaseUrl(String platform) {
    return 'URL base do $platform-api';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return 'URL base do $platform-api (opcional)';
  }

  @override
  String get sessionExpired => 'Sua sessão expirou. Entre novamente.';

  @override
  String get signInTag => 'Entrar';

  @override
  String get signInConnecting => 'Conectando…';

  @override
  String get signInWelcome => 'Boas-vindas';

  @override
  String get signInButton => 'Entrar';

  @override
  String get signInWrongCredentials => 'Usuário ou senha incorretos.';

  @override
  String get signInRateLimited => 'Muitas tentativas. Aguarde um minuto e tente novamente.';

  @override
  String signInApiFailed(String platform) {
    return 'Não foi possível acessar o $platform-api. Verifique o servidor e tente novamente.';
  }

  @override
  String get signInChooseTitle => 'Escolha como continuar';

  @override
  String signInAuthOffNote(String platform) {
    return 'O $platform-api funciona sem login (P4N4_API_AUTH=off), então qualquer pessoa pode escolher um perfil.';
  }

  @override
  String get signInOfflineTitle => 'Continuar sem entrar';

  @override
  String signInOfflineNote(String platform) {
    return 'Sem o $platform-api, o status dos serviços é obtido testando as portas, e você mesmo escolhe o perfil.';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return 'Não foi possível acessar o $platform-api';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return 'Para entrar, é preciso o $platform-api em $url. Verifique se ele está em execução e acessível a partir deste dispositivo, ou altere o servidor abaixo.';
  }

  @override
  String get signInOfflineButton => 'Continuar sem entrar';

  @override
  String get signInDevAccounts => 'Contas de desenvolvimento';

  @override
  String signInDevAccountsNote(String platform) {
    return 'Requer o $platform-api com P4N4_API_DEV_USERS=true';
  }

  @override
  String signInServer(String url) {
    return 'Servidor: $url';
  }

  @override
  String get signInChangeServer => 'Alterar';

  @override
  String get roleAdminTitle => 'Administrador';

  @override
  String get roleAdminDesc => 'Tudo, além de implantações de clientes, controle de stacks, usuários e diagnóstico.';

  @override
  String get rolePowerTitle => 'Usuário avançado';

  @override
  String get rolePowerDesc => 'Todos os serviços e configurações, sem gerenciar implantações ou usuários.';

  @override
  String get roleNormieTitle => 'Leitor';

  @override
  String get roleNormieDesc => 'Status do sistema, gráficos, câmeras e assistente. Consulta sem alterar configurações.';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get sectionAppearance => 'Aparência';

  @override
  String get sectionLanguage => 'Idioma';

  @override
  String get sectionConnection => 'Conexão';

  @override
  String get sectionEdgeMetrics => 'Leituras do dispositivo';

  @override
  String get sectionGrafana => 'Gráficos';

  @override
  String get sectionVideo => 'Câmeras';

  @override
  String get sectionViews => 'Perfis';

  @override
  String get sectionUsers => 'Usuários';

  @override
  String get sectionDiagnostics => 'Diagnóstico';

  @override
  String get sectionAccount => 'Conta';

  @override
  String get sectionAbout => 'Sobre';

  @override
  String get languageSystem => 'Igual ao dispositivo';

  @override
  String get fieldDeployment => 'Implantação';

  @override
  String get resetConnection => 'Restaurar a conexão padrão';

  @override
  String get metricsUrl => 'URL das métricas';

  @override
  String get demoData => 'Dados de demonstração';

  @override
  String get grafanaBaseUrl => 'URL base do Grafana';

  @override
  String get dashboardPath => 'Caminho do painel';

  @override
  String get kioskMode => 'Modo quiosque';

  @override
  String viewsSaveFailed(String error) {
    return 'Não foi possível salvar os perfis: $error';
  }

  @override
  String get tabOrder => 'Ordem das abas';

  @override
  String get resetTabOrder => 'Restaurar a ordem';

  @override
  String get dragToReorder => 'Arraste para reordenar';

  @override
  String previewView(String view) {
    return 'Ver como $view';
  }

  @override
  String signedInAs(String user) {
    return 'Conectado como $user';
  }

  @override
  String get signedInWithoutAccount => 'Conectado sem conta';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · conta do $platform-api';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · escolhido ao entrar';
  }

  @override
  String get licenses => 'Licenças';

  @override
  String usersNote(String platform) {
    return 'Contas do $platform-api nesta implantação. Uma mudança de perfil vale na próxima atualização do usuário; redefinir a senha encerra a sessão dele.';
  }

  @override
  String usersLoadFailed(String error) {
    return 'Não foi possível carregar os usuários: $error';
  }

  @override
  String get usersOnlyAdmins => 'Somente administradores podem gerenciar usuários.';

  @override
  String userYou(String user) {
    return '$user (você)';
  }

  @override
  String get resetPasswordTooltip => 'Redefinir senha';

  @override
  String get removeUserTooltip => 'Remover usuário';

  @override
  String get addUserButton => 'Adicionar usuário';

  @override
  String get addUserTitle => 'Adicionar usuário';

  @override
  String get passwordMinLength => 'Pelo menos 10 caracteres';

  @override
  String removeUserTitle(String user) {
    return 'Remover $user?';
  }

  @override
  String get removeUserBody => 'A sessão será encerrada em todos os lugares e a pessoa não poderá entrar novamente.';

  @override
  String newPasswordTitle(String user) {
    return 'Nova senha para $user';
  }

  @override
  String get newPasswordHelp => 'Encerra a sessão em todos os lugares';

  @override
  String get diagDeployment => 'Implantação';

  @override
  String get diagSignIn => 'Login';

  @override
  String get diagView => 'Perfil';

  @override
  String get diagAuthMode => 'Modo de autenticação';

  @override
  String get diagAccessToken => 'Token de acesso';

  @override
  String get diagRefreshToken => 'Token de atualização';

  @override
  String get diagSecureStorage => 'Armazenamento seguro';

  @override
  String get diagServices => 'Serviços';

  @override
  String get diagChecking => 'verificando…';

  @override
  String get diagNotChecked => 'não verificado';

  @override
  String get diagNoAccount => 'sem conta';

  @override
  String get diagNone => 'nenhum';

  @override
  String get diagStored => 'salvo';

  @override
  String get diagAvailable => 'disponível';

  @override
  String get diagUnavailable => 'indisponível (somente em memória)';

  @override
  String diagServicesViaApi(int online, int known) {
    return '$online de $known ativos segundo a API';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return '$online de $known ativos segundo as portas';
  }

  @override
  String get tokenNone => 'nenhum (obtido na próxima requisição)';

  @override
  String tokenExpired(String time) {
    return 'expirou às $time';
  }

  @override
  String tokenValid(String time, int minutes) {
    return 'válido até $time ($minutes min)';
  }

  @override
  String get tokenUnreadable => 'presente (ilegível)';

  @override
  String get checkSignIn => 'Verificar login';

  @override
  String get checkServices => 'Verificar serviços';

  @override
  String get copySettings => 'Copiar configurações';

  @override
  String get settingsDump => 'Exportação das configurações';

  @override
  String get secretsHidden => 'Segredos ocultos';

  @override
  String get summaryChecking => 'Verificando seu sistema…';

  @override
  String get summaryCheckingSub => 'Isso leva alguns segundos.';

  @override
  String get summaryUnavailable => 'Status dos serviços indisponível';

  @override
  String get summaryUnavailableSub =>
      'Seu sistema responde, mas não informou o status dos serviços. Fale com o administrador se continuar.';

  @override
  String get summaryUnreachable => 'Não conseguimos acessar seu sistema';

  @override
  String get summaryUnreachableSub => 'Verifique se o dispositivo está ligado e conectado.';

  @override
  String get summaryOk => 'Tudo funcionando';

  @override
  String get summaryOkSub => 'Seu sistema está funcionando normalmente.';

  @override
  String get summaryAttention => 'Algo precisa de atenção';

  @override
  String get summaryAttentionSub =>
      'Parte do seu sistema não está funcionando agora. Se não se recuperar em alguns minutos, fale com o administrador.';

  @override
  String summaryAffected(String features) {
    return 'Afetado: $features';
  }

  @override
  String summaryUpdated(String time) {
    return 'Verificado às $time';
  }

  @override
  String get featureAssistant => 'Assistente';

  @override
  String get featureCharts => 'Gráficos';

  @override
  String get featureHistory => 'Histórico de dados';

  @override
  String get featureSensors => 'Dados dos sensores';

  @override
  String get featureAutomations => 'Automações';

  @override
  String get featureDeviceAi => 'IA no dispositivo';

  @override
  String get featureConnection => 'Conexão com o sistema';

  @override
  String get yourDevice => 'Seu dispositivo';

  @override
  String get deviceUnavailable => 'As leituras do dispositivo não estão disponíveis no momento.';

  @override
  String get deviceLoading => 'Carregando leituras…';

  @override
  String get readingProcessor => 'Processador';

  @override
  String get readingMemory => 'Memória';

  @override
  String get readingTemperature => 'Temperatura';

  @override
  String get levelNormal => 'Normal';

  @override
  String get levelHigh => 'Alto';

  @override
  String get levelCritical => 'Muito alto';

  @override
  String get levelWarm => 'Morno';

  @override
  String get levelHot => 'Quente';

  @override
  String get deviceDetails => 'Detalhes';

  @override
  String servicesApiUnreachable(String platform) {
    return 'O $platform-api não responde, então o status é obtido testando a porta de cada serviço.';
  }

  @override
  String servicesApiNoStatus(String platform, String reason) {
    return 'O $platform-api não informa o status dos serviços ($reason), então o status é obtido testando a porta de cada serviço.';
  }

  @override
  String get servicesTitle => 'Serviços';

  @override
  String servicesSubtitle(String host) {
    return 'Os aplicativos em execução em $host. Abra um para usá-lo diretamente.';
  }

  @override
  String get servicesSubtitlePlain => 'Os aplicativos em execução no seu sistema. Abra um para usá-lo.';

  @override
  String servicesLiveFrom(String authority) {
    return 'Status em tempo real de $authority';
  }

  @override
  String servicesContacting(String authority) {
    return 'Conectando a $authority…';
  }

  @override
  String serviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count serviços', one: '1 serviço');
    return '$_temp0';
  }

  @override
  String endpointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count endpoints', one: '1 endpoint');
    return '$_temp0';
  }

  @override
  String get stackControls => 'Ações do stack';

  @override
  String get stackStart => 'Iniciar';

  @override
  String get stackRestart => 'Reiniciar';

  @override
  String get stackStop => 'Parar';

  @override
  String stackConfirmStop(String stack) {
    return 'Parar o $stack?';
  }

  @override
  String get stackConfirmStopBody =>
      'Os serviços dele param de funcionar para todos até que alguém o inicie novamente.';

  @override
  String stackConfirmRestart(String stack) {
    return 'Reiniciar o $stack?';
  }

  @override
  String get stackConfirmRestartBody => 'Os serviços dele param por um momento enquanto reiniciam.';

  @override
  String stackJobRunning(String stack) {
    return 'Trabalhando no $stack…';
  }

  @override
  String stackJobDone(String stack) {
    return 'O $stack terminou.';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return 'A ação no $stack falhou: $error';
  }

  @override
  String couldNotOpen(String url) {
    return 'Não foi possível abrir $url';
  }

  @override
  String get tcpOnly => 'Sem página web';

  @override
  String get stackIot => 'Stack IoT';

  @override
  String get stackAi => 'Stack IA';

  @override
  String get stackApi => 'Gateway de API';

  @override
  String get serviceGrafanaDesc => 'Painéis e gráficos';

  @override
  String get serviceNodeRedDesc => 'Automação de fluxos';

  @override
  String get serviceInfluxDesc => 'Histórico de dados dos sensores';

  @override
  String get serviceMqttDesc => 'Broker de mensagens para dispositivos';

  @override
  String get serviceOllamaDesc => 'Modelos de IA locais';

  @override
  String get serviceLettaDesc => 'Agentes de IA com memória';

  @override
  String get serviceN8nDesc => 'Automação de fluxos de trabalho';

  @override
  String get serviceEiRunnerDesc => 'IA no dispositivo (Edge Impulse)';

  @override
  String get serviceApiDesc => 'Ponto de entrada único para todos os stacks';

  @override
  String get serviceSwaggerDesc => 'Documentação interativa da API';

  @override
  String get clientsIntro =>
      'O status de cada implantação vem da API dela ou, se ela não responder, do teste das portas dos serviços. Conectar muda este painel, e todas as configurações de conexão, para essa implantação.';

  @override
  String get clientsTitle => 'Implantações de clientes';

  @override
  String get noDeployments => 'Nenhuma implantação';

  @override
  String get noDeploymentsMsg => 'Adicione uma implantação de cliente com nome e host para monitorá-la aqui.';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known ativos';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known ativos (pelas portas)';
  }

  @override
  String get currentBadge => 'Conectado';

  @override
  String get editTooltip => 'Editar';

  @override
  String get removeTooltip => 'Remover';

  @override
  String get removeCurrentTooltip => 'Conecte-se a outra implantação para remover esta';

  @override
  String get addDeployment => 'Adicionar implantação';

  @override
  String get editDeployment => 'Editar implantação';

  @override
  String get clientName => 'Nome do cliente';

  @override
  String get apiUrlOptional => 'URL da API (opcional)';

  @override
  String get apiUrlHelp => 'Somente se a API não estiver na porta 8000 do host';

  @override
  String get edgeDemoSwitch => 'Dados de demonstração';

  @override
  String get edgeNoMetrics => 'Sem leituras do dispositivo';

  @override
  String edgeFetchFailed(String url, String error) {
    return 'Não foi possível ler $url: $error\n\nAponte a URL das métricas, nas Configurações, para um endpoint que retorne o JSON descrito no README.';
  }

  @override
  String get edgeUnavailable =>
      'As leituras do dispositivo não estão disponíveis no momento. Tente novamente em instantes.';

  @override
  String get edgeSubtitle => 'Leituras em tempo real do seu dispositivo, a cada 2 segundos.';

  @override
  String get useDemoData => 'Usar dados de demonstração';

  @override
  String get edgeStale => 'Desatualizado';

  @override
  String get edgeDemoLabel => 'Dados de demonstração';

  @override
  String get edgeSynthetic => 'Leituras inventadas para testes';

  @override
  String get edgeLive => 'Ao vivo';

  @override
  String get metricInference => 'Tempo de resposta da IA';

  @override
  String get factDisk => 'Armazenamento usado';

  @override
  String get factLoad => 'Carga média';

  @override
  String get factUptime => 'Em funcionamento há';

  @override
  String sparkStart(int minutes) {
    return 'há $minutes min';
  }

  @override
  String get sparkNow => 'Agora';

  @override
  String get agentModel => 'Modelo';

  @override
  String get agentAgent => 'Agente';

  @override
  String get assistantUnavailable => 'Assistente indisponível';

  @override
  String get assistantUnavailableMsg => 'O assistente não está respondendo agora. Tente novamente mais tarde.';

  @override
  String get assistantNotSetUp => 'Nenhum assistente configurado';

  @override
  String get assistantNotSetUpMsg => 'Peça ao administrador para configurar um.';

  @override
  String get assistantChat => 'Pergunte ao seu assistente';

  @override
  String get assistantChatMsg =>
      'Ele sabe como está o seu sistema agora, então você pode perguntar sobre seus dispositivos, dados e serviços.';

  @override
  String get assistantSuggestStatus => 'Está tudo funcionando normalmente?';

  @override
  String get assistantSuggestDevice => 'Quanto meu dispositivo está trabalhando agora?';

  @override
  String get assistantSuggestHelp => 'Como você pode me ajudar?';

  @override
  String get assistantSharedModel => 'Todos nesta implantação conversam com este modelo.';

  @override
  String get assistantSharedAgent => 'Todos nesta implantação conversam com este agente.';

  @override
  String assistantSaveFailed(String error) {
    return 'Não foi possível trocar o assistente: $error';
  }

  @override
  String get assistantErrorUnavailable => 'O assistente não está respondendo agora. Tente novamente em instantes.';

  @override
  String get assistantErrorChanged => 'O assistente mudou. Comece uma nova conversa para continuar.';

  @override
  String get assistantErrorGeneric => 'Não funcionou. Tente novamente.';

  @override
  String get assistantInputUnavailable => 'O assistente não está disponível no momento';

  @override
  String get sendTooltip => 'Enviar';

  @override
  String get stopTooltip => 'Parar';

  @override
  String agentUnreachable(String backend) {
    return '$backend não responde';
  }

  @override
  String get agentNoModels => 'Nenhum modelo instalado';

  @override
  String get agentNoModelsMsg =>
      'Baixe um primeiro no dispositivo, por ex. `docker exec p4n4-ollama ollama pull llama3.2`.';

  @override
  String get agentNoAgents => 'Ainda não há agentes';

  @override
  String get agentNoAgentsMsg => 'Crie um agente no ADE do Letta e tente novamente.';

  @override
  String agentOllamaMsg(String platform) {
    return 'As mensagens vão para o Ollama pelo $platform-api, com o estado atual do seu sistema. O histórico fica só nesta sessão.';
  }

  @override
  String get agentLettaMsg => 'Os agentes do Letta mantêm a própria memória entre sessões.';

  @override
  String get agentMessageHint => 'Faça uma pergunta… (Shift+Enter para nova linha)';

  @override
  String get agentSelectFirst => 'Escolha primeiro um modelo ou agente';

  @override
  String get agentStopped => '(interrompido)';

  @override
  String get agentThinking => 'Pensando…';

  @override
  String agentStepLookup(String what) {
    return 'Consultando $what';
  }

  @override
  String get agentStepData => 'Consultando os dados';

  @override
  String get agentWriting => 'Escrevendo a resposta…';

  @override
  String agentElapsed(int seconds) {
    return '$seconds s';
  }

  @override
  String agentWaitLast(int seconds) {
    return 'A última resposta levou $seconds s.';
  }

  @override
  String get agentWaitHint => 'As respostas podem levar até um minuto.';

  @override
  String get bubbleYou => 'Você';

  @override
  String get bubbleAgent => 'Assistente';

  @override
  String get bubbleError => 'Algo deu errado';

  @override
  String get grafanaDashboards => 'Gráficos';

  @override
  String get reloadTooltip => 'Recarregar';

  @override
  String get backTooltip => 'Voltar';

  @override
  String get openInBrowser => 'Abrir no navegador';

  @override
  String embedUnavailable(String platform) {
    return 'A visualização integrada não está disponível em $platform';
  }

  @override
  String get embedUnavailableMsg =>
      'A WebView do Flutter é compatível com Android, iOS e macOS. Nesta plataforma, o Grafana abre no seu navegador padrão.';

  @override
  String get openGrafana => 'Abrir o Grafana';

  @override
  String get grafanaUnreachable => 'O Grafana não responde';

  @override
  String get dashboardsUnavailable => 'Gráficos indisponíveis';

  @override
  String get dashboardsUnavailableMsg => 'Os gráficos não podem ser carregados agora. Tente novamente mais tarde.';

  @override
  String get viewerClose => 'Voltar aos serviços';

  @override
  String viewerLoading(String service) {
    return 'Carregando $service…';
  }

  @override
  String viewerBlankHint(String service) {
    return 'Em branco? O $service pode não permitir ser exibido no app.';
  }

  @override
  String get viewerDismissHint => 'Dispensar';

  @override
  String openService(String service) {
    return 'Abrir $service';
  }

  @override
  String viewerDownTitle(String service) {
    return '$service está fora do ar';
  }

  @override
  String get viewerDownMsg => 'O contêiner não está rodando. Inicie ou reinicie pela aba Serviços e tente novamente.';

  @override
  String get viewerDownMsgPlain => 'Não está funcionando agora. Tente novamente mais tarde.';

  @override
  String viewerUnsupportedMsg(String service) {
    return 'A WebView do Flutter é compatível com Android, iOS e macOS. Nesta plataforma, o $service abre no seu navegador padrão.';
  }

  @override
  String viewerBlockedTitle(String service) {
    return 'Não é possível mostrar $service aqui';
  }

  @override
  String viewerBlockedMsg(String service) {
    return 'O $service não permite ser exibido dentro de outro site. Sirva-o pelo proxy do painel (mesma origem) ou abra-o no navegador.';
  }

  @override
  String viewerInsecureMsg(String service) {
    return 'O painel usa HTTPS e o $service só HTTP, por isso o navegador não o mostra aqui. Sirva-o pelo proxy do painel ou abra-o no navegador.';
  }

  @override
  String viewerBlockedMsgPlain(String service) {
    return 'O $service não pode ser exibido no app. Abra-o no navegador.';
  }

  @override
  String viewerUnreachable(String service) {
    return '$service inacessível';
  }

  @override
  String viewerUnavailable(String service) {
    return '$service não está disponível';
  }

  @override
  String get viewerUnavailableMsg => 'Não pode ser carregado agora. Tente novamente mais tarde.';

  @override
  String viewerSlowTitle(String service) {
    return '$service está a demorar';
  }

  @override
  String viewerSlowMsg(String service) {
    return 'Se continuar em branco, o $service pode não permitir ser exibido no app. Você pode abri-lo no navegador.';
  }

  @override
  String get viewerSlowDetails =>
      'Páginas enviadas com X-Frame-Options ou uma política frame-ancestors ficam em branco num frame. Sirva o serviço pelo proxy do painel (/svc/<id>/) para incorporá-lo.';

  @override
  String get viewerKeepWaiting => 'Continuar esperando';

  @override
  String couldNotOpenService(String service) {
    return 'Não foi possível abrir $service';
  }

  @override
  String serviceUrlField(String service) {
    return 'URL de $service';
  }

  @override
  String cameraDefaultName(int n) {
    return 'Câmera $n';
  }

  @override
  String get resumeTooltip => 'Retomar';

  @override
  String get pauseTooltip => 'Pausar';

  @override
  String get reconnectTooltip => 'Reconectar';

  @override
  String get singleCamera => 'Uma câmera';

  @override
  String get allCameras => 'Todas as câmeras';

  @override
  String get editCamera => 'Editar câmera';

  @override
  String get addCamera => 'Adicionar câmera';

  @override
  String get addCameraButton => 'Adicionar câmera';

  @override
  String get noCameras => 'Nenhuma câmera';

  @override
  String get noCamerasTechnical =>
      'Adicione a URL de um stream MJPEG, de uma captura JPEG ou de um arquivo de vídeo da sua câmera edge, ou uma das câmeras deste dispositivo.';

  @override
  String get noCamerasNormie => 'Nenhuma câmera foi configurada ainda. Peça ao administrador para adicionar uma.';

  @override
  String get noCamerasConfigured => 'Nenhuma câmera configurada';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count câmeras', one: '1 câmera');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '\"$name\" tem uma URL inválida';
  }

  @override
  String get cameraUrl => 'URL de stream, captura ou vídeo, ou câmera do dispositivo';

  @override
  String get cameraUrlError => 'Digite uma URL http:// ou https://, device:back ou device:front';

  @override
  String get cameraExamples => 'por ex.';

  @override
  String get cameraReconnecting => 'Reconectando…';

  @override
  String get cameraStreamEnded => 'O stream terminou';

  @override
  String get cameraUnavailable => 'Câmera indisponível';

  @override
  String get cameraLive => 'Ao vivo';

  @override
  String get cameraVideo => 'Vídeo';

  @override
  String get backCamera => 'Câmera traseira';

  @override
  String get frontCamera => 'Câmera frontal';

  @override
  String get deviceCameraMissing => 'Este dispositivo não tem essa câmera';

  @override
  String get deviceCameraOneAtATime => 'Este dispositivo mostra uma câmera por vez';

  @override
  String get deviceCameraShow => 'Mostrar esta';

  @override
  String deviceCameraUnsupported(String platform) {
    return 'As câmeras do dispositivo não funcionam no app em $platform';
  }

  @override
  String get videoDemoSwitch => 'Câmeras de demonstração';

  @override
  String get videoGridDefault => 'Abrir com todas as câmeras';

  @override
  String get alertSound => 'Som dos alertas';

  @override
  String get alertDismiss => 'Dispensar alerta';

  @override
  String get visionPerson => 'Pessoa';

  @override
  String visionPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas',
      one: '1 pessoa',
      zero: 'Ninguém à vista',
    );
    return '$_temp0';
  }

  @override
  String get sectionChats => 'Chats';

  @override
  String get chatsNote =>
      'Os chats vinculados ao bot do projeto recebem os alertas assim que acontecem e podem perguntar-lhe sobre o projeto. Num grupo vinculado, todos podem.';

  @override
  String get chatsLink => 'Vincular um chat';

  @override
  String chatsLinkHow(String bot) {
    return 'Abra o link no telemóvel que vai usar o bot, ou envie este comando para $bot. Para um grupo, adicione primeiro o bot ao grupo e envie lá o comando.';
  }

  @override
  String get chatsTheBot => 'o bot';

  @override
  String chatsCodeExpires(String time) {
    return 'Funciona uma vez, até às $time.';
  }

  @override
  String get chatsCopyLink => 'Copiar link';

  @override
  String get chatsCopyCommand => 'Copiar comando';

  @override
  String get chatsNone => 'Ainda não há chats vinculados.';

  @override
  String chatsLinkedBy(String date, String who) {
    return 'Vinculado em $date por $who';
  }

  @override
  String chatsLinkedOn(String date) {
    return 'Vinculado em $date';
  }

  @override
  String chatsMuted(String codes) {
    return 'Silenciados: $codes';
  }

  @override
  String get chatsUnlink => 'Desvincular';

  @override
  String chatsUnlinkTitle(String name) {
    return 'Desvincular $name?';
  }

  @override
  String get chatsUnlinkBody => 'Deixa de receber alertas e o bot deixa de lhe responder. O chat é avisado.';

  @override
  String chatsLoadFailed(String error) {
    return 'Não foi possível carregar os chats: $error';
  }

  @override
  String get chatsMock => 'Modo simulado: o bot regista as mensagens em vez de as enviar.';

  @override
  String get chatsOff => 'Desligado: o bot não tem token.';

  @override
  String get useDemoCameras => 'Usar câmeras de demonstração';

  @override
  String get videoDemoCredits =>
      'Imagens de demonstração: clipes do MDN (CC0); Big Buck Bunny e Sintel © Blender Foundation (CC BY 3.0).';

  @override
  String videoUnsupported(String platform) {
    return 'Arquivos de vídeo não são reproduzidos no app em $platform';
  }

  @override
  String get settingsSearch => 'Pesquisar configurações';

  @override
  String settingsNoMatch(String query) {
    return 'Nenhum resultado para \"$query\"';
  }

  @override
  String get groupPersonal => 'Pessoal';

  @override
  String get groupDeployment => 'Implantação';

  @override
  String get groupAdmin => 'Administração';

  @override
  String get sectionAccessibility => 'Acessibilidade';

  @override
  String get sectionLanguageRegion => 'Idioma e região';

  @override
  String get sectionEndpoints => 'Endpoints';

  @override
  String get themeHeading => 'Tema';

  @override
  String get textSize => 'Tamanho do texto';

  @override
  String textSizeValue(String size) {
    return 'Texto $size';
  }

  @override
  String get textSizePreview => 'É assim que o texto aparece em todo o painel.';

  @override
  String get textSizeSmaller => 'Texto menor';

  @override
  String get textSizeLarger => 'Texto maior';

  @override
  String get resetToDefault => 'Redefinir';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get reduceMotion => 'Reduzir movimento';

  @override
  String get onInDeviceSettings => 'Ativado nas configurações do seu dispositivo.';

  @override
  String languageDevice(String language) {
    return 'Igual ao dispositivo ($language)';
  }

  @override
  String get searchLanguages => 'Pesquisar idiomas';

  @override
  String get formatsHeading => 'Formatos';

  @override
  String get temperatureUnit => 'Temperatura';

  @override
  String get unitAuto => 'Auto';

  @override
  String get timeFormat => 'Hora';

  @override
  String get time12h => '12 horas';

  @override
  String get time24h => '24 horas';

  @override
  String tourWelcome(String appName) {
    return 'Boas-vindas ao $appName! Veja o básico.';
  }

  @override
  String get tourNavigation => 'Aqui estão suas telas. Início mostra como está tudo; toque em outra tela para abri-la.';

  @override
  String get tourTheme => 'Alterne entre o visual claro e o escuro, ou siga o do seu dispositivo.';

  @override
  String get tourSettings => 'Idioma, tamanho do texto e mais ficam em Configurações. Lá você pode repetir este tour.';

  @override
  String get tourSignOut => 'Saia por aqui quando terminar.';

  @override
  String tourProgress(Object current, Object total) {
    return '$current de $total';
  }

  @override
  String get tourNext => 'Próximo';

  @override
  String get tourBack => 'Voltar';

  @override
  String get tourDone => 'Entendi';

  @override
  String get tourSkip => 'Pular tour';

  @override
  String get takeTour => 'Fazer o tour';

  @override
  String get takeTourSubtitle => 'Uma visão rápida do painel';

  @override
  String get navFeed => 'Atividade';

  @override
  String get feedEmpty => 'Nada ainda';

  @override
  String get feedEmptyMsg => 'Eventos e alertas aparecem aqui conforme acontecem.';

  @override
  String get feedNotSetUp => 'Sem atividade';

  @override
  String get feedNotSetUpMsg => 'Esta instalação não publica atividade.';

  @override
  String get feedNotSetUpTechnical => 'O projeto não tem feed: adicione dashboard.feed ao .p4n4.json dele.';

  @override
  String get feedUnavailable => 'Não foi possível ler a atividade';

  @override
  String get feedUnavailableMsg => 'Verifique se os serviços da loja estão em execução e tente novamente.';

  @override
  String feedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count para revisar',
      one: '1 para revisar',
    );
    return '$_temp0';
  }

  @override
  String get feedFilterAll => 'Tudo';

  @override
  String get feedFilterAlerts => 'Alertas';

  @override
  String get feedFilterPending => 'Para revisar';

  @override
  String get feedOlder => 'Anteriores';

  @override
  String feedActionFailed(String error) {
    return 'Não foi possível: $error';
  }

  @override
  String get feedDemoData => 'Dados de demonstração';

  @override
  String get feedStatusPending => 'Para revisar';

  @override
  String get feedStatusAttended => 'Atendido';

  @override
  String get feedStatusConfirmed => 'Confirmada';

  @override
  String get feedStatusDismissed => 'Descartado';

  @override
  String feedPosition(int index, int count) {
    return '$index de $count';
  }

  @override
  String get feedPrevious => 'Anterior';

  @override
  String get feedNext => 'Seguinte';

  @override
  String get feedKeys => 'Teclas: 1, 2… as ações · J / K seguinte / anterior · Esc voltar';

  @override
  String get feedPicture => 'A imagem do alerta';

  @override
  String get feedPictureFailed => 'Não foi possível carregar a imagem.';

  @override
  String get changePassword => 'Alterar senha';

  @override
  String get changePasswordSubtitle => 'Encerra sua sessão nos outros dispositivos';

  @override
  String get changePasswordTitle => 'Escolha uma nova senha';

  @override
  String get changePasswordBody => 'Um administrador pede que você escolha sua própria senha antes de continuar.';

  @override
  String get fieldCurrentPassword => 'Senha atual';

  @override
  String get fieldNewPassword => 'Nova senha';

  @override
  String get fieldRepeatPassword => 'Repita a nova senha';

  @override
  String get passwordsDontMatch => 'As senhas não coincidem';

  @override
  String get passwordCurrentWrong => 'A senha atual está incorreta';

  @override
  String get passwordChanged => 'Senha alterada';

  @override
  String get signOutUserTooltip => 'Sair em todos os lugares';

  @override
  String signOutUserTitle(String user) {
    return 'Encerrar a sessão de $user em todos os lugares?';
  }

  @override
  String get signOutUserBody => 'A pessoa terá que entrar de novo em cada dispositivo. A senha continua a mesma.';

  @override
  String get signOutSelfBody =>
      'Você terá que entrar de novo aqui e nos outros dispositivos. Sua senha continua a mesma.';

  @override
  String userLastSignIn(String when) {
    return 'Último acesso: $when';
  }

  @override
  String get userNeverSignedIn => 'Nunca entrou';

  @override
  String get userMustChangePassword => 'Precisa escolher uma nova senha';

  @override
  String get mustChangeAtFirstSignIn => 'Escolher a própria senha no primeiro acesso';

  @override
  String get mustChangeAtNextSignIn => 'Escolher uma nova senha no próximo acesso';

  @override
  String get sectionAudit => 'Registro de auditoria';

  @override
  String get auditNote => 'Quem mudou o quê nesta implantação, do mais recente';

  @override
  String auditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count alterações', one: '1 alteração');
    return '$_temp0, da mais recente';
  }

  @override
  String get auditEmpty => 'Nada mudou ainda';

  @override
  String auditLoadFailed(String error) {
    return 'Não foi possível carregar o registro de auditoria: $error';
  }

  @override
  String get auditLoadMore => 'Carregar mais';

  @override
  String get sectionBanner => 'Aviso';

  @override
  String get bannerNone => 'Sem aviso';

  @override
  String get bannerShowing => 'Visível em todos os dispositivos até você removê-lo';

  @override
  String bannerShowingUntil(String when) {
    return 'Visível em todos os dispositivos até $when';
  }

  @override
  String get bannerText => 'Mensagem';

  @override
  String get bannerHint => 'Manutenção hoje das 15h às 16h';

  @override
  String get bannerInfo => 'Informação';

  @override
  String get bannerWarning => 'Alerta';

  @override
  String get bannerUntilCleared => 'Até remover';

  @override
  String bannerForHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: 'Por $hours horas', one: 'Por 1 hora');
    return '$_temp0';
  }

  @override
  String get bannerClear => 'Remover';

  @override
  String get bannerShow => 'Mostrar';

  @override
  String get viewStartTab => 'Abre em';

  @override
  String get viewHomeCards => 'O início mostra';

  @override
  String get homeCardStatus => 'Status';

  @override
  String get homeCardDevice => 'Leituras do dispositivo';

  @override
  String get homeCardPage => 'Página do projeto';

  @override
  String get viewGrafanaPage => 'Página do Grafana';

  @override
  String get viewGrafanaPageHelp => 'Vazio: a página da implantação';

  @override
  String get viewCameras => 'Câmeras';

  @override
  String get viewCameraOverlay => 'Sobreposição de visão';

  @override
  String get viewAlerts => 'Alertas que aparecem';

  @override
  String get alertsAll => 'Todos';

  @override
  String get alertsReview => 'Só os que precisam de revisão';

  @override
  String get alertsOff => 'Nenhum';

  @override
  String get viewAlertSound => 'Som para alertas a revisar';

  @override
  String get sectionDevice => 'Este dispositivo';

  @override
  String get deviceKiosk => 'Modo quiosque';

  @override
  String get kioskModeHelp =>
      'Prende este dispositivo a uma conta de leitor: sem sair nem ajustes, e ele recomeça quando ninguém o usa';

  @override
  String get kioskNeedsAccounts => 'Requer login com contas do p4n4-api';

  @override
  String get kioskIdleReset => 'Recomeçar quando inativo';

  @override
  String get idleSignOut => 'Encerrar a sessão de administradores e usuários avançados quando inativo';

  @override
  String get idleNever => 'Nunca';

  @override
  String idleAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Após $count minutos',
      one: 'Após 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get startKioskTitle => 'Ativar o modo quiosque';

  @override
  String get startKioskBody =>
      'Entre neste dispositivo com uma conta de leitor. Aqui ninguém poderá sair nem mudar ajustes, e ele recomeça quando ninguém o usa.';

  @override
  String get kioskTurnOn => 'Ativar';

  @override
  String get leaveKiosk => 'Sair do modo quiosque';

  @override
  String get leaveKioskBody =>
      'Entre com uma conta de administrador. O dispositivo continua conectado com esse administrador.';

  @override
  String get kioskNeedsViewer => 'Essa não é uma conta de leitor.';

  @override
  String get kioskNeedsAdmin => 'Essa não é uma conta de administrador.';

  @override
  String get startTabDefault => 'Padrão';

  @override
  String get chartHistory => 'Histórico dos gráficos';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minutos', one: '1 minuto');
    return '$_temp0';
  }

  @override
  String get defaultCamera => 'Câmera padrão';

  @override
  String get defaultCameraFirst => 'A primeira';

  @override
  String logsTitle(String name) {
    return 'Logs de $name';
  }

  @override
  String logsFailed(String error) {
    return 'Parado: $error';
  }

  @override
  String get logsEnded => 'O fluxo de logs terminou';

  @override
  String get logsFollowing => 'Acompanhando as novas linhas';

  @override
  String get copyTooltip => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get logsFilter => 'Filtrar';

  @override
  String get logsEmpty => 'Ainda não há linhas de log';

  @override
  String get logsNoMatch => 'Nenhuma linha corresponde ao filtro';

  @override
  String get logsLatest => 'Ir para a linha mais recente';

  @override
  String get logsMenu => 'Logs';

  @override
  String get serviceConfirmRestartBody => 'Ele para por um momento para todos que o usam.';

  @override
  String serviceUptime(String time) {
    return 'ativo há $time';
  }

  @override
  String get serviceUnhealthy => 'Com falha';

  @override
  String get serviceStarting => 'Iniciando';

  @override
  String serviceActions(String name) {
    return 'Ações de $name';
  }

  @override
  String get sectionDevices => 'Dispositivos';

  @override
  String devicesNote(String platform) {
    return 'Dispositivos que enviam leituras ao $platform-api, cada um com sua própria chave.';
  }

  @override
  String get devicesOnlyAdmins => 'Só administradores podem alterar dispositivos.';

  @override
  String devicesLoadFailed(String error) {
    return 'Não foi possível carregar os dispositivos: $error';
  }

  @override
  String get devicesNone => 'Nenhum dispositivo registrado ainda.';

  @override
  String get deviceDisabled => 'Desativado';

  @override
  String deviceLastSeen(String time) {
    return 'Visto pela última vez $time';
  }

  @override
  String get deviceNeverSeen => 'Nunca visto';

  @override
  String deviceKey(String prefix) {
    return 'Chave $prefix…';
  }

  @override
  String get deviceDisable => 'Desativar: ele não poderá entrar';

  @override
  String get deviceEnable => 'Ativar';

  @override
  String get rotateKey => 'Nova chave';

  @override
  String rotateKeyTitle(String name) {
    return 'Nova chave para $name?';
  }

  @override
  String get rotateKeyBody => 'A chave atual para de funcionar na hora. Coloque a nova no dispositivo.';

  @override
  String removeDeviceTitle(String name) {
    return 'Remover $name?';
  }

  @override
  String get removeDeviceBody => 'A chave dele para de funcionar na hora, e ele não poderá mais enviar leituras.';

  @override
  String get removeDeviceTooltip => 'Remover dispositivo';

  @override
  String get showMore => 'Mostrar mais';

  @override
  String get addDevice => 'Adicionar dispositivo';

  @override
  String get editDevice => 'Editar dispositivo';

  @override
  String get deviceId => 'ID do dispositivo';

  @override
  String get deviceIdHelp => 'Letras, dígitos, pontos, hifens e sublinhados; não pode ser mudado depois';

  @override
  String get deviceName => 'Nome';

  @override
  String get deviceDescription => 'Descrição';

  @override
  String deviceKeyTitle(String id) {
    return 'Chave de $id';
  }

  @override
  String get deviceKeyBody => 'Copie para o dispositivo agora: ela não será mostrada de novo.';

  @override
  String get done => 'Pronto';

  @override
  String get contactSupport => 'Falar com o suporte';

  @override
  String summaryDownFor(String time) {
    return 'Fora do ar há $time';
  }

  @override
  String deviceUpdatedAt(String time) {
    return 'Atualizado às $time';
  }

  @override
  String deviceStaleSince(String time) {
    return 'Não foi possível atualizar · leituras das $time';
  }

  @override
  String get sectionThresholds => 'Limites';

  @override
  String get thresholdServiceDown => 'Serviço fora do ar';

  @override
  String get sensorsTitle => 'Sensores';

  @override
  String get sensorsSubtitle => 'Leituras ao vivo dos dispositivos. Toque em uma para ver o histórico.';

  @override
  String sensorsUnavailable(String error) {
    return 'Sem leituras ao vivo: $error';
  }

  @override
  String get sensorsNoBroker => 'Ainda sem conexão com o broker MQTT';

  @override
  String get sensorsWaiting => 'Aguardando leituras…';

  @override
  String sensorReadAt(String time) {
    return 'Lido às $time';
  }

  @override
  String get rangeHour => 'Hora';

  @override
  String get rangeDay => 'Dia';

  @override
  String get rangeWeek => 'Semana';

  @override
  String sensorHistoryFailed(String error) {
    return 'Não foi possível carregar o histórico: $error';
  }

  @override
  String get sensorHistoryEmpty => 'Nenhuma leitura salva neste período';

  @override
  String sensorMin(String value) {
    return 'Mínimo $value';
  }

  @override
  String sensorMax(String value) {
    return 'Máximo $value';
  }

  @override
  String get modelTitle => 'Modelo';

  @override
  String get modelSubtitle => 'O executor de inferência do dispositivo edge';

  @override
  String get modelNoRunner => 'Esta implantação não tem executor de inferência, ou ele não responde.';

  @override
  String modelFailed(String error) {
    return 'Não foi possível falar com o executor: $error';
  }

  @override
  String get modelInferences => 'Inferências';

  @override
  String get modelLastLatency => 'Última latência';

  @override
  String get modelLastAt => 'A última';

  @override
  String get modelRecent => 'Resultados recentes';

  @override
  String get classifyTitle => 'Experimente';

  @override
  String get classifyValues => 'Valores de entrada';

  @override
  String classifyExpects(int expected, int count) {
    return '$count de $expected valores';
  }

  @override
  String get classify => 'Classificar';

  @override
  String classifyAnomaly(String score) {
    return 'anomalia $score';
  }

  @override
  String get classifyNotNumbers => 'Digite números separados por vírgulas ou espaços.';

  @override
  String get commandTitle => 'Enviar um comando';

  @override
  String get commandSubtitle => 'Publica uma mensagem MQTT, por ex. no tópico de comandos de um dispositivo';

  @override
  String get commandTopic => 'Tópico';

  @override
  String get commandPayload => 'Mensagem';

  @override
  String get commandPayloadHelp => 'Texto ou JSON';

  @override
  String get commandRetain => 'Reter';

  @override
  String commandSent(String topic, int bytes) {
    return 'Enviado para $topic ($bytes bytes)';
  }

  @override
  String commandTopicNotAllowed(String topic) {
    return 'Esta implantação não permite publicar em $topic (P4N4_API_MQTT_PUBLISH_ALLOW e _DENY no p4n4-api).';
  }

  @override
  String commandNoBroker(String error) {
    return 'O p4n4-api não está conectado ao broker: $error';
  }

  @override
  String get commandNotAllowed => 'Só operadores e administradores podem enviar comandos.';

  @override
  String commandFailed(String error) {
    return 'Não enviado: $error';
  }

  @override
  String thresholdsNote(String deployment) {
    return 'Quando as leituras de $deployment aparecem como altas ou críticas, neste dispositivo.';
  }

  @override
  String thresholdLevels(String high, String critical) {
    return 'Alto a partir de $high · crítico a partir de $critical';
  }

  @override
  String get thresholdServiceDownHelp => 'Um serviço que para de responder é primeiro um aviso, depois crítico';

  @override
  String get thresholdsReset => 'Voltar aos padrões';

  @override
  String get fleetNoReadings => 'Sem leituras do dispositivo';

  @override
  String get incidentUnreachable => 'Tudo';

  @override
  String incidentOngoing(String service, String start, String length) {
    return '$service fora do ar desde $start ($length)';
  }

  @override
  String incidentEnded(String service, String start, String end) {
    return '$service fora do ar $start–$end';
  }

  @override
  String get incidentHistory => 'Histórico de quedas';

  @override
  String incidentHistoryOf(String name) {
    return '$name: quedas';
  }

  @override
  String get incidentNone => 'Nenhuma queda vista deste dispositivo.';

  @override
  String get incidentNote => 'Vistas deste dispositivo enquanto ele mostrava o status desta implantação.';

  @override
  String serviceDownFor(String time) {
    return 'Offline · $time';
  }

  @override
  String get answerStyle => 'Estilo de resposta';

  @override
  String get styleStandard => 'Padrão';

  @override
  String get styleBrief => 'Breve';

  @override
  String get styleSteps => 'Passo a passo';

  @override
  String get styleSimple => 'Palavras simples';

  @override
  String get styleCustom => 'Instruções próprias';

  @override
  String get styleCustomLabel => 'Como o assistente deve responder?';

  @override
  String get styleCustomHelp => 'Enviadas com cada pergunta deste dispositivo';

  @override
  String get videoGridLight => 'Grade leve para conexões lentas';

  @override
  String get videoGridLightHelp => 'Na grade, uma imagem nova a cada 2 segundos em vez de movimento ao vivo';

  @override
  String cameraFrameEvery(int seconds) {
    return 'a cada $seconds s';
  }

  @override
  String get clearList => 'Limpar';
}
