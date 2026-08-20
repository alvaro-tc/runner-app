import 'dart:math';

/// UUID v4 con `Random.secure`. Una dependencia menos que `package:uuid` para
/// las cuatro lineas que hacen falta.
///
/// Se usa para el `deviceId`, el `clientUuid` de cada entrenamiento y las
/// `Idempotency-Key`.
String uuidV4() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
