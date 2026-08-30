import 'package:camrun/core/network/interceptors.dart';
import 'package:camrun/core/network/server_clock.dart';
import 'package:camrun/features/admin/data/admin_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fake_http.dart';

/// El listado de usuarios del panel.
///
/// Lo que se comprueba es que el filtro y la pagina **viajan al servidor** y
/// que el total llega. Filtrar en el cliente era el bug: la lista viene por
/// paginas, y los organizadores —tres cuentas, de las primeras creadas— nunca
/// caian en la primera.
void main() {
  late RequestOptions ultimaPeticion;

  AdminApi apiCon({required int total, int filas = 2}) {
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = FakeAdapter((req) async {
        ultimaPeticion = req;
        return jsonBody({
          'data': [
            for (var i = 0; i < filas; i++)
              {'id': 'u$i', 'name': 'Ana $i', 'role': 'organizer'},
          ],
          'meta': {'requestId': 'req-1', 'total': total, 'page': 1},
        }, 200);
      })
      ..interceptors.add(EnvelopeInterceptor(ServerClock()));
    return AdminApi(dio);
  }

  test('el rol, la busqueda y la pagina van en la consulta', () async {
    await apiCon(
      total: 7,
    ).users(search: '76543210', role: 'organizer', page: 3, pageSize: 50);

    expect(ultimaPeticion.queryParameters, {
      'q': '76543210',
      'role': 'organizer',
      'page': 3,
      'pageSize': 50,
    });
  });

  test('sin rol ni busqueda solo viaja la paginacion', () async {
    await apiCon(total: 7).users();

    expect(ultimaPeticion.queryParameters, {'page': 1, 'pageSize': 20});
  });

  test('el total sale de meta, no de las filas que vinieron', () async {
    final pagina = await apiCon(total: 340).users();

    expect(pagina.total, 340);
    expect(pagina.filas, hasLength(2));
  });

  test('si el sobre no trae total, se cae al numero de filas', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = FakeAdapter(
        (req) async => envelope([
          {'id': 'u0', 'name': 'Ana', 'role': 'runner'},
        ]),
      )
      ..interceptors.add(EnvelopeInterceptor(ServerClock()));

    expect((await AdminApi(dio).users()).total, 1);
  });
}
