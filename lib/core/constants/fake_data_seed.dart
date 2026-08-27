import 'dart:math' as math;

import 'package:camrun/core/utils/route_generator.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';

/// In-memory dataset backing every `Fake*Repository`. Everything is anchored to
/// [now] so countdowns and "this week" grouping stay correct whenever the app
/// is opened. Swapping in a real API means replacing the repositories that read
/// this file, not the file itself.
abstract final class FakeDataSeed {
  static final DateTime now = DateTime.now();

  static DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The next time this calendar date comes round, so seeded events stay in the
  /// future however long the app sits unopened.
  static DateTime _nextOccurrence({
    required int month,
    required int day,
    required int hour,
  }) {
    final thisYear = DateTime(now.year, month, day, hour);
    return thisYear.isAfter(now)
        ? thisYear
        : DateTime(now.year + 1, month, day, hour);
  }

  /// Monday of the week containing [d].
  // -------------------------------------------------------------- profile

  static final UserProfile profile = UserProfile(
    id: 'user-1',
    fullName: 'Pandu Wirawan',
    email: 'pandu@camrun.app',
    city: 'Jakarta',
    country: 'Indonesia',
    avatarUrl: '',
    birthDate: DateTime(1994, 4, 17),
    gender: Gender.male,
    weightKg: 68,
    heightCm: 174,
    highlights: const RunningHighlights(
      weeklyMileageKm: 52.3,
      longestRunKm: 26,
    ),
    primaryShoes: const ShoeInfo(model: 'Pegasus 41', distanceKm: 612),
    injuryFlags: 'None in 30 days',
    sleep: const SleepStats(Duration(hours: 7, minutes: 11)),
    hydration: const HydrationStats(daysHitTarget: 4),
  );

  // ------------------------------------------------------------ marathons

