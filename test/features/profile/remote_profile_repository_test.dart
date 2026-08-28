import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/core/db/app_database.dart';
import 'package:paceup/core/network/interceptors.dart';
import 'package:paceup/core/network/server_clock.dart';
import 'package:paceup/features/profile/data/datasources/profile_api.dart';
import 'package:paceup/features/profile/data/repositories/remote_profile_repository.dart';

import '../../core/fake_http.dart';

final _profileJson = <String, dynamic>{
  'id': 'user-1',
  'name': 'Pandu Updated',
  'email': 'pandu@paceup.app',
  'city': 'La Paz',
  'country': 'BO',
  'avatarUrl': '',
  'birthDate': '1994-04-17T00:00:00.000Z',
  'gender': 'male',
  'weightGrams': 68000,
  'heightCm': 174,
  'weeklyMileageKm': 52.3,
  'longestRunKm': 26,
  'shoes': {'model': 'Pegasus 41', 'distanceKm': 612, 'retireAtKm': 700},
  'injuryFlags': '',
  'avgSleepMinutes': 431,
  'hydrationDays': 4,
  'defaultBibNumber': '0666',
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

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('GET /me maps the server profile and PATCH uses server units', () async {
    RequestOptions? patch;
    final dio = _dio((request) async {
      if (request.method == 'PATCH') {
        patch = request;
        return envelope(_profileJson);
      }
      return envelope(_profileJson);
    });
    final repository = RemoteProfileRepository(ProfileApi(dio), db);

    final profile = (await repository.fetch()).unwrap();
    expect(profile.fullName, 'Pandu Updated');
    expect(profile.weightKg, 68);
    expect(profile.birthDate.year, 1994);

    final updated = profile.copyWith(fullName: 'Pandu Server');
    await repository.save(updated);
    final body = patch!.data is String
        ? jsonDecode(patch!.data as String) as Map<String, dynamic>
        : (patch!.data as Map).cast<String, dynamic>();
    expect(patch!.path, '/me');
    expect(body['name'], 'Pandu Server');
    expect(body['weightGrams'], 68000);
    expect(body['birthDate'], contains('1994-04-17'));
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
        return envelope(_profileJson);
      });
      final repository = RemoteProfileRepository(ProfileApi(dio), db);

      expect((await repository.fetch()).unwrap().fullName, 'Pandu Updated');
      online = false;
      expect((await repository.fetch()).unwrap().fullName, 'Pandu Updated');
    },
  );
}
