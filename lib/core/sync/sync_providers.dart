import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/network/network_providers.dart';
import 'package:camrun/core/sync/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La base local. `driftDatabase` abre perezosamente, asi que no hace falta
/// resolverla en `bootstrap()` antes del primer frame.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(appDatabaseProvider), ref.watch(dioProvider)),
);
