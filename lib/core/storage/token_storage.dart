import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens y `deviceId`. Interfaz aparte del almacen real para poder inyectar
/// uno en memoria en los tests, donde no hay Keychain ni Keystore.
abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();

  /// Estable entre arranques: es lo que separa "Pixel 8" de "iPad" en la lista
  /// de sesiones y lo que permite revocar la cadena de un dispositivo robado.
  Future<String> deviceId();
}

/// Keychain en iOS, Keystore en Android. **Nunca** `SharedPreferences`: de ahi
/// un backup de Android se lleva la sesion entera.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _access = 'auth.accessToken';
  static const _refresh = 'auth.refreshToken';
  static const _device = 'auth.deviceId';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _access);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refresh);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _access, value: accessToken);
    await _storage.write(key: _refresh, value: refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }

  @override
  Future<String> deviceId() async {
    final actual = await _storage.read(key: _device);
    if (actual != null && actual.isNotEmpty) return actual;
    final nuevo = _randomUuidV4();
    await _storage.write(key: _device, value: nuevo);
    return nuevo;
  }
}

/// UUID v4 con `Random.secure`. Una dependencia menos que `package:uuid` para
/// las cuatro lineas que hacen falta.
String _randomUuidV4() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
