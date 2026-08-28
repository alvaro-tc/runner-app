import 'package:camrun/l10n/gen/app_localizations.dart';

/// Client-side form checks. Messages are written to be actionable, not just
/// "invalid".
///
/// Reciben `AppLocalizations` en vez de devolver texto fijo: el mensaje sale
/// del ARB del idioma activo, y los campos concretos (nombre, ciudad, peso,
/// altura) tienen clave propia porque en espanol el articulo y el genero no se
/// pueden interpolar de forma generica.
abstract final class Validators {
  static final _email = RegExp(r'^[\w.!#$%&*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(AppLocalizations t, String value) {
    if (value.trim().isEmpty) return t.validationEmailEmpty;
    if (!_email.hasMatch(value.trim())) return t.validationEmailInvalid;
    return null;
  }

  /// Sign-in accepts either a CI or an email, so only emptiness is fatal.
  static String? identifier(AppLocalizations t, String value) =>
      value.trim().isEmpty ? t.validationIdentifierEmpty : null;

  /// Bolivian CI: digits, optionally followed by the issuing-department code.
  ///
  /// Mirrors the server's rule instead of guessing a laxer one — a client check
  /// that lets through what the server rejects is worse than no check, because
  /// the user finds out one screen later.
  static final _ci = RegExp(r'^[0-9]{4,12}[A-Z]{0,3}$');

  static String? ci(AppLocalizations t, String value) {
    final limpio = value.toUpperCase().replaceAll(RegExp(r'[\s.\-_]'), '');

    if (limpio.isEmpty) return t.validationIdEmpty;
    if (!_ci.hasMatch(limpio)) return t.validationIdInvalid;
    return null;
  }

  static String? password(AppLocalizations t, String value) {
    if (value.isEmpty) return t.validationPasswordEmpty;
    if (value.length < 8) return t.validationPasswordTooShort;
    return null;
  }

  static String? confirmPassword(
    AppLocalizations t,
    String value,
    String original,
  ) {
    if (value.isEmpty) return t.validationConfirmEmpty;
    if (value != original) return t.validationConfirmMismatch;
    return null;
  }

  /// Campo obligatorio cualquiera: el mensaje ya viene redactado por quien
  /// llama, que es el unico que sabe de que campo se trata.
  static String? required(String value, String message) =>
      value.trim().isEmpty ? message : null;

  /// [notANumber] y [notPositive] igual: dos redacciones por campo.
  static String? positiveNumber(
    String value, {
    required String notANumber,
    required String notPositive,
  }) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return notANumber;
    if (parsed <= 0) return notPositive;
    return null;
  }
}
