/// `connectMqtt`: a connection to an MQTT broker over TCP, to publish this
/// phone's GPS fixes. Browsers have no TCP sockets, so there it throws
/// [UnsupportedError].
library;

export 'mqtt_connect_io.dart' if (dart.library.js_interop) 'mqtt_connect_web.dart';