  static final List<Marathon> marathons = [
    Marathon(
      id: 'ny-halloween',
      name: 'NY Halloween Marathon',
      // The next 26 October, so the name and the date always agree.
      date: _nextOccurrence(month: 10, day: 26, hour: 18),
      city: 'New York',
      country: 'United States',
      heroImageUrl: '',
      distanceKm: 42.195,
      entryFee: const Money(85),
      slotsTotal: 8000,
      slotsTaken: 6120,
      status: RegistrationStatus.open,
      predictedFinishMin: const Duration(hours: 4, minutes: 2),
      predictedFinishMax: const Duration(hours: 4, minutes: 10),
      about:
          'Five boroughs, one night, and a costume on every corner. The '
          'Halloween Marathon closes Manhattan traffic from dusk and runs a '
          'flat, fast loop lit by 12,000 pumpkins. Pacers start every 10 '
          'minutes from the 3:00 group down to 5:30.',
      schedule: const [
        ScheduleItem(
          time: 'Oct 24',
          title: 'Kit collection opens',
          detail: 'Expo at Pier 36, 10:00–20:00. Bring photo ID.',
        ),
        ScheduleItem(
          time: 'Oct 25',
          title: 'Shakeout run',
          detail: '5 km easy from Central Park, Columbus Circle, 08:00.',
        ),
        ScheduleItem(
          time: 'Oct 26 · 17:30',
          title: 'Corrals close',
          detail: 'Bag drop shuts 20 minutes before your wave.',
        ),
        ScheduleItem(
          time: 'Oct 26 · 18:00',
          title: 'Wave 1 start',
          detail: 'Sub-3:30 predicted finishers.',
        ),
      ],
      included: const [
        'Chip timing and live splits every 5 km',
        'Finisher medal and technical tee',
        'Nine aid stations with water, electrolytes and gels',
        'Bag drop and post-race recovery zone',
      ],
      routePreview: _nyRoute,
      categories: const [
        RaceCategory(
          id: 'full',
          label: 'Full marathon',
          distanceKm: 42.195,
          surcharge: Money.zero,
        ),
        RaceCategory(
          id: 'half',
          label: 'Half marathon',
          distanceKm: 21.0975,
          surcharge: Money(-25),
        ),
        RaceCategory(
          id: 'ten',
          label: '10 km',
          distanceKm: 10,
          surcharge: Money(-45),
        ),
      ],
      extras: const [
        RaceExtra(
          id: 'photos',
          label: 'Race photo pack',
          description: 'Every shot of you on course, no watermark.',
          price: Money(15),
        ),
        RaceExtra(
          id: 'shuttle',
          label: 'Start line shuttle',
          description: 'Return coach from Midtown, leaves 16:00.',
          price: Money(12),
        ),
        RaceExtra(
          id: 'pasta',
          label: 'Pasta party',
          description: 'Night-before dinner for you and one guest.',
          price: Money(28),
        ),
      ],
    ),
    Marathon(
      id: 'bali-coastal',
      name: 'Bali Coastal Half',
      date: now.add(const Duration(days: 82)),
      city: 'Sanur',
      country: 'Indonesia',
      heroImageUrl: '',
      distanceKm: 21.0975,
      entryFee: const Money(45),
      slotsTotal: 3000,
      slotsTaken: 1240,
      status: RegistrationStatus.open,
      predictedFinishMin: const Duration(hours: 1, minutes: 51),
      predictedFinishMax: const Duration(hours: 1, minutes: 58),
      about:
          'A sunrise half along the Sanur boardwalk and back through the rice '
          'terraces. Sea breeze the whole way out, shade for the return.',
      schedule: const [
        ScheduleItem(
          time: 'Day before',
          title: 'Bib pickup',
          detail: 'Beachfront expo, 09:00–18:00.',
        ),
        ScheduleItem(
          time: 'Race day · 05:30',
          title: 'Start',
          detail: 'Single wave from Mertasari Beach.',
        ),
      ],
      included: const [
        'Chip timing',
        'Finisher medal and sarong',
        'Five aid stations',
      ],
      routePreview: _baliRoute,
      extras: const [
        RaceExtra(
          id: 'photos',
          label: 'Race photo pack',
          description: 'All your course photos, delivered in 48 hours.',
          price: Money(12),
        ),
      ],
    ),
    Marathon(
      id: 'senayan-10k',
      name: 'Senayan City 10K',
      date: now.add(const Duration(days: 12)),
      city: 'Jakarta',
      country: 'Indonesia',
      heroImageUrl: '',
      distanceKm: 10,
      entryFee: const Money(25),
      slotsTotal: 5000,
      slotsTaken: 4870,
      status: RegistrationStatus.closingSoon,
      predictedFinishMin: const Duration(minutes: 48),
      predictedFinishMax: const Duration(minutes: 52),
      about:
          'Two laps of the Senayan complex on closed roads. Flat, fast and the '
          'fixture most Jakarta runners use to chase a personal best.',
      schedule: const [
        ScheduleItem(
          time: 'Race day · 05:00',
          title: 'Bag drop opens',
          detail: 'Gate 7, Gelora Bung Karno.',
        ),
        ScheduleItem(
          time: 'Race day · 06:00',
          title: 'Start',
          detail: 'Rolling start by predicted finish time.',
        ),
      ],
      included: const ['Chip timing', 'Finisher medal', 'Three aid stations'],
      routePreview: _senayanRoute,
    ),
    Marathon(
      id: 'kyoto-night',
      name: 'Kyoto Night Run 5K',
      date: now.add(const Duration(days: 46)),
      city: 'Kyoto',
      country: 'Japan',
      heroImageUrl: '',
      distanceKm: 5,
      entryFee: const Money(20),
      slotsTotal: 2000,
      slotsTaken: 2000,
      status: RegistrationStatus.full,
      about:
          'A lantern-lit 5 km along the Kamo river. Entries sold out in under '
          'four hours; a waiting list opens two weeks before race day.',
      schedule: const [
        ScheduleItem(
          time: 'Race day · 19:00',
          title: 'Start',
          detail: 'Sanjo Bridge, groups of 200 every five minutes.',
        ),
      ],
      included: const ['Chip timing', 'Lantern and finisher towel'],
      routePreview: _kyotoRoute,
    ),
    Marathon(
      id: 'jakarta-marathon',
      name: 'Jakarta Marathon',
      date: now.subtract(const Duration(days: 96)),
      city: 'Jakarta',
      country: 'Indonesia',
      heroImageUrl: '',
      distanceKm: 42.195,
      entryFee: const Money(80),
      slotsTotal: 12000,
      slotsTaken: 12000,
      status: RegistrationStatus.closed,
      about:
          'The city\'s flagship marathon, run on closed roads through Monas, '
          'Kota Tua and back down Sudirman.',
      schedule: const [],
      included: const ['Chip timing', 'Finisher medal and tee'],
      routePreview: _senayanRoute,
    ),
    Marathon(
      id: 'bandung-highland',
      name: 'Bandung Highland Half',
      date: now.subtract(const Duration(days: 187)),
      city: 'Bandung',
      country: 'Indonesia',
      heroImageUrl: '',
      distanceKm: 21.0975,
      entryFee: const Money(50),
      slotsTotal: 2500,
      slotsTaken: 2500,
      status: RegistrationStatus.closed,
      about:
          'A hard half through the tea plantations north of the city. '
          '640 metres of climbing, all of it in the first 12 km.',
      schedule: const [],
      included: const ['Chip timing', 'Finisher medal'],
      routePreview: _baliRoute,
    ),
  ];

