import 'package:camrun/app/router/app_routes.dart';
import 'package:camrun/app/router/guards.dart';
import 'package:camrun/features/admin/domain/admin_models.dart';
import 'package:camrun/features/organizer/domain/organizer_participant.dart';
import 'package:camrun/features/organizer/presentation/providers/organizer_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdminMarathon marathon({String? startedAt, String? finishedAt}) =>
      AdminMarathon.fromJson({
        'id': startedAt ?? 'idle',
        'name': 'Carrera',
        'city': 'La Paz',
        'startsAt': '2026-09-25T12:00:00.000Z',
        'liveStartedAt': startedAt,
        'liveFinishedAt': finishedAt,
      });

  test('el home elige solo una maraton realmente en curso', () {
    final preparing = marathon();
    final running = marathon(startedAt: '2026-09-25T12:01:00.000Z');
    final finished = marathon(
      startedAt: '2026-09-24T12:01:00.000Z',
      finishedAt: '2026-09-24T16:00:00.000Z',
    );

    expect(currentRunningMarathon([preparing, running, finished]), running);
    expect(currentRunningMarathon([preparing, finished]), isNull);
  });

  test('los datos privados se cruzan por dorsal', () {
    final participant = OrganizerParticipant.fromJson(const {
      'id': 'reg-1',
      'runner': 'Nicol Flores',
      'bibNumber': 'A-017',
      'email': 'nicol@example.com',
      'phone': '76543210',
    });

    expect(participant.name, 'Nicol Flores');
    expect(participant.bib, 'A-017');
    expect(participant.phone, '76543210');
  });

  group('frontera de rutas del organizador', () {
    test('no puede entrar al panel de admin escribiendo la ruta', () {
      expect(
        staffAreaRedirect(
          role: 'organizer',
          inAdminArea: true,
          inOrganizerArea: false,
        ),
        Routes.organizer,
      );
    });

    test('permanece dentro de su propio arbol', () {
      expect(
        staffAreaRedirect(
          role: 'organizer',
          inAdminArea: false,
          inOrganizerArea: true,
        ),
        isNull,
      );
    });

    test('un corredor tampoco puede entrar a ninguno de los paneles', () {
      expect(
        staffAreaRedirect(
          role: 'runner',
          inAdminArea: true,
          inOrganizerArea: false,
        ),
        Routes.home,
      );
    });
  });
}
