import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/app/dependencies.dart';
import 'package:paceup/core/error/failure.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/races/domain/entities/race_entry.dart';

class RacesNotifier extends AsyncNotifier<List<RaceEntry>> {
  @override
  Future<List<RaceEntry>> build() async =>
      (await ref.watch(raceRepositoryProvider).fetchEntries()).unwrap();

  /// Registers and refreshes the list so the new entry is visible immediately.
  Future<(RaceEntry?, Failure?)> register({
    required Marathon marathon,
    required Money amountPaid,
    required String paymentMethod,
  }) async {
    final result = await ref
        .read(raceRepositoryProvider)
        .register(
          marathon: marathon,
          amountPaid: amountPaid,
          paymentMethod: paymentMethod,
        );
    return result.fold((entry) {
      ref.invalidateSelf();
      return (entry, null);
    }, (failure) => (null, failure));
  }

  Future<String?> cancel(String entryId) async {
    final result = await ref.read(raceRepositoryProvider).cancel(entryId);
    return result.fold((_) {
      ref.invalidateSelf();
      return null;
    }, (failure) => failure.message);
  }
}

final racesProvider = AsyncNotifierProvider<RacesNotifier, List<RaceEntry>>(
  RacesNotifier.new,
);

final raceTotalsProvider = Provider<RaceTotals?>((ref) {
  final entries = ref.watch(racesProvider).value;
  return entries == null ? null : RaceTotals.from(entries);
});

final raceEntryProvider = Provider.family<RaceEntry?, String>((ref, id) {
  final entries = ref.watch(racesProvider).value ?? const [];
  for (final entry in entries) {
    if (entry.id == id) return entry;
  }
  return null;
});
