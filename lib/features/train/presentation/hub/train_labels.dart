import 'package:camrun/features/train/domain/entities/workout_log.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// El icono de un tipo de salida. El nombre no se pinta: el titulo de la fila
/// ya dice si fue carrera o sesion del plan.
extension WorkoutKindIcon on WorkoutKind {
  IconData get icon => switch (this) {
    WorkoutKind.freeRun => Icons.directions_run_rounded,
    WorkoutKind.planSession => Icons.event_available_rounded,
    WorkoutKind.goalDistance => Icons.straighten_rounded,
    WorkoutKind.goalTime => Icons.timer_outlined,
    WorkoutKind.race => Icons.emoji_events_rounded,
  };
}

/// Como se titula una salida en la lista.
///
/// Se calcula al pintar en vez de guardarse: el titulo depende de la hora de
/// inicio y del idioma activo, y un texto guardado en ingles seguiria en
/// ingles despues de cambiar el idioma de la app.
String runTitle(WorkoutLog run, AppLocalizations t) {
  if (run.kind == WorkoutKind.race) return t.trainHubRunRace;
  if (run.kind == WorkoutKind.planSession) return t.trainHubRunPlan;
  final hour = run.startedAt.hour;
  if (hour < 11) return t.trainHubRunMorning;
  if (hour < 14) return t.trainHubRunMidday;
  if (hour < 19) return t.trainHubRunAfternoon;
  if (hour < 22) return t.trainHubRunEvening;
  return t.trainHubRunNight;
}
