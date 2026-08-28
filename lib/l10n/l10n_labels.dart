import 'package:camrun/core/error/failure.dart';
import 'package:camrun/core/services/location_service.dart';
import 'package:camrun/core/services/settings_provider.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/features/home/domain/entities/training_plan.dart';
import 'package:camrun/features/profile/domain/entities/user_profile.dart';
import 'package:camrun/features/races/domain/entities/race_entry.dart';
import 'package:camrun/features/races/domain/entities/registration.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/features/train/presentation/providers/history_provider.dart';
import 'package:camrun/l10n/gen/app_localizations.dart';

/// Etiquetas de los tipos del dominio.
///
/// El dominio guarda identificadores estables —no texto— para que un dato
/// grabado en un idioma no se quede en ese idioma para siempre. Aqui es donde
/// esos identificadores se convierten en copy, y por eso vive en la capa de
/// presentacion y no junto a las entidades.
extension SessionTypeL10n on SessionType {
  String label(AppLocalizations t) => switch (this) {
    SessionType.easy => t.sessionTypeEasy,
    SessionType.tempo => t.sessionTypeTempo,
    SessionType.intervals => t.sessionTypeIntervals,
    SessionType.recovery => t.sessionTypeRecovery,
    SessionType.long => t.sessionTypeLong,
    SessionType.rest => t.sessionTypeRest,
    SessionType.race => t.sessionTypeRace,
  };
}

extension PlannedSessionL10n on PlannedSession {
  /// `5 km · Rodaje suave`, o `Dia de descanso`.
  String title(AppLocalizations t) => type.isRest
      ? t.sessionRestDay
      : t.sessionTitle(targetDistanceKm.round(), type.label(t));
}

extension TrainingWeekL10n on TrainingWeek {
  String label(AppLocalizations t) => t.homeTrainingWeek(index);
}

extension RunTitleL10n on TrainingRun {
  /// El titulo se guarda como clave cuando lo genera la app, y como texto
  /// libre cuando viene del servidor: lo que no reconozcamos se pinta tal cual.
  String localizedTitle(AppLocalizations t) => switch (title) {
    RunTitleKey.morning => t.runTitleMorning,
    RunTitleKey.lunch => t.runTitleLunch,
    RunTitleKey.afternoon => t.runTitleAfternoon,
    RunTitleKey.evening => t.runTitleEvening,
    RunTitleKey.tempo => t.runTitleTempo,
    RunTitleKey.long => t.runTitleLong,
    RunTitleKey.trackSession => t.runTitleTrackSession,
    _ => title,
  };
}

extension RunFeelingL10n on RunFeeling {
  String label(AppLocalizations t) => switch (this) {
    RunFeeling.rough => t.feelingRough,
    RunFeeling.okay => t.feelingOkay,
    RunFeeling.good => t.feelingGood,
    RunFeeling.strong => t.feelingStrong,
  };
}

extension DateRangeFilterL10n on DateRangeFilter {
  String label(AppLocalizations t) => switch (this) {
    DateRangeFilter.all => t.filterAllTime,
    DateRangeFilter.last30 => t.filterLast30,
    DateRangeFilter.last90 => t.filterLast90,
  };
}

extension GenderL10n on Gender {
  String label(AppLocalizations t) => switch (this) {
    Gender.female => t.genderFemale,
    Gender.male => t.genderMale,
    Gender.other => t.genderOther,
    Gender.undisclosed => t.genderUndisclosed,
  };
}

extension HydrationHabitL10n on HydrationHabit {
  String label(AppLocalizations t) => switch (this) {
    HydrationHabit.low => t.profileHydrationLow,
    HydrationHabit.moderate => t.profileHydrationModerate,
    HydrationHabit.high => t.profileHydrationHigh,
  };
}

extension PaymentStatusL10n on PaymentStatus {
  String label(AppLocalizations t) => switch (this) {
    PaymentStatus.paid => t.paymentStatusPaid,
    PaymentStatus.pending => t.paymentStatusPending,
    PaymentStatus.failed => t.paymentStatusFailed,
    PaymentStatus.refunded => t.paymentStatusRefunded,
  };
}

extension RaceEntryStatusL10n on RaceEntryStatus {
  String label(AppLocalizations t) => switch (this) {
    RaceEntryStatus.upcoming => t.raceEntryStatusUpcoming,
    RaceEntryStatus.completed => t.raceEntryStatusCompleted,
    RaceEntryStatus.dnf => t.raceEntryStatusDnf,
    RaceEntryStatus.cancelled => t.raceEntryStatusCancelled,
  };
}

extension RegistrationStatusL10n on RegistrationStatus {
  String label(AppLocalizations t) => switch (this) {
    RegistrationStatus.open => t.registrationStatusOpen,
    RegistrationStatus.closingSoon => t.registrationStatusClosingSoon,
    RegistrationStatus.full => t.registrationStatusFull,
    RegistrationStatus.closed => t.registrationStatusClosed,
  };
}

extension RacePaymentMethodL10n on RacePaymentMethod {
  String label(AppLocalizations t) => switch (this) {
    RacePaymentMethod.card => t.paymentMethodCard,
    RacePaymentMethod.qr => t.paymentMethodQr,
    RacePaymentMethod.bankTransfer => t.paymentMethodBankTransfer,
    RacePaymentMethod.qrManual => t.paymentMethodQrManual,
  };
}

extension ThemeModeL10n on AppLanguage {
  String label(AppLocalizations t) => switch (this) {
    AppLanguage.system => t.languageSystem,
    AppLanguage.spanish => t.languageSpanish,
    AppLanguage.english => t.languageEnglish,
  };

  String detail(AppLocalizations t) => switch (this) {
    AppLanguage.system => t.languageSystemDetail,
    AppLanguage.spanish => t.languageSpanishDetail,
    AppLanguage.english => t.languageEnglishDetail,
  };
}

extension LocationPermissionOutcomeL10n on LocationPermissionOutcome {
  /// Vacio cuando el permiso esta concedido: no hay nada que explicar.
  String message(AppLocalizations t) => switch (this) {
    LocationPermissionOutcome.granted => '',
    LocationPermissionOutcome.denied => t.locationDenied,
    LocationPermissionOutcome.deniedForever => t.locationDeniedForever,
    LocationPermissionOutcome.backgroundDenied => t.locationBackgroundDenied,
    LocationPermissionOutcome.serviceDisabled => t.locationServiceDisabled,
  };
}

/// Mensaje para el usuario de cualquier cosa que llegue por un `AsyncValue`
/// en error.
///
/// Los fallos con codigo propio se traducen; los que traen texto del servidor
/// —`ApiFailure`, `ValidationFailure`— se pintan tal cual.
///
/// Ojo: hoy el backend responde **siempre en espanol**, sin mirar
/// `Accept-Language`. Con la app en ingles esos mensajes salen en espanol. Se
/// arregla del lado del servidor; aqui no hay nada que traducir sin inventarse
/// un catalogo paralelo al suyo.
extension FailureL10n on Object {
  String localized(AppLocalizations t) => switch (this) {
    NetworkFailure() => t.failureNetwork,
    CacheFailure() => t.failureCache,
    NotFoundFailure() => t.failureNotFound,
    PermissionFailure() => t.failurePermission,
    SessionExpiredFailure() => t.failureSessionExpired,
    UnexpectedFailure() => t.failureUnexpected,
    final Failure f => f.message,
    _ => t.failureUnexpected,
  };
}
