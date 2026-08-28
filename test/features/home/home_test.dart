import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/network/api_client.dart';
import 'package:camrun/core/network/server_clock.dart';
import 'package:camrun/core/network/session_controller.dart';
import 'package:camrun/features/home/data/datasources/home_api.dart';
import 'package:camrun/features/home/data/home_mappers.dart';
import 'package:camrun/features/home/data/repositories/remote_home_repositories.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fake_http.dart';
import '../../fake_api.dart';
import '../../helpers.dart';

void main() {
  group('mapeo de /home/summary', () {
    final resumen = summaryFrom(homeSummary);

    test('la tira trae las siete casillas, con sesion o sin ella', () {
      expect(resumen.week.sessions, hasLength(7));
      // Martes no tiene sesion del plan y aun asi ocupa su hueco.
      expect(resumen.week.sessions[1].type, SessionType.rest);
      expect(resumen.week.sessions[1].targetDistanceKm, 0);
    });

    test('el progreso del dia cruza lo corrido con lo planificado', () {
      // Jueves: 10 km de los 16 que pedia el plan.
      expect(resumen.week.sessions[3].completionRatio, closeTo(0.625, 0.001));
      expect(resumen.week.sessions[3].isCompleted, isFalse);
      // Lunes: cumplido entero.
      expect(resumen.week.sessions[0].completionRatio, 1);
      expect(resumen.week.sessions[0].isCompleted, isTrue);
    });

    test('las unidades crudas se convierten una sola vez', () {
      final maraton = resumen.featuredMarathon!;
      expect(maraton.distanceKm, closeTo(21.097, 0.001));
      expect(maraton.entryFee.amount, 180);
      expect(maraton.entryFee.currency, 'BOB');
      expect(resumen.plan!.totalWeeks, 12);
    });

    test('el pronostico se abre en banda segun la confianza declarada', () {
      final maraton = resumen.featuredMarathon!;
      // 7020 s con confianza media: ±8 %.
      expect(maraton.predictedFinishMin, const Duration(seconds: 6458));
      expect(maraton.predictedFinishMax, const Duration(seconds: 7582));
    });

    test('sin prediccion no se inventa un rango', () {
      final sinDatos = summaryFrom({
        ...homeSummary,
        'prediction': {'finishTimeSeconds': null, 'reason': 'insufficient_data'},
      });
      expect(sinDatos.featuredMarathon!.predictedFinishMin, isNull);
    });
  });

  test('el recorrido GeoJSON llega como lat/lng, no al reves', () async {
    final (repo, db) = _repo((_) async => envelope(marathonDetail));
    final maraton = (await repo.fetchById('m1')).unwrap();
    expect(maraton.routePreview.first.lat, closeTo(-17.7833, 0.0001));
    expect(maraton.routePreview.first.lng, closeTo(-63.1821, 0.0001));
    await db.close();
  });

  test('sin red se sirve lo ultimo cacheado', () async {
    var caiga = false;
    final (marathons, db) = _repo((req) async {
      if (caiga) {
        throw DioException.connectionError(
          requestOptions: req,
          reason: 'sin red',
        );
      }
      return envelope(marathonDetail);
    });

    expect((await marathons.fetchById('m1')).unwrap().name, isNotEmpty);
    caiga = true;
    // La segunda llamada no llega al servidor y aun asi devuelve la maraton.
    expect((await marathons.fetchById('m1')).unwrap().id, 'm1');

    // Y sin nada en cache, el fallo sube: no hay nada que ensenar.
    expect((await marathons.fetchById('otra')).unwrap, throwsA(isA<Object>()));
    await db.close();
  });
}

(RemoteMarathonRepository, AppDatabase) _repo(
  Future<ResponseBody> Function(RequestOptions) handler,
) {
  final db = AppDatabase(NativeDatabase.memory());
  final dio =
      buildApiClient(
          session: SessionController(
            storage: MemoryTokenStorage(),
            refreshClient: Dio(),
          ),
          clock: ServerClock(),
        )
        ..httpClientAdapter = FakeAdapter(handler);
  return (RemoteMarathonRepository(HomeApi(dio), db), db);
}
