import 'dart:convert';
import 'dart:io';

import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/network/interceptors.dart';
import 'package:camrun/core/network/server_clock.dart';
import 'package:camrun/features/profile/data/datasources/profile_api.dart';
import 'package:camrun/features/profile/data/repositories/remote_profile_repository.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fake_http.dart';

/// Tal y como responde `GET /users/me`: la cuenta arriba, el atleta anidado.
final _userJson = <String, dynamic>{
  'id': 'user-1',
  'email': 'pandu@camrun.app',
  'ci': '1234567LP',
  'name': 'Pandu Updated',
  'role': 'runner',
  'profile': {
    'avatarUrl': null,
    'city': 'La Paz',
    'country': 'BO',
    'birthDate': '1994-04-17',
    'gender': 'male',
    'weightGrams': 68000,
    'heightCm': 174,
    'defaultBibNumber': '0666',
    'phone': '+591 70000000',
  },
};

final _highlightsJson = <String, dynamic>{
  'weekDistanceMeters': 52300,
  'longestWorkout': {'distanceMeters': 26000},
};

final _healthJson = <String, dynamic>{
  'injuryFlags': [
    {'zone': 'rodilla derecha'},
  ],
  'avgSleepMinutes': 431,
};

final _preferencesJson = <String, dynamic>{
  'notifications': {'planReminders': false, 'raceReminders': true},
  'privacy': {'shareActivity': true},
};

Dio _dio(Future<ResponseBody> Function(RequestOptions) handler) =>
    Dio(
        BaseOptions(
          baseUrl: 'http://test',
          validateStatus: (status) => status != null && status < 400,
        ),
      )
      ..interceptors.addAll([
        EnvelopeInterceptor(ServerClock()),
        ErrorInterceptor(),
      ])
      ..httpClientAdapter = FakeAdapter(handler);

