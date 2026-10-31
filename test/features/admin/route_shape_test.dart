import 'package:camrun/features/admin/presentation/pages/admin_route_editor_page.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

GeoPoint _p(double lat, double lng) =>
    GeoPoint(lat: lat, lng: lng, timestamp: DateTime(2000));

List<({double lat, double lng})> _ll(List<GeoPoint> r) => [
  for (final p in r) (lat: p.lat, lng: p.lng),
];

void main() {
  final a = _p(-16.50, -68.13);
  final b = _p(-16.51, -68.13);
  final c = _p(-16.51, -68.14);

  test('lineal deja los vertices tal cual', () {
    expect(routeForShape([a, b, c], RouteShape.line), [a, b, c]);
  });

  test('ida y vuelta no repite el punto de giro', () {
    expect(routeForShape([a, b, c], RouteShape.outAndBack), [a, b, c, b, a]);
  });

  test('circular cierra en el primer punto: salida y meta son una', () {
    final ruta = routeForShape([a, b, c], RouteShape.loop);
    expect(ruta, [a, b, c, a]);
    expect(isClosedLoop(_ll(ruta)), isTrue);
  });

  test('un trazado abierto no se toma por circuito', () {
    expect(isClosedLoop(_ll([a, b, c])), isFalse);
    expect(isClosedLoop(_ll([a, a])), isFalse);
  });
}
