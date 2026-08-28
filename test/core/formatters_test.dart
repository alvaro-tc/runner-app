import 'package:camrun/core/formatters/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('distance', () {
    test('renders kilometres with one decimal by default', () {
      expect(Fmt.distance(12.53), '12.5 km');
    });

    test('converts to miles when asked', () {
      expect(Fmt.distance(10, miles: true), '6.2 mi');
    });

    test('shortens to a ring label', () {
      expect(Fmt.distanceShort(13.6), '14K');
    });
  });

  group('pace', () {
    test('formats minutes and padded seconds', () {
      expect(Fmt.pace(const Duration(minutes: 5, seconds: 53)), '5:53');
    });

    test('returns placeholder for a zero pace', () {
      expect(Fmt.pace(Duration.zero), '--:--');
    });

    test('scales per-km pace up to per-mile', () {
      // 6:00/km is roughly 9:39/mi.
      expect(Fmt.pace(const Duration(minutes: 6), miles: true), '9:39');
    });

    test('renders a range with a single unit suffix', () {
      expect(
        Fmt.paceRange(
          const Duration(minutes: 6, seconds: 10),
          const Duration(minutes: 6, seconds: 30),
        ),
        '6:10–6:30/km',
      );
    });
  });

  group('duration', () {
    test('clock always carries hours', () {
      expect(
        Fmt.clock(const Duration(hours: 4, minutes: 32, seconds: 16)),
        '04:32:16',
      );
      expect(Fmt.clock(const Duration(seconds: 9)), '00:00:09');
    });

    test('short form drops empty units', () {
      expect(Fmt.durationShort(const Duration(hours: 4, minutes: 2)), '4h 02m');
      expect(Fmt.durationShort(const Duration(minutes: 45)), '45 min');
      expect(Fmt.durationShort(const Duration(seconds: 52)), '52s');
    });

    test('countdown splits into padded parts', () {
      final parts = Fmt.countdown(
        const Duration(days: 34, hours: 10, minutes: 24, seconds: 5),
      );
      expect(parts.days, '34');
      expect(parts.hours, '10');
      expect(parts.minutes, '24');
      expect(parts.seconds, '05');
    });

    test('countdown clamps a past date to zero', () {
      final parts = Fmt.countdown(const Duration(days: -2));
      expect(parts.days, '0');
      expect(parts.hours, '00');
    });
  });

  test('rank groups thousands', () {
    expect(Fmt.rank(412, 5200), '#412 / 5,200');
  });
}
