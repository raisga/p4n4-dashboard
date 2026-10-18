// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navHome => 'Inicio';

  @override
  String get navClients => 'Clientes';

  @override
  String get navServices => 'Servicios';

  @override
  String get navEdge => 'Dispositivo';

  @override
  String get navAgent => 'Asistente';

  @override
  String get navGrafana => 'Gráficas';

  @override
  String get navVideo => 'Cámaras';

  @override
  String previewingView(String view) {
    return 'Estás viendo el panel como lo ve un perfil $view';
  }

  @override
  String get backToAdmin => 'Volver a admin';

  @override
  String themeTooltip(String mode) {
    return 'Tema: $mode';
  }

  @override
  String get themeSystem => 'Como el dispositivo';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get signOutTooltip => 'Cerrar sesión';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePower => 'Avanzado';

  @override
  String get roleNormie => 'Lector';

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get add => 'Añadir';

  @override
  String get remove => 'Eliminar';

  @override
  String get reset => 'Restablecer';

  @override
  String get delete => 'Borrar';

  @override
  String get clear => 'Nueva conversación';

  @override
  String get open => 'Abrir';

  @override
  String get connect => 'Conectar';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get refreshStatus => 'Actualizar estado';

  @override
  String get healthOnline => 'En línea';

  @override
  String get healthOffline => 'Sin conexión';

  @override
  String get healthChecking => 'Comprobando…';

  @override
  String get healthUnknown => 'Desconocido';

  @override
  String get fieldUsername => 'Usuario';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get fieldHost => 'Host';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldView => 'Perfil';

  @override
  String hostHelp(String platform) {
    return 'Equipo que ejecuta los stacks de $platform. Desde el emulador de Android usa 10.0.2.2.';
  }

  @override
  String apiBaseUrl(String platform) {
    return 'URL base de $platform-api';
  }

  @override
  String apiBaseUrlOptional(String platform) {
    return 'URL base de $platform-api (opcional)';
  }

  @override
  String get sessionExpired => 'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get signInTag => 'Iniciar sesión';

  @override
  String get signInConnecting => 'Conectando…';

  @override
  String get signInWelcome => 'Te damos la bienvenida';

  @override
  String get signInButton => 'Iniciar sesión';

  @override
  String get signInWrongCredentials => 'Usuario o contraseña incorrectos.';

  @override
  String get signInRateLimited => 'Demasiados intentos. Espera un minuto y vuelve a intentarlo.';

  @override
  String signInApiFailed(String platform) {
    return 'No se puede conectar con $platform-api. Revisa el servidor y vuelve a intentarlo.';
  }

  @override
  String get signInChooseTitle => 'Elige cómo continuar';

  @override
  String signInAuthOffNote(String platform) {
    return '$platform-api funciona sin inicio de sesión (P4N4_API_AUTH=off), así que cualquiera puede elegir un perfil.';
  }

  @override
  String get signInOfflineTitle => 'Continuar sin iniciar sesión';

  @override
  String signInOfflineNote(String platform) {
    return 'Sin $platform-api, el estado de los servicios se obtiene comprobando puertos y el perfil lo eliges tú.';
  }

  @override
  String signInUnreachableTitle(String platform) {
    return 'No se puede conectar con $platform-api';
  }

  @override
  String signInUnreachableBody(String platform, String url) {
    return 'Para iniciar sesión se necesita $platform-api en $url. Comprueba que esté en marcha y que sea accesible desde este dispositivo, o cambia el servidor abajo.';
  }

  @override
  String get signInOfflineButton => 'Continuar sin iniciar sesión';

  @override
  String get signInDevAccounts => 'Cuentas de desarrollo';

  @override
  String signInDevAccountsNote(String platform) {
    return 'Requiere $platform-api con P4N4_API_DEV_USERS=true';
  }

  @override
  String signInServer(String url) {
    return 'Servidor: $url';
  }

  @override
  String get signInChangeServer => 'Cambiar';

  @override
  String get roleAdminTitle => 'Administrador';

  @override
  String get roleAdminDesc => 'Todo, más despliegues de clientes, control de stacks, usuarios y diagnóstico.';

  @override
  String get rolePowerTitle => 'Usuario avanzado';

  @override
  String get rolePowerDesc => 'Todos los servicios y ajustes, sin gestionar despliegues ni usuarios.';

  @override
  String get roleNormieTitle => 'Lector';

  @override
  String get roleNormieDesc => 'Estado del sistema, gráficas, cámaras y asistente. Consulta sin cambiar ajustes.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get sectionLanguage => 'Idioma';

  @override
  String get sectionConnection => 'Conexión';

  @override
  String get sectionEdgeMetrics => 'Lecturas del dispositivo';

  @override
  String get sectionGrafana => 'Gráficas';

  @override
  String get sectionVideo => 'Cámaras';

  @override
  String get sectionViews => 'Perfiles';

  @override
  String get sectionUsers => 'Usuarios';

  @override
  String get sectionDiagnostics => 'Diagnóstico';

  @override
  String get sectionAccount => 'Cuenta';

  @override
  String get sectionAbout => 'Acerca de';

  @override
  String get languageSystem => 'Como el dispositivo';

  @override
  String get fieldDeployment => 'Despliegue';

  @override
  String get resetConnection => 'Restablecer la conexión predeterminada';

  @override
  String get metricsUrl => 'URL de métricas';

  @override
  String get demoData => 'Datos de demostración';

  @override
  String get grafanaBaseUrl => 'URL base de Grafana';

  @override
  String get dashboardPath => 'Ruta del panel';

  @override
  String get kioskMode => 'Modo quiosco';

  @override
  String viewsSaveFailed(String error) {
    return 'No se pudieron guardar los perfiles: $error';
  }

  @override
  String get tabOrder => 'Orden de las pestañas';

  @override
  String get resetTabOrder => 'Restablecer el orden';

  @override
  String get dragToReorder => 'Arrastra para reordenar';

  @override
  String previewView(String view) {
    return 'Ver como $view';
  }

  @override
  String signedInAs(String user) {
    return 'Sesión iniciada como $user';
  }

  @override
  String get signedInWithoutAccount => 'Sesión iniciada sin cuenta';

  @override
  String accountViewApi(String view, String platform) {
    return '$view · cuenta de $platform-api';
  }

  @override
  String accountViewLocal(String view) {
    return '$view · elegido al iniciar sesión';
  }

  @override
  String get licenses => 'Licencias';

  @override
  String usersNote(String platform) {
    return 'Cuentas de $platform-api en este despliegue. Un cambio de perfil se aplica en la siguiente actualización del usuario; restablecer una contraseña cierra su sesión.';
  }

  @override
  String usersLoadFailed(String error) {
    return 'No se pueden cargar los usuarios: $error';
  }

  @override
  String get usersOnlyAdmins => 'Solo los administradores pueden gestionar usuarios.';

  @override
  String userYou(String user) {
    return '$user (tú)';
  }

  @override
  String get resetPasswordTooltip => 'Restablecer contraseña';

  @override
  String get removeUserTooltip => 'Eliminar usuario';

  @override
  String get addUserButton => 'Añadir usuario';

  @override
  String get addUserTitle => 'Añadir usuario';

  @override
  String get passwordMinLength => 'Al menos 10 caracteres';

  @override
  String removeUserTitle(String user) {
    return '¿Eliminar a $user?';
  }

  @override
  String get removeUserBody => 'Se cerrará su sesión en todas partes y no podrá volver a iniciarla.';

  @override
  String newPasswordTitle(String user) {
    return 'Nueva contraseña para $user';
  }

  @override
  String get newPasswordHelp => 'Cierra su sesión en todas partes';

  @override
  String get diagDeployment => 'Despliegue';

  @override
  String get diagSignIn => 'Inicio de sesión';

  @override
  String get diagView => 'Perfil';

  @override
  String get diagAuthMode => 'Modo de autenticación';

  @override
  String get diagAccessToken => 'Token de acceso';

  @override
  String get diagRefreshToken => 'Token de renovación';

  @override
  String get diagSecureStorage => 'Almacenamiento seguro';

  @override
  String get diagServices => 'Servicios';

  @override
  String get diagChecking => 'comprobando…';

  @override
  String get diagNotChecked => 'sin comprobar';

  @override
  String get diagNoAccount => 'sin cuenta';

  @override
  String get diagNone => 'ninguno';

  @override
  String get diagStored => 'guardado';

  @override
  String get diagAvailable => 'disponible';

  @override
  String get diagUnavailable => 'no disponible (solo en memoria)';

  @override
  String diagServicesViaApi(int online, int known) {
    return '$online de $known activos según la API';
  }

  @override
  String diagServicesViaProbes(int online, int known) {
    return '$online de $known activos según los puertos';
  }

  @override
  String get tokenNone => 'ninguno (se obtiene en la siguiente petición)';

  @override
  String tokenExpired(String time) {
    return 'caducó a las $time';
  }

  @override
  String tokenValid(String time, int minutes) {
    return 'válido hasta las $time ($minutes min)';
  }

  @override
  String get tokenUnreadable => 'presente (ilegible)';

  @override
  String get checkSignIn => 'Comprobar inicio de sesión';

  @override
  String get checkServices => 'Comprobar servicios';

  @override
  String get copySettings => 'Copiar ajustes';

  @override
  String get settingsDump => 'Volcado de ajustes';

  @override
  String get secretsHidden => 'Secretos ocultos';

  @override
  String get summaryChecking => 'Comprobando tu sistema…';

  @override
  String get summaryCheckingSub => 'Esto tarda unos segundos.';

  @override
  String get summaryUnavailable => 'Estado de los servicios no disponible';

  @override
  String get summaryUnavailableSub =>
      'Tu sistema responde, pero no informó del estado de los servicios. Contacta con tu administrador si continúa.';

  @override
  String get summaryUnreachable => 'No podemos conectar con tu sistema';

  @override
  String get summaryUnreachableSub => 'Comprueba que el dispositivo esté encendido y conectado.';

  @override
  String get summaryOk => 'Todo funciona';

  @override
  String get summaryOkSub => 'Tu sistema funciona con normalidad.';

  @override
  String get summaryAttention => 'Algo necesita atención';

  @override
  String get summaryAttentionSub =>
      'Parte de tu sistema no funciona en este momento. Si no se recupera en unos minutos, contacta con tu administrador.';

  @override
  String summaryAffected(String features) {
    return 'Afectado: $features';
  }

  @override
  String summaryUpdated(String time) {
    return 'Comprobado a las $time';
  }

  @override
  String get featureAssistant => 'Asistente';

  @override
  String get featureCharts => 'Gráficas';

  @override
  String get featureHistory => 'Historial de datos';

  @override
  String get featureSensors => 'Datos de sensores';

  @override
  String get featureAutomations => 'Automatizaciones';

  @override
  String get featureDeviceAi => 'IA en el dispositivo';

  @override
  String get featureConnection => 'Conexión con el sistema';

  @override
  String get yourDevice => 'Tu dispositivo';

  @override
  String get deviceUnavailable => 'Las lecturas del dispositivo no están disponibles en este momento.';

  @override
  String get deviceLoading => 'Cargando lecturas…';

  @override
  String get readingProcessor => 'Procesador';

  @override
  String get readingMemory => 'Memoria';

  @override
  String get readingTemperature => 'Temperatura';

  @override
  String get levelNormal => 'Normal';

  @override
  String get levelHigh => 'Alto';

  @override
  String get levelCritical => 'Muy alto';

  @override
  String get levelWarm => 'Templado';

  @override
  String get levelHot => 'Caliente';

  @override
  String get deviceDetails => 'Detalles';

  @override
  String servicesApiUnreachable(String platform) {
    return '$platform-api no responde, así que el estado se obtiene comprobando el puerto de cada servicio.';
  }

  @override
  String get servicesTitle => 'Servicios';

  @override
  String servicesSubtitle(String host) {
    return 'Las aplicaciones en marcha en $host. Abre una para usarla directamente.';
  }

  @override
  String get servicesSubtitlePlain => 'Las aplicaciones en marcha en tu sistema. Abre una para usarla.';

  @override
  String servicesLiveFrom(String authority) {
    return 'Estado en vivo desde $authority';
  }

  @override
  String servicesContacting(String authority) {
    return 'Contactando con $authority…';
  }

  @override
  String serviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count servicios', one: '1 servicio');
    return '$_temp0';
  }

  @override
  String endpointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count endpoints', one: '1 endpoint');
    return '$_temp0';
  }

  @override
  String get stackControls => 'Acciones del stack';

  @override
  String get stackStart => 'Iniciar';

  @override
  String get stackRestart => 'Reiniciar';

  @override
  String get stackStop => 'Detener';

  @override
  String stackConfirmStop(String stack) {
    return '¿Detener el $stack?';
  }

  @override
  String get stackConfirmStopBody =>
      'Sus servicios dejan de funcionar para todos hasta que alguien lo vuelva a iniciar.';

  @override
  String stackConfirmRestart(String stack) {
    return '¿Reiniciar el $stack?';
  }

  @override
  String get stackConfirmRestartBody => 'Sus servicios dejan de funcionar un momento mientras se reinician.';

  @override
  String stackJobRunning(String stack) {
    return 'Trabajando en el $stack…';
  }

  @override
  String stackJobDone(String stack) {
    return 'El $stack ha terminado.';
  }

  @override
  String stackJobFailed(String stack, String error) {
    return 'La acción del $stack falló: $error';
  }

  @override
  String couldNotOpen(String url) {
    return 'No se pudo abrir $url';
  }

  @override
  String get tcpOnly => 'Sin página web';

  @override
  String get stackIot => 'Stack IoT';

  @override
  String get stackAi => 'Stack IA';

  @override
  String get stackApi => 'Gateway API';

  @override
  String get serviceGrafanaDesc => 'Paneles y gráficas';

  @override
  String get serviceNodeRedDesc => 'Automatización de flujos';

  @override
  String get serviceInfluxDesc => 'Historial de datos de sensores';

  @override
  String get serviceMqttDesc => 'Broker de mensajes para dispositivos';

  @override
  String get serviceOllamaDesc => 'Modelos de IA locales';

  @override
  String get serviceLettaDesc => 'Agentes de IA con memoria';

  @override
  String get serviceN8nDesc => 'Automatización de flujos de trabajo';

  @override
  String get serviceEiRunnerDesc => 'IA en el dispositivo (Edge Impulse)';

  @override
  String get serviceApiDesc => 'Punto de entrada único para todos los stacks';

  @override
  String get serviceSwaggerDesc => 'Documentación interactiva de la API';

  @override
  String get clientsIntro =>
      'El estado de cada despliegue se obtiene de su API o, si no responde, comprobando los puertos de los servicios. Conectar cambia este panel, y todos los ajustes de conexión, a ese despliegue.';

  @override
  String get clientsTitle => 'Despliegues de clientes';

  @override
  String get noDeployments => 'No hay despliegues';

  @override
  String get noDeploymentsMsg => 'Añade un despliegue de cliente con su nombre y host para supervisarlo aquí.';

  @override
  String clientsUp(int online, int known) {
    return '$online/$known activos';
  }

  @override
  String clientsUpProbed(int online, int known) {
    return '$online/$known activos (por puertos)';
  }

  @override
  String get currentBadge => 'Conectado';

  @override
  String get editTooltip => 'Editar';

  @override
  String get removeTooltip => 'Eliminar';

  @override
  String get removeCurrentTooltip => 'Conéctate a otro despliegue para eliminar este';

  @override
  String get addDeployment => 'Añadir despliegue';

  @override
  String get editDeployment => 'Editar despliegue';

  @override
  String get clientName => 'Nombre del cliente';

  @override
  String get apiUrlOptional => 'URL de la API (opcional)';

  @override
  String get apiUrlHelp => 'Solo si la API no está en el puerto 8000 del host';

  @override
  String get edgeDemoSwitch => 'Datos de demostración';

  @override
  String get edgeNoMetrics => 'Sin lecturas del dispositivo';

  @override
  String edgeFetchFailed(String url, String error) {
    return 'No se pudo leer $url: $error\n\nApunta la URL de métricas de Ajustes a un endpoint que devuelva el JSON descrito en el README.';
  }

  @override
  String get edgeUnavailable =>
      'Las lecturas del dispositivo no están disponibles en este momento. Vuelve a intentarlo en breve.';

  @override
  String get edgeSubtitle => 'Lecturas en vivo de tu dispositivo, cada 2 segundos.';

  @override
  String get useDemoData => 'Usar datos de demostración';

  @override
  String get edgeStale => 'Sin actualizar';

  @override
  String get edgeDemoLabel => 'Datos de demostración';

  @override
  String get edgeSynthetic => 'Lecturas inventadas para probar';

  @override
  String get edgeLive => 'En vivo';

  @override
  String get metricInference => 'Tiempo de respuesta de la IA';

  @override
  String get factDisk => 'Almacenamiento usado';

  @override
  String get factLoad => 'Carga media';

  @override
  String get factUptime => 'En marcha desde hace';

  @override
  String sparkStart(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String get sparkNow => 'Ahora';

  @override
  String get agentModel => 'Modelo';

  @override
  String get agentAgent => 'Agente';

  @override
  String get assistantUnavailable => 'Asistente no disponible';

  @override
  String get assistantUnavailableMsg => 'El asistente no responde en este momento. Vuelve a intentarlo en un rato.';

  @override
  String get assistantNotSetUp => 'No hay ningún asistente configurado';

  @override
  String get assistantNotSetUpMsg => 'Pide a tu administrador que configure uno.';

  @override
  String get assistantChat => 'Pregunta a tu asistente';

  @override
  String get assistantChatMsg =>
      'Sabe cómo está tu sistema ahora mismo, así que puedes preguntar por tus dispositivos, datos y servicios.';

  @override
  String get assistantSuggestStatus => '¿Funciona todo con normalidad?';

  @override
  String get assistantSuggestDevice => '¿Cuánto trabaja mi dispositivo ahora?';

  @override
  String get assistantSuggestHelp => '¿En qué me puedes ayudar?';

  @override
  String get assistantSharedModel => 'Todos en este despliegue hablan con este modelo.';

  @override
  String get assistantSharedAgent => 'Todos en este despliegue hablan con este agente.';

  @override
  String assistantSaveFailed(String error) {
    return 'No se pudo cambiar el asistente: $error';
  }

  @override
  String get assistantErrorUnavailable =>
      'El asistente no responde en este momento. Vuelve a intentarlo en un momento.';

  @override
  String get assistantErrorChanged => 'El asistente ha cambiado. Empieza una conversación nueva para seguir.';

  @override
  String get assistantErrorGeneric => 'No funcionó. Vuelve a intentarlo.';

  @override
  String get assistantInputUnavailable => 'El asistente no está disponible en este momento';

  @override
  String get sendTooltip => 'Enviar';

  @override
  String get stopTooltip => 'Detener';

  @override
  String agentUnreachable(String backend) {
    return '$backend no responde';
  }

  @override
  String get agentNoModels => 'No hay modelos instalados';

  @override
  String get agentNoModelsMsg =>
      'Descarga uno primero en el dispositivo, p. ej. `docker exec p4n4-ollama ollama pull llama3.2`.';

  @override
  String get agentNoAgents => 'Aún no hay agentes';

  @override
  String get agentNoAgentsMsg => 'Crea un agente en el ADE de Letta y vuelve a intentarlo.';

  @override
  String agentOllamaMsg(String platform) {
    return 'Los mensajes van a Ollama a través de $platform-api, con el estado actual de tu sistema. El historial solo se conserva en esta sesión.';
  }

  @override
  String get agentLettaMsg => 'Los agentes de Letta conservan su propia memoria entre sesiones.';

  @override
  String get agentMessageHint => 'Haz una pregunta… (Mayús+Intro para nueva línea)';

  @override
  String get agentSelectFirst => 'Elige primero un modelo o agente';

  @override
  String get agentStopped => '(detenido)';

  @override
  String get agentThinking => 'Pensando…';

  @override
  String agentStepLookup(String what) {
    return 'Consultando $what';
  }

  @override
  String get agentStepData => 'Consultando datos';

  @override
  String get agentWriting => 'Redactando la respuesta…';

  @override
  String agentElapsed(int seconds) {
    return '$seconds s';
  }

  @override
  String agentWaitLast(int seconds) {
    return 'La última respuesta tardó $seconds s.';
  }

  @override
  String get agentWaitHint => 'Las respuestas pueden tardar hasta un minuto.';

  @override
  String get bubbleYou => 'Tú';

  @override
  String get bubbleAgent => 'Asistente';

  @override
  String get bubbleError => 'Algo salió mal';

  @override
  String get grafanaDashboards => 'Gráficas';

  @override
  String get reloadTooltip => 'Recargar';

  @override
  String get backTooltip => 'Atrás';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String embedUnavailable(String platform) {
    return 'La vista integrada no está disponible en $platform';
  }

  @override
  String get embedUnavailableMsg =>
      'El WebView de Flutter es compatible con Android, iOS y macOS. En esta plataforma Grafana se abre en tu navegador predeterminado.';

  @override
  String get openGrafana => 'Abrir Grafana';

  @override
  String get grafanaUnreachable => 'Grafana no responde';

  @override
  String get dashboardsUnavailable => 'Gráficas no disponibles';

  @override
  String get dashboardsUnavailableMsg =>
      'Las gráficas no se pueden cargar en este momento. Vuelve a intentarlo en un rato.';

  @override
  String cameraDefaultName(int n) {
    return 'Cámara $n';
  }

  @override
  String get resumeTooltip => 'Reanudar';

  @override
  String get pauseTooltip => 'Pausar';

  @override
  String get reconnectTooltip => 'Reconectar';

  @override
  String get singleCamera => 'Una cámara';

  @override
  String get allCameras => 'Todas las cámaras';

  @override
  String get editCamera => 'Editar cámara';

  @override
  String get addCamera => 'Añadir cámara';

  @override
  String get addCameraButton => 'Añadir cámara';

  @override
  String get noCameras => 'No hay cámaras';

  @override
  String get noCamerasTechnical =>
      'Añade la URL de un stream MJPEG, de una captura JPEG o de un archivo de vídeo de tu cámara edge, o una de las cámaras de este dispositivo.';

  @override
  String get noCamerasNormie => 'Aún no se ha configurado ninguna cámara. Pide a tu administrador que añada una.';

  @override
  String get noCamerasConfigured => 'No hay cámaras configuradas';

  @override
  String cameraCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count cámaras', one: '1 cámara');
    return '$_temp0';
  }

  @override
  String cameraInvalidUrl(String name) {
    return '\"$name\" tiene una URL no válida';
  }

  @override
  String get cameraUrl => 'URL de stream, captura o vídeo, o cámara del dispositivo';

  @override
  String get cameraUrlError => 'Introduce una URL http:// o https://, device:back o device:front';

  @override
  String get cameraExamples => 'p. ej.';

  @override
  String get cameraReconnecting => 'Reconectando…';

  @override
  String get cameraStreamEnded => 'El stream terminó';

  @override
  String get cameraUnavailable => 'Cámara no disponible';

  @override
  String get cameraLive => 'En vivo';

  @override
  String get cameraVideo => 'Vídeo';

  @override
  String get backCamera => 'Cámara trasera';

  @override
  String get frontCamera => 'Cámara frontal';

  @override
  String get deviceCameraMissing => 'Este dispositivo no tiene esa cámara';

  @override
  String get deviceCameraOneAtATime => 'Este dispositivo muestra una de sus cámaras a la vez';

  @override
  String get deviceCameraShow => 'Mostrar esta';

  @override
  String deviceCameraUnsupported(String platform) {
    return 'Las cámaras del dispositivo no funcionan en la app en $platform';
  }

  @override
  String get videoDemoSwitch => 'Cámaras de demostración';

  @override
  String get videoGridDefault => 'Abrir con todas las cámaras';

  @override
  String get alertSound => 'Sonido de alertas';

  @override
  String get alertDismiss => 'Descartar alerta';

  @override
  String get visionPerson => 'Persona';

  @override
  String visionPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '1 persona',
      zero: 'Nadie a la vista',
    );
    return '$_temp0';
  }

  @override
  String get sectionChats => 'Chats';

  @override
  String get chatsNote =>
      'Los chats vinculados al bot del proyecto reciben sus alertas en cuanto ocurren y pueden preguntarle por el proyecto. En un grupo vinculado, todos pueden.';

  @override
  String get chatsLink => 'Vincular un chat';

  @override
  String chatsLinkHow(String bot) {
    return 'Abre el enlace en el teléfono que usará el bot, o envía este comando a $bot. Para un grupo, añade primero el bot al grupo y envía allí el comando.';
  }

  @override
  String get chatsTheBot => 'el bot';

  @override
  String chatsCodeExpires(String time) {
    return 'Sirve una vez, hasta las $time.';
  }

  @override
  String get chatsCopyLink => 'Copiar enlace';

  @override
  String get chatsCopyCommand => 'Copiar comando';

  @override
  String get chatsNone => 'Aún no hay chats vinculados.';

  @override
  String chatsLinkedBy(String date, String who) {
    return 'Vinculado el $date por $who';
  }

  @override
  String chatsLinkedOn(String date) {
    return 'Vinculado el $date';
  }

  @override
  String chatsMuted(String codes) {
    return 'Silenciadas: $codes';
  }

  @override
  String get chatsUnlink => 'Desvincular';

  @override
  String chatsUnlinkTitle(String name) {
    return '¿Desvincular $name?';
  }

  @override
  String get chatsUnlinkBody => 'Deja de recibir alertas y el bot deja de responderle. Se le avisa al chat.';

  @override
  String chatsLoadFailed(String error) {
    return 'No se pudieron cargar los chats: $error';
  }

  @override
  String get chatsMock => 'Modo simulado: el bot registra sus mensajes en lugar de enviarlos.';

  @override
  String get chatsOff => 'Apagado: el bot no tiene token.';

  @override
  String get useDemoCameras => 'Usar cámaras de demostración';

  @override
  String get videoDemoCredits =>
      'Imágenes de demostración: clips de MDN (CC0); Big Buck Bunny y Sintel © Blender Foundation (CC BY 3.0).';

  @override
  String videoUnsupported(String platform) {
    return 'Los archivos de vídeo no se reproducen en la app en $platform';
  }

  @override
  String get settingsSearch => 'Buscar ajustes';

  @override
  String settingsNoMatch(String query) {
    return 'Nada coincide con \"$query\"';
  }

  @override
  String get groupPersonal => 'Personal';

  @override
  String get groupDeployment => 'Despliegue';

  @override
  String get groupAdmin => 'Administración';

  @override
  String get sectionAccessibility => 'Accesibilidad';

  @override
  String get sectionLanguageRegion => 'Idioma y región';

  @override
  String get sectionEndpoints => 'Endpoints';

  @override
  String get themeHeading => 'Tema';

  @override
  String get textSize => 'Tamaño del texto';

  @override
  String textSizeValue(String size) {
    return 'Texto $size';
  }

  @override
  String get textSizePreview => 'Así se ve el texto en todo el panel.';

  @override
  String get textSizeSmaller => 'Texto más pequeño';

  @override
  String get textSizeLarger => 'Texto más grande';

  @override
  String get resetToDefault => 'Restablecer';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get reduceMotion => 'Reducir movimiento';

  @override
  String get onInDeviceSettings => 'Activado en los ajustes de tu dispositivo.';

  @override
  String languageDevice(String language) {
    return 'Igual que el dispositivo ($language)';
  }

  @override
  String get searchLanguages => 'Buscar idiomas';

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
    return '¡Te damos la bienvenida a $appName! Te mostramos lo básico.';
  }

  @override
  String get tourNavigation =>
      'Aquí están tus pantallas. Inicio muestra cómo va todo; toca otra pantalla para abrirla.';

  @override
  String get tourTheme => 'Cambia entre un aspecto claro y uno oscuro, o usa el de tu dispositivo.';

  @override
  String get tourSettings =>
      'El idioma, el tamaño del texto y más están en Ajustes. Desde ahí puedes repetir este recorrido.';

  @override
  String get tourSignOut => 'Cierra sesión aquí cuando termines.';

  @override
  String tourProgress(Object current, Object total) {
    return '$current de $total';
  }

  @override
  String get tourNext => 'Siguiente';

  @override
  String get tourBack => 'Atrás';

  @override
  String get tourDone => 'Entendido';

  @override
  String get tourSkip => 'Saltar recorrido';

  @override
  String get takeTour => 'Hacer el recorrido';

  @override
  String get takeTourSubtitle => 'Un vistazo rápido al panel';

  @override
  String get navFeed => 'Actividad';

  @override
  String get feedEmpty => 'Nada todavía';

  @override
  String get feedEmptyMsg => 'Los eventos y las alertas aparecen aquí a medida que ocurren.';

  @override
  String get feedNotSetUp => 'Sin actividad';

  @override
  String get feedNotSetUpMsg => 'Esta instalación no publica actividad.';

  @override
  String get feedNotSetUpTechnical => 'El proyecto no tiene feed: agrega dashboard.feed a su .p4n4.json.';

  @override
  String get feedUnavailable => 'No se puede leer la actividad';

  @override
  String get feedUnavailableMsg => 'Revisa que los servicios de la tienda estén en marcha y vuelve a intentarlo.';

  @override
  String feedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count por revisar', one: '1 por revisar');
    return '$_temp0';
  }

  @override
  String get feedFilterAll => 'Todo';

  @override
  String get feedFilterAlerts => 'Alertas';

  @override
  String get feedFilterPending => 'Por revisar';

  @override
  String get feedOlder => 'Anteriores';

  @override
  String feedActionFailed(String error) {
    return 'No se pudo: $error';
  }

  @override
  String get feedDemoData => 'Datos de demostración';

  @override
  String get feedStatusPending => 'Por revisar';

  @override
  String get feedStatusAttended => 'Atendida';

  @override
  String get feedStatusConfirmed => 'Confirmada';

  @override
  String get feedStatusDismissed => 'Descartada';

  @override
  String feedPosition(int index, int count) {
    return '$index de $count';
  }

  @override
  String get feedPrevious => 'Anterior';

  @override
  String get feedNext => 'Siguiente';

  @override
  String get feedKeys => 'Teclas: 1, 2… las acciones · J / K siguiente / anterior · Esc volver';

  @override
  String get feedPicture => 'La imagen de la alerta';

  @override
  String get feedPictureFailed => 'No se pudo cargar la imagen.';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get changePasswordSubtitle => 'Cierra tu sesión en tus otros dispositivos';

  @override
  String get changePasswordTitle => 'Elige una contraseña nueva';

  @override
  String get changePasswordBody => 'Un administrador te pide que elijas tu propia contraseña antes de continuar.';

  @override
  String get fieldCurrentPassword => 'Contraseña actual';

  @override
  String get fieldNewPassword => 'Contraseña nueva';

  @override
  String get fieldRepeatPassword => 'Repite la contraseña nueva';

  @override
  String get passwordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get passwordCurrentWrong => 'La contraseña actual no es correcta';

  @override
  String get passwordChanged => 'Contraseña cambiada';

  @override
  String get signOutUserTooltip => 'Cerrar sesión en todas partes';

  @override
  String signOutUserTitle(String user) {
    return '¿Cerrar la sesión de $user en todas partes?';
  }

  @override
  String get signOutUserBody => 'Tendrá que volver a iniciar sesión en cada dispositivo. Su contraseña no cambia.';

  @override
  String get signOutSelfBody =>
      'Tendrás que volver a iniciar sesión aquí y en tus otros dispositivos. Tu contraseña no cambia.';

  @override
  String userLastSignIn(String when) {
    return 'Último inicio de sesión: $when';
  }

  @override
  String get userNeverSignedIn => 'Nunca ha iniciado sesión';

  @override
  String get userMustChangePassword => 'Debe elegir una contraseña nueva';

  @override
  String get mustChangeAtFirstSignIn => 'Que elija su propia contraseña al iniciar sesión por primera vez';

  @override
  String get mustChangeAtNextSignIn => 'Que elija una contraseña nueva al iniciar sesión';

  @override
  String get sectionAudit => 'Registro de auditoría';

  @override
  String get auditNote => 'Quién cambió qué en este despliegue, lo más reciente primero';

  @override
  String auditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count cambios', one: '1 cambio');
    return '$_temp0, lo más reciente primero';
  }

  @override
  String get auditEmpty => 'Todavía no ha cambiado nada';

  @override
  String auditLoadFailed(String error) {
    return 'No se pudo cargar el registro de auditoría: $error';
  }

  @override
  String get auditLoadMore => 'Cargar más';

  @override
  String get sectionBanner => 'Aviso';

  @override
  String get bannerNone => 'Sin aviso';

  @override
  String get bannerShowing => 'Visible en todos los dispositivos hasta que lo quites';

  @override
  String bannerShowingUntil(String when) {
    return 'Visible en todos los dispositivos hasta $when';
  }

  @override
  String get bannerText => 'Mensaje';

  @override
  String get bannerHint => 'Mantenimiento hoy de 3 a 4 p. m.';

  @override
  String get bannerInfo => 'Información';

  @override
  String get bannerWarning => 'Advertencia';

  @override
  String get bannerUntilCleared => 'Hasta quitarlo';

  @override
  String bannerForHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Durante $hours horas',
      one: 'Durante 1 hora',
    );
    return '$_temp0';
  }

  @override
  String get bannerClear => 'Quitar';

  @override
  String get bannerShow => 'Mostrar';

  @override
  String get viewStartTab => 'Abre en';

  @override
  String get viewHomeCards => 'Inicio muestra';

  @override
  String get homeCardStatus => 'Estado';

  @override
  String get homeCardDevice => 'Lecturas del dispositivo';

  @override
  String get homeCardPage => 'Página del proyecto';

  @override
  String get viewGrafanaPage => 'Página de Grafana';

  @override
  String get viewGrafanaPageHelp => 'Vacío: la página del despliegue';

  @override
  String get viewCameras => 'Cámaras';

  @override
  String get viewCameraOverlay => 'Superposición de visión';

  @override
  String get viewAlerts => 'Alertas que aparecen';

  @override
  String get alertsAll => 'Todas';

  @override
  String get alertsReview => 'Solo las que hay que revisar';

  @override
  String get alertsOff => 'Ninguna';

  @override
  String get viewAlertSound => 'Sonido para alertas por revisar';

  @override
  String get sectionDevice => 'Este dispositivo';

  @override
  String get deviceKiosk => 'Modo quiosco';

  @override
  String get kioskModeHelp =>
      'Fija este dispositivo a una cuenta de lector: sin cerrar sesión ni ajustes, y vuelve a empezar cuando nadie lo usa';

  @override
  String get kioskNeedsAccounts => 'Requiere iniciar sesión con cuentas de p4n4-api';

  @override
  String get kioskIdleReset => 'Volver a empezar si está inactivo';

  @override
  String get idleSignOut => 'Cerrar la sesión de administradores y usuarios avanzados si está inactivo';

  @override
  String get idleNever => 'Nunca';

  @override
  String idleAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tras $count minutos',
      one: 'Tras 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get startKioskTitle => 'Activar el modo quiosco';

  @override
  String get startKioskBody =>
      'Inicia sesión en este dispositivo con una cuenta de lector. Aquí no se podrá cerrar sesión ni cambiar ajustes, y vuelve a empezar cuando nadie lo usa.';

  @override
  String get kioskTurnOn => 'Activar';

  @override
  String get leaveKiosk => 'Salir del modo quiosco';

  @override
  String get leaveKioskBody =>
      'Inicia sesión con una cuenta de administrador. El dispositivo seguirá con la sesión de ese administrador.';

  @override
  String get kioskNeedsViewer => 'No es una cuenta de lector.';

  @override
  String get kioskNeedsAdmin => 'No es una cuenta de administrador.';

  @override
  String get startTabDefault => 'Predeterminada';

  @override
  String get chartHistory => 'Historial de los gráficos';

  @override
  String minutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minutos', one: '1 minuto');
    return '$_temp0';
  }

  @override
  String get defaultCamera => 'Cámara predeterminada';

  @override
  String get defaultCameraFirst => 'La primera';

  @override
  String logsTitle(String name) {
    return 'Registros de $name';
  }

  @override
  String logsFailed(String error) {
    return 'Detenido: $error';
  }

  @override
  String get logsEnded => 'El flujo de registros terminó';

  @override
  String get logsFollowing => 'Siguiendo las líneas nuevas';

  @override
  String get copyTooltip => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get logsFilter => 'Filtrar';

  @override
  String get logsEmpty => 'Aún no hay líneas de registro';

  @override
  String get logsNoMatch => 'Ninguna línea coincide con el filtro';

  @override
  String get logsLatest => 'Ir a la línea más reciente';

  @override
  String get logsMenu => 'Registros';

  @override
  String get serviceConfirmRestartBody => 'Se detiene un momento para todos los que lo usan.';

  @override
  String serviceUptime(String time) {
    return 'activo $time';
  }

  @override
  String get serviceUnhealthy => 'No saludable';

  @override
  String get serviceStarting => 'Iniciando';

  @override
  String serviceActions(String name) {
    return 'Acciones de $name';
  }

  @override
  String get sectionDevices => 'Dispositivos';

  @override
  String devicesNote(String platform) {
    return 'Dispositivos que envían lecturas a $platform-api, cada uno con su propia clave.';
  }

  @override
  String get devicesOnlyAdmins => 'Solo los administradores pueden cambiar los dispositivos.';

  @override
  String devicesLoadFailed(String error) {
    return 'No se pudieron cargar los dispositivos: $error';
  }

  @override
  String get devicesNone => 'Aún no hay dispositivos registrados.';

  @override
  String get deviceDisabled => 'Desactivado';

  @override
  String deviceLastSeen(String time) {
    return 'Visto por última vez $time';
  }

  @override
  String get deviceNeverSeen => 'Nunca visto';

  @override
  String deviceKey(String prefix) {
    return 'Clave $prefix…';
  }

  @override
  String get deviceDisable => 'Desactivar: no podrá iniciar sesión';

  @override
  String get deviceEnable => 'Activar';

  @override
  String get rotateKey => 'Nueva clave';

  @override
  String rotateKeyTitle(String name) {
    return '¿Nueva clave para $name?';
  }

  @override
  String get rotateKeyBody => 'La clave actual deja de funcionar al instante. Pon la nueva en el dispositivo.';

  @override
  String removeDeviceTitle(String name) {
    return '¿Quitar $name?';
  }

  @override
  String get removeDeviceBody => 'Su clave deja de funcionar al instante y ya no podrá enviar lecturas.';

  @override
  String get removeDeviceTooltip => 'Quitar dispositivo';

  @override
  String get showMore => 'Mostrar más';

  @override
  String get addDevice => 'Añadir dispositivo';

  @override
  String get editDevice => 'Editar dispositivo';

  @override
  String get deviceId => 'ID del dispositivo';

  @override
  String get deviceIdHelp => 'Letras, dígitos, puntos, guiones y guiones bajos; no se puede cambiar después';

  @override
  String get deviceName => 'Nombre';

  @override
  String get deviceDescription => 'Descripción';

  @override
  String deviceKeyTitle(String id) {
    return 'Clave de $id';
  }

  @override
  String get deviceKeyBody => 'Cópiala al dispositivo ahora: no se vuelve a mostrar.';

  @override
  String get done => 'Listo';

  @override
  String get contactSupport => 'Contactar con soporte';

  @override
  String summaryDownFor(String time) {
    return 'Caído desde hace $time';
  }

  @override
  String deviceUpdatedAt(String time) {
    return 'Actualizado a las $time';
  }

  @override
  String deviceStaleSince(String time) {
    return 'No se pudo actualizar · lecturas de las $time';
  }

  @override
  String get sectionThresholds => 'Umbrales';

  @override
  String get thresholdServiceDown => 'Servicio caído';

  @override
  String get sensorsTitle => 'Sensores';

  @override
  String get sensorsSubtitle => 'Lecturas en vivo de los dispositivos. Toca una para ver su historial.';

  @override
  String sensorsUnavailable(String error) {
    return 'Sin lecturas en vivo: $error';
  }

  @override
  String get sensorsNoBroker => 'Aún sin conexión con el broker MQTT';

  @override
  String get sensorsWaiting => 'Esperando lecturas…';

  @override
  String sensorReadAt(String time) {
    return 'Leído a las $time';
  }

  @override
  String get rangeHour => 'Hora';

  @override
  String get rangeDay => 'Día';

  @override
  String get rangeWeek => 'Semana';

  @override
  String sensorHistoryFailed(String error) {
    return 'No se pudo cargar el historial: $error';
  }

  @override
  String get sensorHistoryEmpty => 'No hay lecturas guardadas en este periodo';

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
  String get modelSubtitle => 'El ejecutor de inferencia del dispositivo edge';

  @override
  String get modelNoRunner => 'Este despliegue no tiene ejecutor de inferencia, o no responde.';

  @override
  String modelFailed(String error) {
    return 'No se pudo contactar con el ejecutor: $error';
  }

  @override
  String get modelInferences => 'Inferencias';

  @override
  String get modelLastLatency => 'Última latencia';

  @override
  String get modelLastAt => 'La última';

  @override
  String get modelRecent => 'Resultados recientes';

  @override
  String get classifyTitle => 'Pruébalo';

  @override
  String get classifyValues => 'Valores de entrada';

  @override
  String classifyExpects(int expected, int count) {
    return '$count de $expected valores';
  }

  @override
  String get classify => 'Clasificar';

  @override
  String classifyAnomaly(String score) {
    return 'anomalía $score';
  }

  @override
  String get classifyNotNumbers => 'Escribe números separados por comas o espacios.';

  @override
  String get commandTitle => 'Enviar un comando';

  @override
  String get commandSubtitle => 'Publica un mensaje MQTT, p. ej. en el tema de comandos de un dispositivo';

  @override
  String get commandTopic => 'Tema';

  @override
  String get commandPayload => 'Mensaje';

  @override
  String get commandPayloadHelp => 'Texto o JSON';

  @override
  String get commandRetain => 'Retener';

  @override
  String commandSent(String topic, int bytes) {
    return 'Enviado a $topic ($bytes bytes)';
  }

  @override
  String commandTopicNotAllowed(String topic) {
    return 'Este despliegue no permite publicar en $topic (P4N4_API_MQTT_PUBLISH_ALLOW y _DENY en p4n4-api).';
  }

  @override
  String commandNoBroker(String error) {
    return 'p4n4-api no está conectado al broker: $error';
  }

  @override
  String get commandNotAllowed => 'Solo los operadores y administradores pueden enviar comandos.';

  @override
  String commandFailed(String error) {
    return 'No enviado: $error';
  }

  @override
  String thresholdsNote(String deployment) {
    return 'Cuándo las lecturas de $deployment se muestran como altas o críticas, en este dispositivo.';
  }

  @override
  String thresholdLevels(String high, String critical) {
    return 'Alto desde $high · crítico desde $critical';
  }

  @override
  String get thresholdServiceDownHelp => 'Un servicio que deja de responder es primero un aviso y luego crítico';

  @override
  String get thresholdsReset => 'Volver a los valores predeterminados';

  @override
  String get fleetNoReadings => 'Sin lecturas del dispositivo';

  @override
  String get incidentUnreachable => 'Todo';

  @override
  String incidentOngoing(String service, String start, String length) {
    return '$service caído desde las $start ($length)';
  }

  @override
  String incidentEnded(String service, String start, String end) {
    return '$service caído $start–$end';
  }

  @override
  String get incidentHistory => 'Historial de caídas';

  @override
  String incidentHistoryOf(String name) {
    return '$name: caídas';
  }

  @override
  String get incidentNone => 'No se han visto caídas desde este dispositivo.';

  @override
  String get incidentNote => 'Vistas desde este dispositivo mientras mostraba el estado de este despliegue.';

  @override
  String serviceDownFor(String time) {
    return 'Sin conexión · $time';
  }

  @override
  String get answerStyle => 'Estilo de respuesta';

  @override
  String get styleStandard => 'Estándar';

  @override
  String get styleBrief => 'Breve';

  @override
  String get styleSteps => 'Paso a paso';

  @override
  String get styleSimple => 'Palabras sencillas';

  @override
  String get styleCustom => 'Instrucciones propias';

  @override
  String get styleCustomLabel => '¿Cómo debe responder el asistente?';

  @override
  String get styleCustomHelp => 'Se envían con cada pregunta desde este dispositivo';

  @override
  String get videoGridLight => 'Cuadrícula ligera para conexiones lentas';

  @override
  String get videoGridLightHelp => 'En la cuadrícula, una imagen nueva cada 2 segundos en lugar de movimiento en vivo';

  @override
  String cameraFrameEvery(int seconds) {
    return 'cada $seconds s';
  }

  @override
  String get clearList => 'Borrar';
}
