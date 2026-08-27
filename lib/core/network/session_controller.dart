import 'dart:async';

import 'package:camrun/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dueno de los tokens y del refresh.
///
/// El refresh **rota siempre**: el token que mandas muere en cuanto recibes el
/// nuevo. Si diez peticiones en vuelo reciben 401 a la vez y cada una dispara
/// su propio refresh, nueve llegan con un token ya rotado, el servidor lo lee
/// —bien— como robo y revoca la cadena entera del dispositivo. De ahi el
/// single-flight: la primera arranca el refresh y las demas esperan **ese
/// mismo** Future.
class SessionController {
  SessionController({required this.storage, required Dio refreshClient})
    : _client = refreshClient;

  final TokenStorage storage;

  /// Dio **sin** interceptores. Con ellos, un 401 del propio `/auth/refresh`
  /// dispararia otro refresh y de ahi no se sale.
  final Dio _client;

  String? _accessToken;
  Future<String?>? _enVuelo;

  /// Pasa a `true` cuando la sesion ya no se puede recuperar. El router lo
  /// escucha y manda a Welcome; salta una sola vez porque el refresh es unico.
  final ValueNotifier<bool> expired = ValueNotifier(false);

  Future<String?> accessToken() async =>
      _accessToken ??= await storage.readAccessToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    expired.value = false;
    await storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> clear() async {
    _accessToken = null;
    await storage.clearTokens();
  }

  /// Devuelve el access token nuevo, o `null` si la sesion murio.
  Future<String?> refresh() => _enVuelo ??= _refresh().whenComplete(() {
    _enVuelo = null;
  });

  Future<String?> _refresh() async {
    final refreshToken = await storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expire();
      return null;
    }

    try {
      final res = await _client.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          'deviceId': await storage.deviceId(),
        },
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      final access = data?['accessToken'] as String?;
      final nuevoRefresh = data?['refreshToken'] as String?;
      if (access == null || nuevoRefresh == null) {
        await _expire();
        return null;
      }
      // Guardar el par nuevo antes de hacer nada mas: el viejo ya no sirve.
      await saveTokens(accessToken: access, refreshToken: nuevoRefresh);
      return access;
    } on DioException catch (e) {
      // Un fallo de red no mata la sesion: el refresh token sigue siendo valido
      // y el proximo intento con cobertura funcionara. Solo un rechazo real del
      // servidor (401 INVALID_REFRESH_TOKEN o TOKEN_REUSE_DETECTED) la cierra.
      final esRed = e.response == null || (e.response!.statusCode ?? 0) >= 500;
      if (!esRed) await _expire();
      return null;
    }
  }

  Future<void> _expire() async {
    await clear();
    expired.value = true;
  }
}