/// Responde cada endpoint del perfil con su trozo.
Future<ResponseBody> _server(RequestOptions request) async =>
    switch (request.path) {
      '/users/me/highlights' => envelope(_highlightsJson),
      '/users/me/health' => envelope(_healthJson),
      '/users/me/preferences' => envelope(_preferencesJson),
      _ => envelope(_userJson),
    };

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test(
    'GET /users/me compone el perfil y PATCH usa las unidades del servidor',
    () async {
      RequestOptions? patch;
      final dio = _dio((request) async {
        if (request.method == 'PATCH') {
          patch = request;
        }
        return _server(request);
      });
      final repository = RemoteProfileRepository(ProfileApi(dio), db);

      final profile = (await repository.fetch()).unwrap();
      expect(profile.fullName, 'Pandu Updated');
      expect(profile.email, 'pandu@camrun.app');
      expect(profile.weightKg, 68);
      expect(profile.birthDate!.year, 1994);
      expect(profile.highlights.weeklyMileageKm, 52.3);
      expect(profile.injuryFlags, 'rodilla derecha');

      final updated = profile.copyWith(fullName: 'Pandu Server');
      await repository.save(updated);
      final body = patch!.data is String
          ? jsonDecode(patch!.data as String) as Map<String, dynamic>
          : (patch!.data as Map).cast<String, dynamic>();
      expect(patch!.path, '/users/me');
      expect(body['name'], 'Pandu Server');
      expect(body['weightGrams'], 68000);
      expect(body['birthDate'], contains('1994-04-17'));
    },
  );

  test('el CI y el celular se leen y viajan en el PATCH', () async {
    RequestOptions? patch;
    final dio = _dio((request) async {
      if (request.method == 'PATCH') patch = request;
      return _server(request);
    });
    final repository = RemoteProfileRepository(ProfileApi(dio), db);

    final profile = (await repository.fetch()).unwrap();
    expect(profile.ci, '1234567LP');
    expect(profile.phone, '+591 70000000');

    await repository.save(
      profile.copyWith(ci: '7654321', phone: '+591 71111111'),
    );
    final body = patch!.data is String
        ? jsonDecode(patch!.data as String) as Map<String, dynamic>
        : (patch!.data as Map).cast<String, dynamic>();
    expect(body['ci'], '7654321');
    expect(body['phone'], '+591 71111111');
  });

  test('guardar el formulario no borra highlights ni salud', () async {
    final dio = _dio(_server);
    final repository = RemoteProfileRepository(ProfileApi(dio), db);

    await repository.fetch();
    // El PATCH solo devuelve la cuenta: lo demas sale de la cache.
    final saved = (await repository.save(
      (await repository.fetch()).unwrap().copyWith(city: 'Cochabamba'),
    )).unwrap();
    expect(saved.highlights.weeklyMileageKm, 52.3);
    expect(saved.sleep.averageLast7Days.inMinutes, 431);
  });

  test('subir la foto deja la nueva URL en el perfil y en la cache', () async {
    // No se borra al terminar: en Windows el MultipartFile deja el descriptor
    // abierto y el delete falla.
    final file = File('${Directory.systemTemp.path}/avatar-test.png')
      ..writeAsBytesSync([1, 2, 3]);

    final dio = _dio((request) async {
      if (request.path == '/users/me/avatar') {
        return envelope({
          'avatarUrl': 'https://cam-run.test/uploads/avatars/nueva.webp',
        });
      }
      return _server(request);
    });
    final repository = RemoteProfileRepository(ProfileApi(dio), db);

    await repository.fetch();
    final updated = (await repository.uploadAvatar(file.path)).unwrap();
    expect(
      updated.avatarUrl,
      'https://cam-run.test/uploads/avatars/nueva.webp',
    );
    expect(updated.fullName, 'Pandu Updated');

    final doc = await db.readDoc('profile.current');
    expect(
      (doc!['profile'] as Map)['avatarUrl'],
      'https://cam-run.test/uploads/avatars/nueva.webp',
    );
  });

  test('los interruptores de ajustes viajan a /users/me/preferences', () async {
    RequestOptions? patch;
    final dio = _dio((request) async {
      if (request.method == 'PATCH') patch = request;
      return _server(request);
    });
    final repository = RemoteProfileRepository(ProfileApi(dio), db);

    final prefs = (await repository.fetchPreferences()).unwrap();
    expect(prefs.planReminders, isFalse);
    expect(prefs.raceUpdates, isTrue);
    expect(prefs.shareActivity, isTrue);
    // Ausente en la respuesta: se estrena apagado, no a null.
    expect(prefs.weeklyReport, isFalse);

    await repository.savePreferences(
      prefs.copyWith(
        planReminders: true,
        raceUpdates: false,
        units: 'imperial',
      ),
    );
    final body = (patch!.data as Map).cast<String, dynamic>();
    expect(patch!.path, '/users/me/preferences');
    expect((body['notifications'] as Map)['raceReminders'], false);
    expect((body['privacy'] as Map)['shareActivity'], true);
    // La apariencia viaja en el mismo PATCH que los interruptores.
    expect(body['units'], 'imperial');
  });

  test(
    'fetch serves the cached profile when the network is unavailable',
    () async {
      var online = true;
      final dio = _dio((request) async {
        if (!online) {
          throw DioException.connectionError(
            requestOptions: request,
            reason: 'offline',
          );
        }
        return _server(request);
      });
      final repository = RemoteProfileRepository(ProfileApi(dio), db);

      expect((await repository.fetch()).unwrap().fullName, 'Pandu Updated');
      online = false;
      expect((await repository.fetch()).unwrap().fullName, 'Pandu Updated');
    },
  );

  test('PATCH /users/me/health manda la lista de lesiones entera', () async {
    RequestOptions? patch;
    final dio = _dio((request) async {
      if (request.path == '/users/me/health' && request.method == 'PATCH') {
        patch = request;
        return envelope({
          'injuryFlags': [
            {'zone': 'tobillo', 'notes': 'vieja'},
          ],
          'avgSleepMinutes': 465,
        });
      }
      return _server(request);
    });
    final repository = RemoteProfileRepository(ProfileApi(dio), db);

    await repository.fetch();
    final saved = (await repository.saveHealth(
      injuries: const [Injury(zone: 'tobillo', notes: 'vieja')],
      sleep: const Duration(hours: 7, minutes: 45),
    )).unwrap();

    final body = (patch!.data as Map).cast<String, dynamic>();
    expect(body['avgSleepMinutes'], 465);
    // `notes` se conserva: el PATCH reescribe la lista, no la fusiona.
    expect((body['injuryFlags'] as List).first, {
      'zone': 'tobillo',
      'notes': 'vieja',
    });

    expect(saved.injuryFlags, 'tobillo');
    expect(saved.sleep.averageLast7Days.inMinutes, 465);
    // El resto del perfil sigue en pie: solo se reemplazo el bloque de salud.
    expect(saved.fullName, 'Pandu Updated');
  });
}
