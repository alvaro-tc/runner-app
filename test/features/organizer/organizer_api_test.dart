import 'package:camrun/core/network/interceptors.dart';
import 'package:camrun/core/network/server_clock.dart';
import 'package:camrun/features/admin/data/admin_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fake_http.dart';

void main() {
  test('carga todas las paginas de inscritos confirmados', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = FakeAdapter((request) async {
        requests.add(request);
        final page = request.queryParameters['page'] as int;
        return envelope({
          'data': [
            {
              'id': 'reg-$page',
              'runner': 'Corredor $page',
              'bibNumber': 'A-00$page',
            },
          ],
          'meta': {'page': page, 'totalPages': 2},
        });
      })
      ..interceptors.add(EnvelopeInterceptor(ServerClock()));

    final rows = await AdminApi(dio).confirmedRegistrations('marathon-1');

    expect(rows.map((row) => row['bibNumber']), ['A-001', 'A-002']);
    expect(requests, hasLength(2));
    expect(requests.first.queryParameters, {
      'marathonId': 'marathon-1',
      'status': 'confirmed',
      'page': 1,
      'limit': 100,
    });
  });
}
