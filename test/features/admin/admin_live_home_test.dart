import 'package:camrun/core/network/live_socket.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/admin/presentation/providers/admin_providers.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdminMarathon marathon(
    String id, {
    String? preparingAt,
    String? startedAt,
    String? finishedAt,
  }) => AdminMarathon.fromJson({
    'id': id,
    'name': 'Carrera $id',
    'city': 'La Paz',
    'startsAt': '2026-09-25T12:00:00.000Z',
    'preparingAt': preparingAt,
    'liveStartedAt': startedAt,
    'liveFinishedAt': finishedAt,
  });

  group('selector del mapa de admin', () {
    test('conserva la maraton elegida aunque exista otra en curso', () {
      final selected = marathon('elegida');
      final running = marathon('activa', startedAt: '2026-09-25T12:01:00.000Z');

      expect(
        selectMarathonForLivePanel([running, selected], selected.id),
        same(selected),
      );
    });

    test('sin eleccion prioriza la carrera en curso', () {
      final idle = marathon('pendiente');
      final running = marathon('activa', startedAt: '2026-09-25T12:01:00.000Z');

      expect(selectMarathonForLivePanel([idle, running], null), same(running));
    });
  });

  group('controles por estado', () {
    test('antes de largar solo corresponde iniciar', () {
      expect(
        adminLiveControlFor(marathon('m1'), const LiveBoard(loading: false)),
        AdminLiveControl.start,
      );
    });

    test('durante la carrera corresponde finalizar', () {
      expect(
        adminLiveControlFor(
          marathon('m1'),
          LiveBoard(
            startedAt: DateTime.parse('2026-09-25T12:01:00.000Z'),
            loading: false,
          ),
        ),
        AdminLiveControl.finish,
      );
    });

    test('despues de terminar no corresponde ningun boton activo', () {
      expect(
        adminLiveControlFor(
          marathon('m1'),
          LiveBoard(
            startedAt: DateTime.parse('2026-09-25T12:01:00.000Z'),
            finishedAt: DateTime.parse('2026-09-25T16:00:00.000Z'),
            loading: false,
          ),
        ),
        AdminLiveControl.finished,
      );
    });
  });

  test('finalizar vacia de inmediato los puntos del mapa', () {
    final position = LivePosition(
      bib: 'A-017',
      lat: -16.5,
      lng: -68.15,
      distanceMeters: 1250,
      at: DateTime.parse('2026-09-25T13:00:00.000Z'),
    );
    final before = LiveBoard(
      runners: {'A-017': position},
      finishedBibs: const {'A-017'},
      startedAt: DateTime.parse('2026-09-25T12:01:00.000Z'),
      loading: false,
    );

    final after = liveBoardAfterServerState(
      current: before,
      marathonId: 'm1',
      next: MarathonLiveState(
        marathonId: 'm1',
        startedAt: DateTime.parse('2026-09-25T12:01:00.000Z'),
        finishedAt: DateTime.parse('2026-09-25T16:00:00.000Z'),
      ),
    );

    expect(after.runners, isEmpty);
    expect(after.finishedBibs, isEmpty);
    expect(after.phase, MarathonPhase.finished);
  });
}
