import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:flutter_test/flutter_test.dart';

GeoPoint _p(double lat, double lng) =>
    GeoPoint(lat: lat, lng: lng, timestamp: DateTime(2000));

void main() {
  group('recorrido en GeoJSON', () {
    test('las coordenadas viajan como [lng, lat], no al reves', () {
      final geoJson = routeToGeoJson([_p(-16.5, -68.13)]);

      expect(geoJson['type'], 'LineString');
      expect(geoJson['coordinates'], [
        [-68.13, -16.5],
      ]);
    });

    test('ida y vuelta: lo que se guarda se lee igual', () {
      final ida = [_p(-16.50, -68.13), _p(-16.51, -68.13)];
      // Como lo arma el editor con «ida y vuelta» puesto: la vuelta es la ida
      // al reves y el punto de giro no se repite.
      final trazado = [...ida, ...ida.reversed.skip(1)];

      final vuelta = routeFromGeoJson(routeToGeoJson(trazado));

      expect(vuelta.length, 3);
      expect(vuelta.first.lat, -16.50);
      expect(vuelta[1].lat, -16.51);
      expect(vuelta.last.lat, -16.50);
    });

    test('lo que no es un LineString no revienta: sale vacio', () {
      expect(routeFromGeoJson(null), isEmpty);
      expect(routeFromGeoJson('no soy geojson'), isEmpty);
      expect(routeFromGeoJson({'type': 'LineString'}), isEmpty);
      // Un par a medias se salta en vez de tirar la ruta entera.
      expect(
        routeFromGeoJson({
          'type': 'LineString',
          'coordinates': [
            [-68.13],
            [-68.12, -16.51],
          ],
        }),
        hasLength(1),
      );
    });
  });

  group('estado en vivo de una maraton', () {
    AdminMarathon conFechas({String? largo, String? termino}) =>
        AdminMarathon.fromJson({
          'id': 'm1',
          'name': 'Maraton',
          'city': 'La Paz',
          'startsAt': '2026-09-13T11:00:00.000Z',
          'capacity': 100,
          'liveStartedAt': largo,
          'liveFinishedAt': termino,
        });

    test('sin largar: se puede iniciar y no esta corriendo', () {
      final m = conFechas();
      expect(m.canStart, isTrue);
      expect(m.running, isFalse);
      expect(m.finished, isFalse);
    });

    test('largada dada: corriendo, y ya no se puede volver a largar', () {
      final m = conFechas(largo: '2026-09-13T11:02:00.000Z');
      expect(m.running, isTrue);
      expect(m.canStart, isFalse);
    });

    test('cortada: ni corre ni se puede largar otra vez', () {
      final m = conFechas(
        largo: '2026-09-13T11:02:00.000Z',
        termino: '2026-09-13T15:30:00.000Z',
      );
      expect(m.running, isFalse);
      expect(m.finished, isTrue);
      expect(m.canStart, isFalse);
    });
  });
}
