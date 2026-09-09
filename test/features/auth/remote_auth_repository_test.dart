import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/network/api_client.dart';
import 'package:camrun/core/network/server_clock.dart';
import 'package:camrun/core/network/session_controller.dart';
import 'package:camrun/core/services/google_sign_in_service.dart';
import 'package:camrun/core/utils/result.dart';
import 'package:camrun/features/auth/data/datasources/auth_api.dart';
import 'package:camrun/features/auth/data/models/auth_models.dart';
import 'package:camrun/features/auth/data/repositories/remote_auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fake_http.dart';
import '../../helpers.dart';

/// El dialogo de Google, sin dialogo: `null` es el usuario que lo cierra.
class _FakeGoogle extends GoogleSignInService {
  _FakeGoogle(this.token);
  final String? token;

  @override
  Future<String?> idToken() async => token;

  @override
  Future<void> signOut() async {}
}

void main() {
  late AppDatabase db;
  late MemoryTokenStorage storage;
  late List<String> llamadas;

  RemoteAuthRepository build(
    Future<ResponseBody> Function(RequestOptions) handler, {
    GoogleSignInService? google,
  }) {
    db = AppDatabase(NativeDatabase.memory());
    storage = MemoryTokenStorage();
    final session = SessionController(storage: storage, refreshClient: Dio());
    final dio = buildApiClient(session: session, clock: ServerClock())
      ..httpClientAdapter = FakeAdapter((req) {
        llamadas.add(req.path);
        return handler(req);
      });
    addTearDown(db.close);
    return RemoteAuthRepository(
      api: AuthApi(dio, storage),
      session: session,
      storage: storage,
      db: db,
      // Sin plugin registrado todo lo de Google falla, y el servicio se traga
      // sus fallos a proposito: cerrar sesion no puede depender de el.
      google: google ?? GoogleSignInService(),
    );
  }

  setUp(() => llamadas = []);

  test('cancelar el dialogo de Google no toca la sesion', () async {
    final repo = build((_) async => envelope({}), google: _FakeGoogle(null));

    final result = await repo.signInWithGoogle();

    expect(result, isA<Success<AuthUser?>>());
    expect((result as Success<AuthUser?>).value, isNull);
    expect(llamadas, isEmpty);
    expect(storage.refresh, isNull);
  });

  test('entrar con Google manda el idToken y guarda los tokens', () async {
    final repo = build(
      (_) async => envelope({
        'accessToken': 'a1',
        'refreshToken': 'r1',
        'expiresIn': 900,
        'user': {'id': 'u1', 'name': 'Pandu', 'role': 'runner'},
      }),
      google: _FakeGoogle('id-token'),
    );

    final result = await repo.signInWithGoogle();

    expect(result, isA<Success<AuthUser?>>());
    expect(llamadas, ['/auth/google']);
    expect(storage.refresh, 'r1');
  });

  test('el login guarda el par de tokens', () async {
    final repo = build(
      (_) async => envelope({
        'accessToken': 'a1',
        'refreshToken': 'r1',
        'expiresIn': 900,
        'user': {
          'id': 'u1',
          'email': 'a@b.c',
          'name': 'Pandu',
          'role': 'runner',
        },
      }),
    );

    final result = await repo.signIn(
      identifier: 'a@b.c',
      password: 'runfast123',
    );

    expect(result.unwrap().name, 'Pandu');
    expect(storage.access, 'a1');
    expect(storage.refresh, 'r1');
    // Con `user` en la respuesta no hace falta una segunda vuelta.
    expect(llamadas, ['/auth/login']);
  });

  test('cerrar sesion borra tokens y cache aunque el servidor falle', () async {
    final repo = build((req) async {
      if (req.path == '/auth/logout') {
        return errorBody('INTERNAL_ERROR', status: 500);
      }
      return envelope({
        'accessToken': 'a1',
        'refreshToken': 'r1',
        'expiresIn': 900,
        'user': {
          'id': 'u1',
          'email': 'a@b.c',
          'name': 'Pandu',
          'role': 'runner',
        },
      });
    });
    await repo.signIn(identifier: 'a@b.c', password: 'runfast123');
    await db.writeDoc('home.summary', {'x': 1});

    final result = await repo.signOut();

    expect(result, isA<Success<void>>());
    expect(storage.refresh, isNull);
    expect(await db.readDoc('home.summary'), isNull);
  });

  test('borrar la cuenta limpia tokens y cache', () async {
    final repo = build(
      (req) async => req.path == '/auth/me'
          ? envelope(<String, dynamic>{})
          : envelope({
              'accessToken': 'a1',
              'refreshToken': 'r1',
              'expiresIn': 900,
              'user': {
                'id': 'u1',
                'email': 'a@b.c',
                'name': 'Pandu',
                'role': 'runner',
              },
            }),
    );
    await repo.signIn(identifier: 'a@b.c', password: 'runfast123');
    await db.writeDoc('home.summary', {'x': 1});

    final result = await repo.deleteAccount('runfast123');

    expect(result, isA<Success<void>>());
    expect(storage.refresh, isNull);
    expect(await db.readDoc('home.summary'), isNull);
  });

  // Lo importante del borrado no es lo que hace al salir bien: si el servidor
  // dice que no, el telefono tiene que quedarse como estaba.
  test('si el servidor rechaza el borrado no se toca nada local', () async {
    final repo = build((req) async {
      if (req.path == '/users/me/data') {
        return errorBody('INVALID_CREDENTIALS', status: 401);
      }
      return envelope({
        'accessToken': 'a1',
        'refreshToken': 'r1',
        'expiresIn': 900,
        'user': {
          'id': 'u1',
          'email': 'a@b.c',
          'name': 'Pandu',
          'role': 'runner',
        },
      });
    });
    await repo.signIn(identifier: 'a@b.c', password: 'runfast123');
    await db.writeDoc('home.summary', {'x': 1});

    final result = await repo.deleteAccount('mal');

    expect(result, isA<FailureResult<void>>());
    expect(storage.refresh, 'r1');
    expect(await db.readDoc('home.summary'), isNotNull);
  });
}
