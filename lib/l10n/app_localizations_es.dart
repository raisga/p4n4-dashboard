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
  String get goToTag => 'Ir a';

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
  String get shortcutServicesDesc => 'Abre las aplicaciones de tu sistema.';

  @override
  String get shortcutDeviceDesc => 'Cuánto trabaja tu dispositivo, en vivo.';

  @override
  String get shortcutAssistantDesc => 'Pregunta sobre tu sistema con tus palabras.';

  @override
  String get shortcutDashboardsDesc => 'Gráficas e historial de tus sensores.';

  @override
  String get shortcutCameraDesc => 'Mira tus cámaras en vivo.';

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
  String get stackEdge => 'Stack Edge';

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
  String get sparkStart => 'hace 2 min';

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
      'Añade la URL de un stream MJPEG, de una captura JPEG o de un archivo de vídeo de tu cámara edge.';

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
  String get cameraUrl => 'URL de stream, captura o vídeo';

  @override
  String get cameraUrlError => 'Introduce una URL http:// o https://';

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
  String get videoDemoSwitch => 'Cámaras de demostración';

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
}
