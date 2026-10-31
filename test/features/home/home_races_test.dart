import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/presentation/pages/home_page.dart';
import 'package:flutter_test/flutter_test.dart';

Marathon _m(
  String id,
  DateTime date, {
  String cover = '',
  String vertical = '',
  String horizontal = '',
  DateTime? finishedAt,
}) => Marathon(
  id: id,
  name: id,
  date: date,
  city: 'La Paz',
  country: 'BO',
  heroImageUrl: cover,
  logoVerticalUrl: vertical,
  logoHorizontalUrl: horizontal,
  distanceKm: 10,
  entryFee: const Money(80, 'BOB'),
  slotsTotal: 100,
  slotsTaken: 10,
  status: RegistrationStatus.open,
  about: '',
  schedule: const [],
  included: const [],
  routePreview: const [],
  liveStartedAt: finishedAt,
  liveFinishedAt: finishedAt,
);

void main() {
  group('la carrera destacada', () {
    test('es la mas proxima, aunque el resumen destaque otra', () {
      final lejana = _m('lejana', DateTime(2026, 12, 2));
      final cerca = _m('cerca', DateTime(2026, 11, 2));
      final carreras = upcomingRaces(lejana, [cerca, lejana]);
      expect(carreras.map((m) => m.id), ['cerca', 'lejana']);
    });

    test('no descarta una carrera futura con una largada de prueba', () {
      // En produccion la proxima carrera tenia `liveFinishedAt` de un ensayo
      // y el inicio la escondia.
      final ensayada = _m(
        'ensayada',
        DateTime(2026, 11, 22),
        finishedAt: DateTime(2026, 10, 9),
      );
      expect(upcomingRaces(null, [ensayada]).map((m) => m.id), ['ensayada']);
    });
  });

  group('que imagen pinta cada hueco', () {
    final ambas = _m(
      'a',
      DateTime(2026, 11, 2),
      cover: 'cover',
      vertical: 'v',
      horizontal: 'h',
    );

    test('el hueco alto lleva el vertical; el apaisado, el horizontal', () {
      expect(ambas.artworkFor(4 / 5), (url: 'v', isLogo: true));
      expect(ambas.artworkFor(16 / 10), (url: 'h', isLogo: true));
      // Un cuadrado grande lo llena mejor el vertical.
      expect(ambas.artworkFor(1), (url: 'v', isLogo: true));
    });

    test('las miniaturas llevan el logo pequeno', () {
      expect(ambas.artworkFor(1, small: true), (url: 'cover', isLogo: true));
      final sinLogo = _m('d', DateTime(2026, 11, 2), vertical: 'v');
      expect(sinLogo.artworkFor(1, small: true), (url: 'v', isLogo: true));
    });

    test('sin el material de su forma, el otro; sin ninguno, el logo', () {
      final soloH = _m('b', DateTime(2026, 11, 2), horizontal: 'h');
      expect(soloH.artworkFor(4 / 5), (url: 'h', isLogo: true));
      final soloCover = _m('c', DateTime(2026, 11, 2), cover: 'cover');
      expect(soloCover.artworkFor(1), (url: 'cover', isLogo: true));
    });
  });
}
