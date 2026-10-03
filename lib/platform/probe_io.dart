import 'package:http/http.dart' as http;

/// Any HTTP response means the port is serving.
Future<bool> probeHttp(Uri uri) async {
  try {
    await http.get(uri).timeout(const Duration(seconds: 3));
    return true;
  } catch (_) {
    return false;
  }
}
