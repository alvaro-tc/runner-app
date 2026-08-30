import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un punto a [metros] al norte del origen, en el segundo [segundo].
GeoPoint _p(int segundo, double metros, {double accuracy = 5}) => GeoPoint(
  lat: -16.5 + metros / 111_320,
  lng: -68.13,
  timestamp: DateTime.utc(2026, 8, 20, 12, 0, segundo),
  accuracy: accuracy,
);

void main() {
  Future<List<double>> filtrar(List<GeoPoint> puntos) async {
    final salida = await soloMovimiento(Stream.fromIterable(puntos)).toList();
    return [for (final p in salida) (p.lat + 16.5) * 111_320];
  }

  test('parado, el ruido del GPS no pasa', () async {
    // Cinco lecturas seguidas moviendose 3 m cada una: es un semaforo, no
    // quince metros corridos.
    final metros = await filtrar([
      _p(0, 0),
      _p(1, 3),
      _p(2, 0),
      _p(3, 3),
      _p(4, 0),
    ]);
    expect(metros, hasLength(1));
  });

  test('corriendo, los puntos pasan', () async {
    final metros = await filtrar([_p(0, 0), _p(1, 10), _p(2, 20), _p(3, 30)]);
    expect(metros, hasLength(4));
  });

  test('un salto del sensor se descarta', () async {
    // 500 m en un segundo: nadie corre asi.
    final metros = await filtrar([_p(0, 0), _p(1, 500), _p(2, 10)]);
    expect(metros.map((m) => m.round()), [0, 10]);
  });

  test('con poca precision hace falta moverse mas', () async {
    // Con 20 m de error declarado, 10 m de desplazamiento pueden ser el error.
    final metros = await filtrar([
      _p(0, 0, accuracy: 20),
      _p(1, 10, accuracy: 20),
      _p(4, 40, accuracy: 20),
    ]);
    expect(metros.map((m) => m.round()), [0, 40]);
  });
}