  static Marathon get featuredMarathon => marathons.first;

  // ------------------------------------------------------------- history

  /// 25 completed runs spread over the last eight weeks.
  static final List<TrainingRun> runs = _buildRuns();

  static List<TrainingRun> _buildRuns() {
    const centerLat = -6.2088;
    const centerLng = 106.8456;
    const shapes = <({double km, SessionType type, String title, int paceSec})>[
      (
        km: 5.2,
        type: SessionType.easy,
        title: RunTitleKey.morning,
        paceSec: 380,
      ),
      (
        km: 8.1,
        type: SessionType.tempo,
        title: RunTitleKey.tempo,
        paceSec: 322,
      ),
      (
        km: 6.4,
        type: SessionType.easy,
        title: RunTitleKey.evening,
        paceSec: 372,
      ),
      (km: 14.3, type: SessionType.long, title: RunTitleKey.long, paceSec: 398),
      (
        km: 4.0,
        type: SessionType.intervals,
        title: RunTitleKey.trackSession,
        paceSec: 305,
      ),
      (
        km: 10.6,
        type: SessionType.easy,
        title: RunTitleKey.lunch,
        paceSec: 366,
      ),
    ];

    final runs = <TrainingRun>[];
    // Roughly three sessions a week, walking backwards from yesterday.
    for (var i = 0; i < 25; i++) {
      final shape = shapes[i % shapes.length];
      final daysAgo = 1 + (i * 56 / 25).round();
      final started = _atMidnight(now)
          .subtract(Duration(days: daysAgo))
          .add(Duration(hours: 6 + i % 3, minutes: (i * 7) % 60));
      final pace = Duration(seconds: shape.paceSec + (i % 5) * 4 - 8);

      final route = RouteGenerator.loop(
        distanceKm: shape.km,
        centerLat: centerLat + (i % 4) * 0.004,
        centerLng: centerLng - (i % 3) * 0.005,
        startedAt: started,
        pacePerKm: pace,
        seed: i,
      );
      final distanceKm = RouteGenerator.distanceKmOf(route);
      final elapsed = route.last.timestamp.difference(route.first.timestamp);
      final splits = RouteGenerator.splitsOf(route);

      runs.add(
        TrainingRun(
          id: 'run-$i',
          startedAt: started,
          finishedAt: route.last.timestamp,
          distanceKm: distanceKm,
          elapsed: elapsed,
          movingTime: elapsed - Duration(seconds: 20 + i % 40),
          avgPacePerKm: Duration(
            seconds: (elapsed.inSeconds / distanceKm).round(),
          ),
          elevationGainM: RouteGenerator.elevationGainOf(route),
          avgSpeedKmh: distanceKm / (elapsed.inSeconds / 3600),
          route: route,
          splits: splits,
          type: shape.type,
          title: shape.title,
          avgHeartRate: 138 + (i % 7) * 4,
          calories: (distanceKm * 63).round(),
          feeling: RunFeeling.values[i % RunFeeling.values.length],
        ),
      );
    }
    return runs;
  }

  // --------------------------------------------------------------- races

  static final List<RaceEntry> raceEntries = _buildRaceEntries();

