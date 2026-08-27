import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Escrituras que salieron de la UI y todavia no llegaron al servidor.
///
/// La `Idempotency-Key` se guarda **en la fila**, no en memoria: su trabajo es
/// sobrevivir justo a lo que no controlamos —la conexion que se corta despues
/// de mandar el checkout pero antes de recibir la respuesta, o el usuario que
/// mata la app—. Si se pierde en ese hueco, el reintento es un segundo cobro.
class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get method => text()();
  TextColumn get path => text()();
  TextColumn get body => text().nullable()();
  TextColumn get idempotencyKey => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get lastError => text().nullable()();
}

/// Entrenamientos grabados sin red, a la espera de `POST /workouts/sync`.
///
/// Van en su propia tabla y no en la outbox porque el sync es por lotes y
/// resuelve **cada item por separado**: una fila de outbox por peticion no
/// sabria que hacer con un `rejected` en el sexto de cincuenta.
class PendingWorkouts extends Table {
  /// Es la proteccion real contra duplicados: unico tambien en el servidor.
  TextColumn get clientUuid => text()();

  /// El item completo tal como lo espera `/workouts/sync`, puntos incluidos.
  TextColumn get payload => text()();
  DateTimeColumn get startedAt => dateTime()();
  TextColumn get idempotencyKey => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get remoteId => text().nullable()();

  /// Con motivo, no se reintenta: el servidor ya dijo que no va a cambiar.
  TextColumn get rejectedReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clientUuid};
}

/// Cache de lectura: la respuesta cruda de un GET, por clave.
///
/// Una tabla generica en vez de una por entidad. Lo unico que se hace con
/// estas filas es devolverlas tal cual mientras la red responde; modelarlas
/// campo a campo seria mantener el esquema del backend por duplicado.
class CachedDocs extends Table {
  TextColumn get key => text()();
  TextColumn get json => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Puntos de GPS grabados, a la espera de `POST /tracking/sessions/:id/positions`.
///
/// **Se escribe aqui antes de intentar mandarlo.** Un entrenamiento que se
/// pierde no se puede volver a correr: la red es opcional, la fila no.
class PendingPositions extends Table {
  /// Lo que hace seguro reenviar un lote: el servidor ignora los repetidos.
  TextColumn get clientPointId => text()();
  TextColumn get sessionId => text()();

  /// El credencial de esa sesion, guardado con los puntos: la cola puede
  /// drenarse horas despues, con la app reabierta y el servicio ya muerto.
  TextColumn get ingestToken => text()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get altitude => real().nullable()();
  RealColumn get speed => real().nullable()();
  RealColumn get accuracy => real().nullable()();
  RealColumn get heading => real().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {clientPointId};
}

@DriftDatabase(
  tables: [OutboxEntries, PendingWorkouts, CachedDocs, PendingPositions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'camrun',
              // En web el wasm y el worker viven en `web/`; sin esto
              // `driftDatabase` lanza al construirse y no llega ni el primer
              // frame.
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(pendingPositions);
    },
  );

  // ─── Outbox ──────────────────────────────────────────────────────────────

  Future<int> enqueue({
    required String method,
    required String path,
    Map<String, Object?>? body,
    required String idempotencyKey,
    DateTime? now,
  }) {
    final ahora = now ?? DateTime.now();
    return into(outboxEntries).insert(
      OutboxEntriesCompanion.insert(
        method: method,
        path: path,
        body: Value(body == null ? null : jsonEncode(body)),
        idempotencyKey: idempotencyKey,
        createdAt: ahora,
        nextAttemptAt: ahora,
      ),
    );
  }

