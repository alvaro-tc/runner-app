import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Saca el **texto** del QR que hay en una foto. `null` si no se leyo ninguno.
///
/// El QR de cobro se guarda como texto y no como imagen: son unos bytes en vez
/// de cientos de KB, el corredor lo ve nitido a cualquier tamano y se le pinta
/// aunque este sin conexion —que es justo cuando saca el telefono para pagar—.
/// La foto que sube el organizador es solo el vehiculo, y se tira aqui mismo.
///
/// El decodificado va en un isolate: una foto de 12 MP tarda lo suficiente como
/// para congelar la pantalla si se hace en el hilo de la interfaz.
Future<String?> readQrFromImage(String path) async {
  final bytes = await File(path).readAsBytes();
  return Isolate.run(() => _leer(bytes));
}

String? _leer(Uint8List bytes) {
  final foto = img.decodeImage(bytes);
  if (foto == null) return null;

  final fuente = RGBLuminanceSource(
    foto.width,
    foto.height,
    foto.convert(numChannels: 4).toUint8List().buffer.asInt32List(),
  );
  // `tryHarder` porque esto casi nunca es un PNG limpio: es la foto de una
  // pantalla, torcida y con reflejos.
  final pistas = DecodeHints()..put(DecodeHintType.tryHarder);

  try {
    final leido = QRCodeReader().decode(
      BinaryBitmap(HybridBinarizer(fuente)),
      hints: pistas,
    );
    final texto = leido.text.trim();
    return texto.isEmpty ? null : texto;
  } on Exception {
    // No hay QR, esta borroso o la correccion de errores no dio: para quien
    // llama es el mismo caso, "no se pudo leer".
    return null;
  }
}
