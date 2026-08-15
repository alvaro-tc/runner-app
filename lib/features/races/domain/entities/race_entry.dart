import 'package:meta/meta.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/train/domain/entities/training_run.dart';

enum PaymentStatus {
  paid('Paid'),
  pending('Payment pending'),
  refunded('Refunded');

  const PaymentStatus(this.label);
  final String label;
}

enum RaceEntryStatus {
  upcoming('Upcoming'),
  completed('Completed'),
  dnf('Did not finish'),
  cancelled('Cancelled');

  const RaceEntryStatus(this.label);
  final String label;
}

@immutable
class RaceResult {
  const RaceResult({
    required this.finishTime,
    required this.chipTime,
    required this.avgPacePerKm,
    required this.avgSpeedKmh,
    required this.distanceKm,
    required this.route,
    required this.splits,
    required this.elevationGainM,
    this.overallRank,
    this.ageGroupRank,
    this.totalParticipants,
    this.bestKm,
  });

  final Duration finishTime;
  final Duration chipTime;
  final Duration avgPacePerKm;
  final double avgSpeedKmh;
  final double distanceKm;
  final List<GeoPoint> route;
  final List<KmSplit> splits;
  final double elevationGainM;
  final int? overallRank;
  final int? ageGroupRank;
  final int? totalParticipants;
  final Duration? bestKm;
}

@immutable
class RaceEntry {
  const RaceEntry({
    required this.id,
    required this.marathon,
    required this.registeredAt,
    required this.amountPaid,
    required this.paymentStatus,
    required this.bibNumber,
    required this.status,
    this.paymentMethod = 'Card •••• 4242',
    this.result,
  });

  final String id;
  final Marathon marathon;
  final DateTime registeredAt;
  final Money amountPaid;
  final PaymentStatus paymentStatus;
  final String bibNumber;
  final RaceEntryStatus status;
  final String paymentMethod;
  final RaceResult? result;

  bool get isUpcoming => status == RaceEntryStatus.upcoming;
  bool get hasResult => result != null;
}

/// Aggregates shown in the "My Races" header. Derived, never stored.
@immutable
class RaceTotals {
  const RaceTotals({
    required this.racesJoined,
    required this.distanceRacedKm,
    required this.totalSpent,
    this.bestMarathon,
  });

  factory RaceTotals.from(List<RaceEntry> entries) {
    final finished = entries.where((e) => e.result != null).toList();
    final marathons = finished.where((e) => e.marathon.distanceKm >= 42);
    return RaceTotals(
      racesJoined: entries.length,
      distanceRacedKm: finished.fold(0, (s, e) => s + e.result!.distanceKm),
      totalSpent: Money(
        entries
            .where((e) => e.paymentStatus == PaymentStatus.paid)
            .fold(0, (s, e) => s + e.amountPaid.amount),
      ),
      bestMarathon: marathons.isEmpty
          ? null
          : marathons
                .map((e) => e.result!.finishTime)
                .reduce((a, b) => a <= b ? a : b),
    );
  }

  final int racesJoined;
  final double distanceRacedKm;
  final Money totalSpent;
  final Duration? bestMarathon;
}
