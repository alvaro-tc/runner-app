import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paceup/core/theme/app_theme.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/races/domain/entities/race_entry.dart';
import 'package:paceup/features/races/presentation/widgets/race_card.dart';
import 'package:paceup/shared/widgets/atoms/app_button.dart';
import 'package:paceup/shared/widgets/atoms/app_progress_ring.dart';
import 'package:paceup/shared/widgets/molecules/countdown_pill.dart';

Widget wrap(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppButton', () {
    testWidgets('fires its callback when enabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(AppButton(label: 'Start Run', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Start Run'));
      expect(taps, 1);
    });

    testWidgets('ignores taps when disabled', (tester) async {
      await tester.pumpWidget(
        wrap(const AppButton(label: 'Start Run', onPressed: null)),
      );
      await tester.tap(find.text('Start Run'));
      // Nothing to assert beyond not throwing: there is no callback to run.
      expect(find.text('Start Run'), findsOneWidget);
    });

    testWidgets('swaps the label for a spinner while loading', (tester) async {
      await tester.pumpWidget(
        wrap(const AppButton(label: 'Login', isLoading: true, onPressed: null)),
      );
      expect(find.text('Login'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppProgressRing', () {
    testWidgets('shows its centre label', (tester) async {
      await tester.pumpWidget(
        wrap(const AppProgressRing(progress: 0.5, label: '14K')),
      );
      await tester.pumpAndSettle();
      expect(find.text('14K'), findsOneWidget);
    });

    testWidgets('survives out-of-range progress', (tester) async {
      await tester.pumpWidget(
        wrap(const AppProgressRing(progress: 2.4, label: '5K')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('CountdownPill', () {
    testWidgets('splits the remaining time into labelled parts', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const CountdownPill(
            remaining: Duration(days: 34, hours: 10, minutes: 24),
          ),
        ),
      );
      expect(find.text('34'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('d'), findsOneWidget);
    });

    testWidgets('renders zeroes for an event in the past', (tester) async {
      await tester.pumpWidget(
        wrap(const CountdownPill(remaining: Duration(days: -3))),
      );
      expect(find.text('0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('RaceCard', () {
    final marathon = Marathon(
      id: 'ny',
      name: 'NY Halloween Marathon',
      date: DateTime(2026, 10, 26),
      city: 'New York',
      country: 'United States',
      heroImageUrl: '',
      distanceKm: 42.195,
      entryFee: const Money(85),
      slotsTotal: 8000,
      slotsTaken: 6120,
      status: RegistrationStatus.open,
      about: '',
      schedule: const [],
      included: const [],
      routePreview: const [],
    );

    testWidgets('an upcoming entry shows payment state and a CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          RaceCard(
            entry: RaceEntry(
              id: 'e1',
              marathon: marathon,
              registeredAt: DateTime(2026),
              amountPaid: const Money(85),
              paymentStatus: PaymentStatus.paid,
              bibNumber: '0666',
              status: RaceEntryStatus.upcoming,
            ),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('BIB 0666'), findsOneWidget);
      expect(find.text(r'Paid $85.00'), findsOneWidget);
      expect(find.text('View details'), findsOneWidget);
    });

    testWidgets('a finished entry shows the result instead', (tester) async {
      await tester.pumpWidget(
        wrap(
          RaceCard(
            entry: RaceEntry(
              id: 'e2',
              marathon: marathon,
              registeredAt: DateTime(2026),
              amountPaid: const Money(85),
              paymentStatus: PaymentStatus.paid,
              bibNumber: '3187',
              status: RaceEntryStatus.completed,
              result: const RaceResult(
                finishTime: Duration(hours: 4, minutes: 6, seconds: 12),
                chipTime: Duration(hours: 4, minutes: 5),
                avgPacePerKm: Duration(minutes: 5, seconds: 50),
                avgSpeedKmh: 10.3,
                distanceKm: 42.195,
                route: [],
                splits: [],
                elevationGainM: 120,
                overallRank: 412,
                totalParticipants: 5200,
              ),
            ),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('04:06:12'), findsOneWidget);
      expect(find.text('#412'), findsOneWidget);
      expect(find.text('View details'), findsNothing);
    });
  });
}