  /// Lo pendiente que ya toca reintentar, en el orden en que se encolo: una
  /// escritura posterior puede depender de otra anterior.
  Future<List<OutboxEntry>> dueOutbox(DateTime now) =>
      (select(outboxEntries)
            ..where((t) => t.nextAttemptAt.isSmallerOrEqualValue(now))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<void> deleteOutbox(int id) =>
      (delete(outboxEntries)..where((t) => t.id.equals(id))).go();

  /// Un intento mas y a esperar. El backoff vive en la fila, asi que sobrevive
  /// a que la app se cierre entre reintentos.
  Future<void> failOutbox(int id, String error, DateTime nextAttemptAt) =>
      customUpdate(
        'UPDATE outbox_entries SET attempts = attempts + 1, last_error = ?, '
        'next_attempt_at = ? WHERE id = ?',
        variables: [
          Variable<String>(error),
          Variable<DateTime>(nextAttemptAt),
          Variable<int>(id),
        ],
        updates: {outboxEntries},
      );

  // ─── Entrenamientos pendientes ───────────────────────────────────────────

  Future<void> queueWorkout({
    required String clientUuid,
    required Map<String, Object?> payload,
    required DateTime startedAt,
    required String idempotencyKey,
    DateTime? now,
  }) => into(pendingWorkouts).insertOnConflictUpdate(
    PendingWorkoutsCompanion.insert(
      clientUuid: clientUuid,
      payload: jsonEncode(payload),
      startedAt: startedAt,
      idempotencyKey: idempotencyKey,
      nextAttemptAt: now ?? DateTime.now(),
    ),
  );

  /// Los del proximo lote. Tope de 50: es el maximo que acepta el endpoint.
  Future<List<PendingWorkout>> dueWorkouts(DateTime now, {int limit = 50}) =>
      (select(pendingWorkouts)
            ..where(
              (t) =>
                  t.syncedAt.isNull() &
                  t.rejectedReason.isNull() &
                  t.nextAttemptAt.isSmallerOrEqualValue(now),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)])
            ..limit(limit))
          .get();

  Future<void> markWorkoutSynced(String clientUuid, String? remoteId) =>
      (update(
        pendingWorkouts,
      )..where((t) => t.clientUuid.equals(clientUuid))).write(
        PendingWorkoutsCompanion(
          syncedAt: Value(DateTime.now()),
          remoteId: Value(remoteId),
        ),
      );

  Future<void> markWorkoutRejected(String clientUuid, String? reason) =>
      (update(
        pendingWorkouts,
      )..where((t) => t.clientUuid.equals(clientUuid))).write(
        PendingWorkoutsCompanion(rejectedReason: Value(reason ?? 'rejected')),
      );

  Future<void> retryWorkoutsLater(
    Iterable<String> uuids,
    DateTime nextAttemptAt,
  ) {
    final huecos = uuids.map((_) => '?').join(',');
    return customUpdate(
      'UPDATE pending_workouts SET attempts = attempts + 1, '
      'next_attempt_at = ? WHERE client_uuid IN ($huecos)',
      variables: [
        Variable<DateTime>(nextAttemptAt),
        for (final u in uuids) Variable<String>(u),
      ],
      updates: {pendingWorkouts},
    );
  }

  // ─── Posiciones pendientes ───────────────────────────────────────────────

  /// Guarda el lote recien grabado. `insertOnConflictUpdate` para que un punto
  /// repetido por el propio GPS no reviente la grabacion entera.
  Future<void> queuePositions(Iterable<PendingPositionsCompanion> puntos) =>
      batch(
        (b) => b.insertAll(
          pendingPositions,
          puntos.toList(),
          mode: InsertMode.insertOrReplace,
        ),
      );

  /// El proximo lote a mandar, de **una sola sesion**: el endpoint es por
  /// sesion, y mezclar dos en un request no tendria a donde ir.
  Future<List<PendingPosition>> duePositions(
    DateTime now, {
    int limit = 300,
  }) async {
    final primera =
        await (select(pendingPositions)
              ..where((t) => t.nextAttemptAt.isSmallerOrEqualValue(now))
              ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (primera == null) return const [];

    return (select(pendingPositions)
          ..where(
            (t) =>
                t.sessionId.equals(primera.sessionId) &
                t.nextAttemptAt.isSmallerOrEqualValue(now),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)])
          ..limit(limit))
        .get();
  }

  /// Aceptado o duplicado da igual: el punto ya esta en el servidor, que es la
  /// fuente de verdad del recorrido. Guardarlo dos veces no sirve para nada.
  Future<void> deletePositions(Iterable<String> ids) =>
      (delete(pendingPositions)..where((t) => t.clientPointId.isIn(ids))).go();

  Future<void> retryPositionsLater(
    Iterable<String> ids,
    DateTime nextAttemptAt,
  ) {
    final huecos = ids.map((_) => '?').join(',');
    return customUpdate(
      'UPDATE pending_positions SET attempts = attempts + 1, '
      'next_attempt_at = ? WHERE client_point_id IN ($huecos)',
      variables: [
        Variable<DateTime>(nextAttemptAt),
        for (final id in ids) Variable<String>(id),
      ],
      updates: {pendingPositions},
    );
  }

  // ─── Cache de documentos ─────────────────────────────────────────────────

  Future<Map<String, dynamic>?> readDoc(String key) async {
    final fila = await (select(
      cachedDocs,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return fila == null ? null : jsonDecode(fila.json) as Map<String, dynamic>;
  }

  Future<void> writeDoc(String key, Map<String, dynamic> json) =>
      into(cachedDocs).insertOnConflictUpdate(
        CachedDocsCompanion.insert(
          key: key,
          json: jsonEncode(json),
          fetchedAt: DateTime.now(),
        ),
      );

  /// Todo lo local del usuario. Se llama al cerrar sesion: la cache de uno no
  /// puede quedar visible en la sesion de otro.
  Future<void> wipe() async {
    await delete(cachedDocs).go();
    await delete(outboxEntries).go();
    await delete(pendingWorkouts).go();
    await delete(pendingPositions).go();
  }
}
