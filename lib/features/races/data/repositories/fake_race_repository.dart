import 'dart:math' as math;

import 'package:paceup/core/constants/fake_data_seed.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/races/domain/entities/race_entry.dart';
import 'package:paceup/features/races/domain/repositories/race_repository.dart';

class FakeRaceRepository implements RaceRepository {
  FakeRaceRepository() : _entries = [...FakeDataSeed.raceEntries];

  final List<RaceEntry> _entries;
  final _rnd = math.Random();

  @override
  Future<Result<List<RaceEntry>>> fetchEntries() => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 480));
    return [..._entries]
      ..sort((a, b) => a.marathon.date.compareTo(b.marathon.date));
  });

  @override
  Future<Result<RaceEntry>> fetchById(String id) => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final match = _entries.where((e) => e.id == id);
    if (match.isEmpty) {
      throw const NotFoundFailure('We could not find that registration.');
    }
    return match.first;
  });

  @override
  Future<Result<RaceEntry>> register({
    required Marathon marathon,
    required Money amountPaid,
    required String paymentMethod,
  }) => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!marathon.status.acceptsEntries) {
      throw const ValidationFailure(
        'Entries for this event are closed. Join the waiting list instead.',
      );
    }
    final entry = RaceEntry(
      id: 'entry-${DateTime.now().microsecondsSinceEpoch}',
      marathon: marathon,
      registeredAt: DateTime.now(),
      amountPaid: amountPaid,
      paymentStatus: PaymentStatus.paid,
      bibNumber: (1000 + _rnd.nextInt(8999)).toString(),
      status: RaceEntryStatus.upcoming,
      paymentMethod: paymentMethod,
    );
    _entries.add(entry);
    return entry;
  });

  @override
  Future<Result<void>> cancel(String entryId) => guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index == -1) {
      throw const NotFoundFailure('That registration no longer exists.');
    }
    final old = _entries[index];
    _entries[index] = RaceEntry(
      id: old.id,
      marathon: old.marathon,
      registeredAt: old.registeredAt,
      amountPaid: old.amountPaid,
      paymentStatus: PaymentStatus.refunded,
      bibNumber: old.bibNumber,
      status: RaceEntryStatus.cancelled,
      paymentMethod: old.paymentMethod,
      result: old.result,
    );
  });
}
