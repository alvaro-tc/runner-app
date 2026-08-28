import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paceup/core/db/app_database.dart';
import 'package:paceup/core/network/network_providers.dart';
import 'package:paceup/core/sync/sync_service.dart';

/// La base local. `driftDatabase` abre perezosamente, asi que no hace falta
/// resolverla en `bootstrap()` antes del primer frame.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

class SyncRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final syncRevisionProvider = NotifierProvider<SyncRevisionNotifier, int>(
  SyncRevisionNotifier.new,
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
    onChanged: () => ref.read(syncRevisionProvider.notifier).bump(),
  ),
);
