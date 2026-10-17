import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error.dart';

/// The devices that send readings to p4n4-api (`/api/v1/devices`): operators
/// read the list, admins register, change and remove devices. Each signs in
/// with an API key, which the API shows only once.
class ApiDevice {
  const ApiDevice({
    required this.id,
    this.name = '',
    this.description = '',
    this.enabled = true,
    this.keyPrefix = '',
    this.createdAt,
    this.lastSeenAt,
  });

  factory ApiDevice.fromJson(Map<String, dynamic> j) => ApiDevice(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    enabled: j['enabled'] != false,
    keyPrefix: j['key_prefix'] as String? ?? '',
    createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal(),
    lastSeenAt: DateTime.tryParse(j['last_seen_at'] as String? ?? '')?.toLocal(),
  );

  final String id;
  final String name;
  final String description;

  /// A disabled device can't sign in, and its tokens stop working.
  final bool enabled;

  /// The start of its current key (`p4n4_<key id>`), to tell keys apart.
  final String keyPrefix;
  final DateTime? createdAt;

  /// When it last signed in or sent readings; null if it never has.
  final DateTime? lastSeenAt;
}

/// A page of devices and how many there are in all.
typedef DevicePage = ({List<ApiDevice> items, int total});

const _timeout = Duration(seconds: 8);
const _json = {'Content-Type': 'application/json'};

Uri _device(Uri api, String id, [String? action]) =>
    api.resolve('api/v1/devices/${Uri.encodeComponent(id)}${action == null ? '' : '/$action'}');

Future<http.Response> _guard(Future<http.Response> request) async {
  try {
    return await request.timeout(_timeout);
  } on TimeoutException {
    throw const ApiException('No answer in time.', statusCode: 504);
  } on http.ClientException catch (e) {
    throw ApiException(e.message);
  }
}

Future<DevicePage> listDevices(Uri api, {int limit = 50, int offset = 0}) async {
  final res = await _guard(
    http.get(api.resolve('api/v1/devices').replace(queryParameters: {'limit': '$limit', 'offset': '$offset'})),
  );
  final body = (apiBody(res) as Map).cast<String, dynamic>();
  return (
    items: [for (final d in body['items'] as List) ApiDevice.fromJson((d as Map).cast())],
    total: body['total'] as int,
  );
}

/// Registers a device; the result holds its API key, which isn't shown again.
Future<(ApiDevice, String)> createDevice(
  Uri api, {
  required String id,
  String name = '',
  String description = '',
}) async {
  final res = await _guard(
    http.post(
      api.resolve('api/v1/devices'),
      headers: _json,
      body: jsonEncode({'id': id.trim(), 'name': name.trim(), 'description': description.trim()}),
    ),
  );
  final body = (apiBody(res) as Map).cast<String, dynamic>();
  return (ApiDevice.fromJson(body), body['api_key'] as String);
}

/// Changes what's given; the rest stays as it is.
Future<ApiDevice> updateDevice(Uri api, String id, {String? name, String? description, bool? enabled}) async {
  final res = await _guard(
    http.patch(
      _device(api, id),
      headers: _json,
      body: jsonEncode({'name': ?name, 'description': ?description, 'enabled': ?enabled}),
    ),
  );
  return ApiDevice.fromJson((apiBody(res) as Map).cast());
}

/// Replaces the device's key; the old one stops working at once. Returns the
/// new key, shown only now.
Future<String> rotateDeviceKey(Uri api, String id) async {
  final res = await _guard(http.post(_device(api, id, 'key')));
  return (apiBody(res) as Map)['api_key'] as String;
}

/// Deregisters it: its key and tokens stop working at once.
Future<void> deleteDevice(Uri api, String id) async {
  apiBody(await _guard(http.delete(_device(api, id))));
}
