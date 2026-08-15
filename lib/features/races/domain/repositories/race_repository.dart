import 'package:paceup/core/utils/result.dart';
import 'package:paceup/features/home/domain/entities/marathon.dart';
import 'package:paceup/features/races/domain/entities/race_entry.dart';

abstract interface class RaceRepository {
  Future<Result<List<RaceEntry>>> fetchEntries();

  Future<Result<RaceEntry>> fetchById(String id);

  /// Creates an entry from a completed registration flow and returns it with
  /// its generated bib number.
  Future<Result<RaceEntry>> register({
    required Marathon marathon,
    required Money amountPaid,
    required String paymentMethod,
  });

  Future<Result<void>> cancel(String entryId);
}
