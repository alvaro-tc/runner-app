import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/network/api_client.dart';
import 'package:camrun/core/network/api_config.dart';
import 'package:camrun/core/network/error_mapper.dart';
import 'package:camrun/core/network/server_clock.dart';
import 'package:camrun/core/network/session_controller.dart';
import 'package:camrun/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_http.dart';

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
  group('rutas publicas', () {
    test('una ruta privada que contiene a una publica NO es publica', () {
      // El panel llama a `/admin/marathons`, que contiene `/marathons`. Con una
      // comparacion por subcadena salia sin token y el servidor devolvia 401.
      expect(isPublicPath('/admin/marathons'), isFalse);
      expect(isPublicPath('/admin/marathons/abc'), isFalse);
      expect(isPublicPath('/admin/marathons/abc/cover'), isFalse);
      expect(isPublicPath('/admin/marathons/abc/qr'), isFalse);
      expect(isPublicPath('/admin/marathons/abc/publish'), isFalse);
    });

    test('el catalogo del corredor sigue siendo publico', () {
      expect(isPublicPath('/marathons'), isTrue);
      expect(isPublicPath('/marathons/upcoming'), isTrue);
      expect(isPublicPath('/marathons/maraton-la-paz-3600'), isTrue);
      expect(isPublicPath('/marathons/abc/categories'), isTrue);
    });

    test('las entradas con barra final solo cubren lo que cuelga', () {
      expect(isPublicPath('/links/marathon/x'), isTrue);
      expect(isPublicPath('/tracking/osmand'), isTrue);
    });

    test('auth: solo las de entrar, no las de sesion ya iniciada', () {
      expect(isPublicPath('/auth/login'), isTrue);
      expect(isPublicPath('/auth/refresh'), isTrue);
      // Si `/auth/me` se creyera publica, un 401 suyo no renovaria la sesion.
      expect(isPublicPath('/auth/me'), isFalse);
      expect(isPublicPath('/auth/sessions'), isFalse);
    });

    test('el resto del panel se mantiene privado', () {
      expect(isPublicPath('/admin/users'), isFalse);
      expect(isPublicPath('/admin/routes'), isFalse);
      expect(isPublicPath('/home/summary'), isFalse);
      expect(isPublicPath('/races/me'), isFalse);
    });

    test('la query y el prefijo de la base no cambian la decision', () {
      expect(isPublicPath('/marathons/upcoming?limit=8'), isTrue);
      expect(isPublicPath('/api/v1/marathons/upcoming'), isTrue);
      expect(isPublicPath('/api/v1/admin/marathons'), isFalse);
      expect(
        isPublicPath('http://localhost:3000/api/v1/admin/marathons'),
        isFalse,
      );
    });
  });

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
          if (refreshFalla) {
            return errorBody('TOKEN_REUSE_DETECTED', status: 401);
          }
          return envelope({
            'accessToken': 'nuevo',
            'refreshToken': 'refresh-nuevo',
            'expiresIn': 900,
          });
        }
        // El recurso protegido solo acepta el token nuevo.
        return o.headers['Authorization'] == 'Bearer nuevo'
            ? envelope({'ok': true})
            : errorBody('UNAUTHORIZED', status: 401);
      }

      final refreshClient = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = FakeAdapter(handler);
      final session = SessionController(
        storage: storage,
        refreshClient: refreshClient,
      );
      return buildApiClient(
        session: session,
        clock: ServerClock(),
        baseUrl: 'http://test',
      )..httpClientAdapter = FakeAdapter(handler);
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

    test(
      'un multipart sobrevive al refresh (no se reenvia consumido)',
      () async {
        // El FormData se consume al enviarlo: reenviar el mismo objeto lanzaba
        // "already finalized", un error sin respuesta que la UI mostraba como
        // "no pudimos conectar con el servidor" al subir la foto de perfil.
        final dio = armar();

        final res = await dio.post<dynamic>(
          '/users/me/avatar',
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(const [
              1,
              2,
              3,
            ], filename: 'a.webp'),
          }),
        );

        expect(refreshes, 1);
        expect(res.data, {'ok': true});
      },
    );

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

  test(
    'el sobre se abre y el reloj se sincroniza con meta.timestamp',
    () async {
      final clock = ServerClock();
      final session = SessionController(
        storage: _MemoryStorage(),
        refreshClient: Dio(),
      );
      final dio = buildApiClient(
        session: session,
        clock: clock,
        baseUrl: 'http://test',
      )..httpClientAdapter = FakeAdapter((o) async => envelope({'valor': 42}));

      final res = await dio.get<dynamic>('/config/app');

      expect(res.data, {'valor': 42});
      expect(clock.now().year, 2026);
      expect(clock.now().hour, 12);
    },
  );
}
