import 'package:camrun/core/theme/app_colors.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/atoms/event_image.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// El QR de cobro, dibujado desde su texto, con el logo de la carrera encima.
///
/// El violeta de marca va sobre blanco **siempre**, en los dos temas: un QR es
/// contraste antes que adorno, y el violeta claro del tema oscuro sobre fondo
/// oscuro no lo lee ningun escaner.
///
/// El logo va **encima** del codigo y no como `embeddedImage`: aquel se pinta
/// en el canvas y en web necesita CORS que `/uploads` no manda. Tapar el
/// centro es seguro porque la correccion de errores es la alta (~30 %) y el
/// logo ocupa bastante menos.
class BrandedQr extends StatelessWidget {
  const BrandedQr({required this.data, this.logoUrl, super.key});

  final String data;

  /// Logo del centro. Vacio o `null` = QR liso.
  final String? logoUrl;

  /// Lado del logo respecto al del QR. Mas grande empieza a no leerse.
  static const _logoFraccion = 0.24;

  @override
  Widget build(BuildContext context) {
    const tinta = LightTokens.primary;
    final logo = logoUrl ?? '';

    return LayoutBuilder(
      builder: (context, box) {
        final lado = box.biggest.shortestSide * _logoFraccion;
        return Stack(
          alignment: Alignment.center,
          children: [
            QrImageView(
              data: data,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              // Sin margen propio: el padding blanco de quien lo contiene ya
              // es la zona silenciosa que el escaner necesita.
              padding: EdgeInsets.zero,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: tinta,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: tinta,
              ),
            ),
            if (logo.isNotEmpty)
              Container(
                width: lado,
                height: lado,
                padding: EdgeInsets.all(lado * 0.08),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                  child: EventImage(
                    imageUrl: logo,
                    fit: BoxFit.contain,
                    icon: Icons.qr_code_2_rounded,
                    background: const LinearGradient(
                      colors: [Colors.white, Colors.white],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
