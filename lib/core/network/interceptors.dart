import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/network/api_config.dart';
import 'package:paceup/core/network/error_mapper.dart';
import 'package:paceup/core/network/server_clock.dart';
import 'package:paceup/core/network/session_controller.dart';

/// 1. Adjunta el access token, salvo en los endpoints publicos.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session);

  final SessionController _session;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!isPublicPath(options.path)) {
      final token = await _session.accessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// 2. Ante un 401, renueva **una sola vez** (el mutex vive en
/// [SessionController]) y reintenta la peticion original.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor(this._session, this._dio);

  static const _reintentado = 'refreshRetried';

  final SessionController _session;
  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    final aplica =
        err.response?.statusCode == 401 &&
        !isPublicPath(req.path) &&
        req.extra[_reintentado] != true;

    if (!aplica) return handler.next(err);

    final token = await _session.refresh();
    if (token == null) {
      return handler.reject(err.copyWith(error: const SessionExpiredFailure()));
    }

    req
      ..headers['Authorization'] = 'Bearer $token'
      ..extra[_reintentado] = true;

    try {
      handler.resolve(await _dio.fetch<dynamic>(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// 3. Reintenta con backoff exponencial errores de red y 5xx.
///
/// Solo sobre peticiones seguras de repetir: metodos idempotentes o cualquiera
/// que lleve `Idempotency-Key` —reenviar un checkout sin ella es un segundo
/// cobro.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxAttempts = 2});

  static const _intentos = 'retryAttempts';
  static const _idempotentes = {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'};

  final Dio _dio;
  final int maxAttempts;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    final status = err.response?.statusCode ?? 0;
    final esRed = err.response == null && err.type != DioExceptionType.cancel;
    final repetible =
        _idempotentes.contains(req.method.toUpperCase()) ||
        req.headers.containsKey('Idempotency-Key');
    final intentos = (req.extra[_intentos] as int?) ?? 0;

    if (!(esRed || status >= 500) || !repetible || intentos >= maxAttempts) {
      return handler.next(err);
    }

    await Future<void>.delayed(Duration(milliseconds: 400 << intentos));
    req.extra[_intentos] = intentos + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// 4. Abre el sobre `{ data, meta }` y sincroniza el reloj del servidor, para
/// que por encima de esta capa nadie sepa que el sobre existe.
class EnvelopeInterceptor extends Interceptor {
  EnvelopeInterceptor(this._clock);

  final ServerClock _clock;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final body = response.data;
    if (body is Map && body.containsKey('data')) {
      final meta = body['meta'];
      final ts = meta is Map ? meta['timestamp'] as String? : null;
      final serverTime = ts == null ? null : DateTime.tryParse(ts);
      if (serverTime != null) _clock.sync(serverTime.toUtc());
      response.data = body['data'];
    }
    handler.next(response);
  }
}

/// 5. Traduce el error a un [Failure] del dominio y lo deja en `err.error`.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiFailure || err.error is SessionExpiredFailure) {
      return handler.next(err);
    }
    handler.next(err.copyWith(error: mapDioError(err)));
  }
}

/// 6. Log en debug, sin volcar cabeceras de autorizacion.
class DebugLogInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      developer.log(
        '${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.path}',
        name: 'api',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '${err.response?.statusCode ?? '---'} ${err.requestOptions.method} '
        '${err.requestOptions.path} -> ${err.error ?? err.type}',
        name: 'api',
      );
    }
    handler.next(err);
  }
}
