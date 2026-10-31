import 'package:camrun/app/dependencies.dart';
import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/sync/sync_providers.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryNotifier extends AsyncNotifier<List<TrainingRun>> {
  @override
  Future<List<TrainingRun>> build() async =>
      (await ref.watch(trainingRepositoryProvider).fetchHistory()).unwrap();

  /// Devuelve el fallo, no su mensaje: el texto se resuelve en la UI con el
  /// idioma activo.
  Future<Failure?> save(TrainingRun run) async {
    final result = await ref.read(trainingRepositoryProvider).save(run);
    return result.fold((_) {
      ref.invalidateSelf();
      return null;
    }, (failure) => failure);
  }

  Future<Failure?> delete(String id) async {
    final result = await ref.read(trainingRepositoryProvider).delete(id);
    return result.fold((_) {
      ref.invalidateSelf();
      return null;
    }, (failure) => failure);
  }

  Future<void> retrySync(TrainingRun run) async {
    final clientUuid = run.clientUuid;
    if (clientUuid == null) return;
    await ref.read(appDatabaseProvider).retryRejectedWorkout(clientUuid);
    ref.invalidate(trainingSyncStatusProvider(run.id));
    await ref.read(syncServiceProvider).drain();
  }

  Future<void> discardSync(TrainingRun run) async {
    final clientUuid = run.clientUuid;
    if (clientUuid == null) return;
    await ref.read(appDatabaseProvider).deletePendingWorkout(clientUuid);
    await ref.read(trainingRepositoryProvider).delete(run.id);
    ref.invalidateSelf();
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<TrainingRun>>(
      HistoryNotifier.new,
    );

@immutable
class TrainingSyncStatusInfo {
  const TrainingSyncStatusInfo({
    required this.status,
    this.reason,
    this.clientUuid,
  });

  final TrainingSyncStatus status;
  final String? reason;
  final String? clientUuid;
}

final trainingSyncStatusProvider = FutureProvider.autoDispose
    .family<TrainingSyncStatusInfo, String>((ref, runId) async {
      ref.watch(syncRevisionProvider);
      final run = ref.watch(runProvider(runId));
      final clientUuid = run?.clientUuid;
      if (clientUuid == null) {
        return const TrainingSyncStatusInfo(status: TrainingSyncStatus.synced);
      }

      final pending = await ref
          .read(appDatabaseProvider)
          .pendingWorkout(clientUuid);
      if (pending == null || pending.syncedAt != null) {
        return TrainingSyncStatusInfo(
          status: TrainingSyncStatus.synced,
          clientUuid: clientUuid,
        );
      }
      if (pending.rejectedReason != null) {
        return TrainingSyncStatusInfo(
          status: TrainingSyncStatus.rejected,
          reason: pending.rejectedReason,
          clientUuid: clientUuid,
        );
      }
      return TrainingSyncStatusInfo(
        status: TrainingSyncStatus.pending,
        clientUuid: clientUuid,
      );
    });

final runProvider = Provider.autoDispose.family<TrainingRun?, String>((
  ref,
  id,
) {
  final runs = ref.watch(historyProvider).value ?? const [];
  for (final run in runs) {
    if (run.id == id) return run;
  }
  return null;
});
