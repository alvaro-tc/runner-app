/// Client-side form checks. Messages are written to be actionable, not just
/// "invalid".
abstract final class Validators {
  static final _email = RegExp(r'^[\w.!#$%&*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(String value) {
    if (value.trim().isEmpty) return 'Enter the email you signed up with.';
    if (!_email.hasMatch(value.trim())) {
      return 'That does not look like an email address.';
    }
    return null;
  }

  /// Sign-in accepts either a username or an email, so only emptiness is fatal.
  static String? identifier(String value) =>
      value.trim().isEmpty ? 'Enter your username or email.' : null;

  static String? password(String value) {
    if (value.isEmpty) return 'Enter your password.';
    if (value.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  static String? confirmPassword(String value, String original) {
    if (value.isEmpty) return 'Repeat your password.';
    if (value != original) return 'The two passwords do not match.';
    return null;
  }

  static String? required(String value, String field) =>
      value.trim().isEmpty ? 'Enter your $field.' : null;

  static String? positiveNumber(String value, String field) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Enter $field as a number.';
    if (parsed <= 0) return '$field has to be greater than zero.';
    return null;
  }
}
