import 'dart:io';

import 'package:camrun/features/admin/data/qr_image_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Pinta un QR de verdad en un PNG, como el que el organizador fotografiaria.
File _png(String texto, Directory dir, {int escala = 8, int margen = 4}) {
  final codigo = QrImage(
    QrCode.fromData(data: texto, errorCorrectLevel: QrErrorCorrectLevel.M),
  );
  final lado = (codigo.moduleCount + margen * 2) * escala;
  final lienzo = img.Image(width: lado, height: lado)
    ..clear(img.ColorRgb8(255, 255, 255));

  for (var y = 0; y < codigo.moduleCount; y++) {
    for (var x = 0; x < codigo.moduleCount; x++) {
      if (!codigo.isDark(y, x)) continue;
      img.fillRect(
        lienzo,
        x1: (x + margen) * escala,
        y1: (y + margen) * escala,
        x2: (x + margen + 1) * escala - 1,
        y2: (y + margen + 1) * escala - 1,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }

  return File('${dir.path}/qr.png')..writeAsBytesSync(img.encodePng(lienzo));
}

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('qr_test'));
  tearDown(() => temp.deleteSync(recursive: true));

  test('de la foto del QR sale su texto, no la imagen', () async {
    const cobro =
        '00020101021226580014BR.GOV.BCB.PIX0136maraton@banco.bo5204000053039865802BO';

    expect(await readQrFromImage(_png(cobro, temp).path), cobro);
  });

  test('una imagen sin QR no devuelve nada', () async {
    final plano = img.Image(width: 120, height: 120)
      ..clear(img.ColorRgb8(200, 200, 200));
    final ruta = '${temp.path}/plano.png';
    File(ruta).writeAsBytesSync(img.encodePng(plano));

    expect(await readQrFromImage(ruta), isNull);
  });
}
