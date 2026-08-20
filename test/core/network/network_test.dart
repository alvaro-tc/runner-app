import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/network/api_client.dart';
import 'package:paceup/core/network/error_mapper.dart';
import 'package:paceup/core/network/server_clock.dart';
import 'package:paceup/core/network/session_controller.dart';
import 'package:paceup/core/storage/token_storage.dart';

/// Adaptador de mentira: responde lo que diga [handler], sin socket ninguno.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
}

ResponseBody _json(Object body, int status) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _envelope(Object data, {int status = 200}) => _json({
  'data': data,
  'meta': {
    'requestId': 'req-1',
    'timestamp': DateTime.utc(2026, 8, 20, 12).toIso8601String(),
  },
}, status);

ResponseBody _error(String code, {int status = 400}) => _json({
  'error': {'code': code, 'message': 'texto humano', 'details': <Object?>[]},
  'meta': {'requestId': 'req-1'},
}, status);

class _MemoryStorage implements TokenStorage {
  String? access = 'viejo';
  String? refresh = 'refresh-viejo';
  int clears = 0;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
    clears++;
  }

  @override
  Future<String> deviceId() async => 'device-1';
}

Failure _mapear(Map<String, Object?> body, int status) {
  final options = RequestOptions(path: '/x');
  return mapDioError(
    DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: status,
        data: body,
      ),
    ),
  );
}

void main() {
  group('mapDioError', () {
    test('sin red devuelve NetworkFailure', () {
      final f = mapDioError(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(f, isA<NetworkFailure>());
    });

    test('VALIDATION_ERROR conserva los detalles por campo', () {
      final f = _mapear({
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'no paso',
          'details': ['El email no tiene un formato valido'],
        },
      }, 400);
      expect(f, isA<ValidationFailure>());
      expect(f.message, contains('email'));
    });

    test('un codigo de negocio llega entero, con requestId', () {
      final f = _mapear({
        'error': {
          'code': 'MARATHON_FULL',
          'message': 'lleno',
          'details': <Object?>[],
        },
        'meta': {'requestId': 'req-9'},
      }, 409);
      expect(f, isA<ApiFailure>());
      expect((f as ApiFailure).code, 'MARATHON_FULL');
      expect(f.requestId, 'req-9');
    });

    test('el reuso de token es sesion muerta, no error de negocio', () {
      final f = _mapear({
        'error': {'code': 'TOKEN_REUSE_DETECTED', 'message': 'reuso'},
      }, 401);
      expect(f, isA<SessionExpiredFailure>());
    });

    test('respuesta sin sobre (proxy caido) no revienta', () {
      final f = _mapear(const {}, 502);
      expect(f, isA<UnexpectedFailure>());
    });
  });

  group('refresh', () {
    late _MemoryStorage storage;
    late int refreshes;

    Dio armar({bool refreshFalla = false}) {
      storage = _MemoryStorage();
      refreshes = 0;

      Future<ResponseBody> handler(RequestOptions o) async {
        if (o.path == '/auth/refresh') {
          refreshes++;
          if (refreshFalla) return _error('TOKEN_REUSE_DETECTED', status: 401);
          return _envelope({
            'accessToken': 'nuevo',
            'refreshToken': 'refresh-nuevo',
            'expiresIn': 900,
          });
        }
        // El recurso protegido solo acepta el token nuevo.
        return o.headers['Authorization'] == 'Bearer nuevo'
            ? _envelope({'ok': true})
            : _error('UNAUTHORIZED', status: 401);
      }

      final refreshClient = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = _FakeAdapter(handler);
      final session = SessionController(
        storage: storage,
        refreshClient: refreshClient,
      );
      return buildApiClient(
        session: session,
        clock: ServerClock(),
        baseUrl: 'http://test',
      )..httpClientAdapter = _FakeAdapter(handler);
    }

    test('diez 401 en paralelo disparan UN solo refresh', () async {
      final dio = armar();

      // Sin mutex, cada peticion rota el token por su cuenta y las nueve
      // rezagadas llegan con uno ya rotado: el servidor lo lee como robo y
      // cierra la sesion entera del dispositivo.
      final res = await Future.wait([
        for (var i = 0; i < 10; i++) dio.get<dynamic>('/workouts'),
      ]);

      expect(refreshes, 1);
      expect(storage.access, 'nuevo');
      for (final r in res) {
        expect(r.data, {'ok': true});
      }
    });

    test('si el refresh es rechazado se limpia el storage', () async {
      final dio = armar(refreshFalla: true);

      await expectLater(
        dio.get<dynamic>('/workouts'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<SessionExpiredFailure>(),
          ),
        ),
      );
      expect(storage.clears, 1);
      expect(storage.refresh, isNull);
    });
  });

  test('el sobre se abre y el reloj se sincroniza con meta.timestamp', () async {
    final clock = ServerClock();
    final session = SessionController(
      storage: _MemoryStorage(),
      refreshClient: Dio(),
    );
    final dio = buildApiClient(
      session: session,
      clock: clock,
      baseUrl: 'http://test',
    )..httpClientAdapter = _FakeAdapter((o) async => _envelope({'valor': 42}));

    final res = await dio.get<dynamic>('/config/app');

    expect(res.data, {'valor': 42});
    expect(clock.now().year, 2026);
    expect(clock.now().hour, 12);
  });
}
