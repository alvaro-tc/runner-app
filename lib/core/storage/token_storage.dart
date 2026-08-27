import 'package:camrun/core/utils/uuid.dart';
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
    final nuevo = uuidV4();
    await _storage.write(key: _device, value: nuevo);
    return nuevo;
  }
}
