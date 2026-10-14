// lib/services/session_store.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the signed-in passenger's token between app launches.
abstract class SessionStore {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clear();
}

/// Stored in the platform's encrypted storage (Keystore on Android, Keychain
/// on iOS). The token is never logged.
class SecureSessionStore implements SessionStore {
  static const _key = 'session_token_v1';

  final FlutterSecureStorage _storage;

  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> readToken() => _storage.read(key: _key);

  @override
  Future<void> saveToken(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// For tests and previews; nothing survives a restart.
class MemorySessionStore implements SessionStore {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}
