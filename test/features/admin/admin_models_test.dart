import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
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

  group('imagenes de la maraton', () {
    AdminMarathon con({String? cover, String? qr}) => AdminMarathon.fromJson({
      'id': 'm1',
      'name': 'Maraton',
      'city': 'La Paz',
      'startsAt': '2026-09-13T11:00:00.000Z',
      'capacity': 100,
      'coverUrl': cover,
      'paymentQrUrl': qr,
    });

    test('sin subir nada, los dos huecos estan vacios', () {
      final m = con();
      expect(m.hasCover, isFalse);
      expect(m.hasPaymentQr, isFalse);
    });

    test('la portada llega como URL del servidor y se reconoce', () {
      final m = con(
        cover: 'http://localhost:3000/uploads/marathons/cover/a.webp',
      );
      expect(m.hasCover, isTrue);
      expect(m.coverUrl, contains('/uploads/'));
    });

    test('un campo vacio no cuenta como imagen puesta', () {
      expect(con(cover: '', qr: '').hasCover, isFalse);
      expect(con(cover: '', qr: '').hasPaymentQr, isFalse);
    });

    test('cambiar el estado no se lleva por delante las imagenes', () {
      final m = con(cover: 'c.webp', qr: 'q.webp');
      final retirada = m.copyWith(published: false, registrationsOpen: false);

      expect(retirada.coverUrl, 'c.webp');
      expect(retirada.paymentQrUrl, 'q.webp');
      expect(retirada.published, isFalse);
      expect(retirada.registrationsOpen, isFalse);
      // Lo que no se pide no se toca.
      expect(retirada.name, m.name);
      expect(retirada.capacity, m.capacity);
      expect(retirada.startsAt, m.startsAt);
    });
  });

  group('orden del panel', () {
    AdminMarathon el(String nombre, DateTime cuando) => AdminMarathon(
      id: nombre,
      name: nombre,
      city: 'La Paz',
      startsAt: cuando,
      distanceMeters: 10000,
      capacity: 100,
      slotsTaken: 0,
      priceCents: 0,
      published: true,
      registrationsOpen: true,
      registrations: 0,
    );

    test('primero la mas proxima, y el pasado al final', () {
      final ahora = DateTime.now();
      final ordenadas = ordenarParaElPanel([
        el('dentro de un ano', ahora.add(const Duration(days: 365))),
        el('hace un mes', ahora.subtract(const Duration(days: 30))),
        el('la semana que viene', ahora.add(const Duration(days: 7))),
        el('hace un ano', ahora.subtract(const Duration(days: 365))),
      ]);

      expect(ordenadas.map((m) => m.name), [
        'la semana que viene',
        'dentro de un ano',
        // Las pasadas, de la mas reciente a la mas vieja: el archivo se lee
        // hacia atras.
        'hace un mes',
        'hace un ano',
      ]);
    });

    test('sin carreras pasadas no se inventa ninguna seccion', () {
      final ahora = DateTime.now();
      final ordenadas = ordenarParaElPanel([
        el('b', ahora.add(const Duration(days: 20))),
        el('a', ahora.add(const Duration(days: 2))),
      ]);

      expect(ordenadas.map((m) => m.name), ['a', 'b']);
      expect(ordenadas.every((m) => !m.past), isTrue);
    });
  });
}
