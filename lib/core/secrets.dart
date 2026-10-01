import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key-value storage for credentials, kept out of shared_preferences.
abstract interface class SecretStore {
  Future<Map<String, String>> readAll();
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// The platform's secure storage: Keychain (iOS, macOS), Keystore-backed
/// encryption (Android), Credential Manager (Windows), or the Secret Service
/// via libsecret (Linux, e.g. GNOME Keyring or KWallet). Calls throw where
/// that isn't available, such as Linux without a keyring service.
class PlatformSecretStore implements SecretStore {
  // macOS: the legacy keychain needs no Keychain Sharing entitlement, which
  // would require a provisioning profile tied to the building Mac.
  final _storage = !kIsWeb && Platform.isMacOS
      ? const FlutterSecureStorage(mOptions: MacOsOptions(usesDataProtectionKeychain: false))
      : const FlutterSecureStorage();

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory [SecretStore] for tests; [fail] makes every call throw, like a
/// machine without a keyring.
class MemorySecretStore implements SecretStore {
  MemorySecretStore([Map<String, String>? values, this.fail = false]) : values = {...?values};

  final Map<String, String> values;
  bool fail;

  void _check() {
    if (fail) throw StateError('secure storage unavailable');
  }

  @override
  Future<Map<String, String>> readAll() async {
    _check();
    return {...values};
  }

  @override
  Future<void> write(String key, String value) async {
    _check();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _check();
    values.remove(key);
  }
}
