import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:flutter_test/flutter_test.dart';

Marathon _marathon({required String id, required double distanceKm}) =>
    Marathon(
      id: id,
      name: id,
      date: DateTime(2026, 10, 26),
      city: 'Jakarta',
      country: 'Indonesia',
      heroImageUrl: '',
      distanceKm: distanceKm,
      entryFee: const Money(80),
      slotsTotal: 100,
      slotsTaken: 10,
      status: RegistrationStatus.open,
      about: '',
      schedule: const [],
      included: const [],
      routePreview: const [],
    );

RaceResult _result({required Duration finish, required double distanceKm}) =>
    RaceResult(
      finishTime: finish,
      chipTime: finish,
      avgPacePerKm: const Duration(minutes: 6),
      avgSpeedKmh: 10,
      distanceKm: distanceKm,
      route: const [],
      splits: const [],
      elevationGainM: 0,
    );

RaceEntry _entry({
  required String id,
  required double distanceKm,
  required PaymentStatus payment,
  required double paid,
  Duration? finish,
}) => RaceEntry(
  id: id,
  marathon: _marathon(id: id, distanceKm: distanceKm),
  registeredAt: DateTime(2026),
  amountPaid: Money(paid),
  paymentStatus: payment,
  bibNumber: '0001',
  status: finish == null ? RaceEntryStatus.upcoming : RaceEntryStatus.completed,
  result: finish == null
      ? null
      : _result(finish: finish, distanceKm: distanceKm),
);

void main() {
  group('RaceTotals', () {
    test('counts every entry, finished or not', () {
      final totals = RaceTotals.from([
        _entry(
          id: 'a',
          distanceKm: 42.195,
          payment: PaymentStatus.paid,
          paid: 85,
          finish: const Duration(hours: 4, minutes: 6),
        ),
        _entry(
          id: 'b',
          distanceKm: 10,
          payment: PaymentStatus.pending,
          paid: 25,
        ),
      ]);
      expect(totals.racesJoined, 2);
    });

    test('only finished races contribute distance', () {
      final totals = RaceTotals.from([
        _entry(
          id: 'a',
          distanceKm: 42.195,
          payment: PaymentStatus.paid,
          paid: 85,
          finish: const Duration(hours: 4),
        ),
        _entry(id: 'b', distanceKm: 10, payment: PaymentStatus.paid, paid: 25),
      ]);
      expect(totals.distanceRacedKm, closeTo(42.195, 0.001));
    });

    test('only paid entries contribute to the amount spent', () {
      final totals = RaceTotals.from([
        _entry(id: 'a', distanceKm: 10, payment: PaymentStatus.paid, paid: 25),
        _entry(
          id: 'b',
          distanceKm: 10,
          payment: PaymentStatus.pending,
          paid: 30,
        ),
        _entry(
          id: 'c',
          distanceKm: 10,
          payment: PaymentStatus.refunded,
          paid: 40,
        ),
      ]);
      expect(totals.totalSpent.amount, 25);
    });

    test('best marathon takes the fastest full-distance finish', () {
      final totals = RaceTotals.from([
        _entry(
          id: 'slow',
          distanceKm: 42.195,
          payment: PaymentStatus.paid,
          paid: 85,
          finish: const Duration(hours: 4, minutes: 30),
        ),
        _entry(
          id: 'fast',
          distanceKm: 42.195,
          payment: PaymentStatus.paid,
          paid: 85,
          finish: const Duration(hours: 4, minutes: 6),
        ),
        _entry(
          id: 'half',
          distanceKm: 21.1,
          payment: PaymentStatus.paid,
          paid: 50,
          finish: const Duration(hours: 1, minutes: 52),
        ),
      ]);
      expect(totals.bestMarathon, const Duration(hours: 4, minutes: 6));
    });

    test('no marathon finish leaves the best time null', () {
      final totals = RaceTotals.from([
        _entry(id: 'a', distanceKm: 10, payment: PaymentStatus.paid, paid: 25),
      ]);
      expect(totals.bestMarathon, isNull);
      expect(totals.distanceRacedKm, 0);
    });

    test('an empty list produces zero totals', () {
      final totals = RaceTotals.from(const []);
      expect(totals.racesJoined, 0);
      expect(totals.totalSpent.amount, 0);
    });
  });
}