  static List<RaceEntry> _buildRaceEntries() {
    final jakarta = marathons.firstWhere((m) => m.id == 'jakarta-marathon');
    final bandung = marathons.firstWhere((m) => m.id == 'bandung-highland');

    return [
      RaceEntry(
        id: 'entry-ny',
        marathon: featuredMarathon,
        registeredAt: now.subtract(const Duration(days: 21)),
        amountPaid: const Money(85),
        paymentStatus: PaymentStatus.paid,
        bibNumber: '0666',
        status: RaceEntryStatus.upcoming,
      ),
      RaceEntry(
        id: 'entry-senayan',
        marathon: marathons.firstWhere((m) => m.id == 'senayan-10k'),
        registeredAt: now.subtract(const Duration(days: 3)),
        amountPaid: const Money(25),
        paymentStatus: PaymentStatus.pending,
        bibNumber: '1042',
        status: RaceEntryStatus.upcoming,
        paymentMethod: 'Wallet',
      ),
      RaceEntry(
        id: 'entry-jakarta',
        marathon: jakarta,
        registeredAt: now.subtract(const Duration(days: 150)),
        amountPaid: const Money(80),
        paymentStatus: PaymentStatus.paid,
        bibNumber: '3187',
        status: RaceEntryStatus.completed,
        result: _resultFor(
          marathon: jakarta,
          finish: const Duration(hours: 4, minutes: 6, seconds: 12),
          rank: 412,
          ageRank: 88,
          participants: 5200,
          seed: 91,
        ),
      ),
      RaceEntry(
        id: 'entry-bandung',
        marathon: bandung,
        registeredAt: now.subtract(const Duration(days: 240)),
        amountPaid: const Money(50),
        paymentStatus: PaymentStatus.paid,
        bibNumber: '0914',
        status: RaceEntryStatus.completed,
        result: _resultFor(
          marathon: bandung,
          finish: const Duration(hours: 1, minutes: 58, seconds: 41),
          rank: 233,
          ageRank: 51,
          participants: 2140,
          seed: 77,
        ),
      ),
    ];
  }

  static RaceResult _resultFor({
    required Marathon marathon,
    required Duration finish,
    required int rank,
    required int ageRank,
    required int participants,
    required int seed,
  }) {
    final route = RouteGenerator.loop(
      distanceKm: marathon.distanceKm,
      centerLat: -6.1751,
      centerLng: 106.8272,
      startedAt: marathon.date.add(const Duration(hours: 6)),
      pacePerKm: Duration(
        seconds: (finish.inSeconds / marathon.distanceKm).round(),
      ),
      seed: seed,
      samples: 260,
    );
    final splits = RouteGenerator.splitsOf(route);
    return RaceResult(
      finishTime: finish,
      chipTime: finish - const Duration(seconds: 47),
      avgPacePerKm: Duration(
        seconds: (finish.inSeconds / marathon.distanceKm).round(),
      ),
      avgSpeedKmh: marathon.distanceKm / (finish.inSeconds / 3600),
      distanceKm: marathon.distanceKm,
      route: route,
      splits: splits,
      elevationGainM: RouteGenerator.elevationGainOf(route),
      overallRank: rank,
      ageGroupRank: ageRank,
      totalParticipants: participants,
      bestKm: splits.isEmpty
          ? null
          : splits.map((s) => s.pace).reduce((a, b) => a <= b ? a : b),
    );
  }

  // ------------------------------------------------- official route stubs

  static List<({double lat, double lng})> _arc(
    double lat,
    double lng,
    double radiusDeg,
  ) => [
    for (var i = 0; i <= 40; i++)
      (
        lat: lat + radiusDeg * math.sin(i / 40 * math.pi * 2) * 0.7,
        lng: lng + radiusDeg * math.cos(i / 40 * math.pi * 2),
      ),
  ];

  static final _nyRoute = _arc(40.7580, -73.9855, 0.03);
  static final _baliRoute = _arc(-8.6870, 115.2620, 0.02);
  static final _senayanRoute = _arc(-6.2185, 106.8020, 0.012);
  static final _kyotoRoute = _arc(35.0094, 135.7720, 0.01);
}
