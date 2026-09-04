import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('una ida y vuelta se aparta a lados opuestos', () {
    // Ida al este por el ecuador y vuelta por la misma linea.
    final ida = [for (var i = 0; i <= 4; i++) LatLng(0, i * 0.01)];
    final vuelta = [for (var i = 4; i >= 0; i--) LatLng(0, i * 0.01)];

    final a = apartarTrazado(ida, 9);
    final b = apartarTrazado(vuelta, 9);

    // Yendo al este la derecha es el sur; al oeste, el norte.
    expect(a[2].latitude, lessThan(0));
    expect(b[2].latitude, greaterThan(0));
    // Y se separan lo pedido, no mas.
    expect((a[2].latitude - b[2].latitude).abs() * 111320, closeTo(18, 1));
  });

  test('un trazado de un punto se devuelve igual', () {
    final uno = [const LatLng(-16.5, -68.1)];
    expect(apartarTrazado(uno, 9), uno);
  });
}
