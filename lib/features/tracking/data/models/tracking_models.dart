import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracking_models.freezed.dart';
part 'tracking_models.g.dart';

/// Lo que devuelve `POST /workouts/sessions`: la sesion abierta y el credencial
/// con el que se le mandan puntos.
@freezed
abstract class StartedSession with _$StartedSession {
  const factory StartedSession({
    required String sessionId,
    required String workoutId,
    required DateTime startedAt,

    /// Solo sirve para mandar posiciones a **esta** sesion y muere con ella.
    /// Por eso puede viajar mil veces por entrenamiento y el JWT no.
    required String ingestToken,
  }) = _StartedSession;

  /// La respuesta viene anidada (`session`, `workout`); esto la aplana.
  factory StartedSession.fromApi(Map<String, dynamic> json) {
    final sesion = json['session'] as Map<String, dynamic>;
    final workout = json['workout'] as Map<String, dynamic>;
    return StartedSession(
      sessionId: sesion['id'] as String,
      workoutId: workout['id'] as String,
      startedAt: DateTime.parse(sesion['startedAt'] as String),
      ingestToken: json['ingestToken'] as String,
    );
  }
}

/// Respuesta de la ingesta. `duplicated` no es un error: es el reintento
/// funcionando.
@freezed
abstract class IngestResult with _$IngestResult {
  const factory IngestResult({
    @Default(0) int accepted,
    @Default(0) int duplicated,
    @Default(0) int rejected,
  }) = _IngestResult;

  factory IngestResult.fromJson(Map<String, dynamic> json) =>
      _$IngestResultFromJson(json);
}
