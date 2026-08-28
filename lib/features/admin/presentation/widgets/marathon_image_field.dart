import 'package:cached_network_image/cached_network_image.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// En que punto de la subida esta el hueco de la imagen.
enum ImageSlotStatus { idle, uploading, failed }

/// Un hueco de imagen de la maraton: el afiche o el QR de cobro.
///
/// **Siempre pinta lo que hay en el servidor, nunca el archivo local.** Es la
/// razon de ser del widget: mostrar la foto recien elegida desde el disco
/// confirmaria que el telefono la leyo, que es justo lo que nadie duda. Lo que
/// hay que probar es que llego, se guardo y volvera a estar ahi manana, y eso
/// solo lo demuestra la URL que devuelve el servidor.
///
/// El widget no sube nada: avisa con [onPick] y se deja pintar segun [status].
/// Quien sube es la pantalla, que es la que tiene el id de la maraton.
class MarathonImageField extends StatelessWidget {
  const MarathonImageField({
    required this.imageUrl,
    required this.status,
    required this.onPick,
    required this.onRetry,
    required this.emptyLabel,
    required this.aspectRatio,
    this.emptyIcon = Icons.add_photo_alternate_outlined,
    this.onRemove,
    this.enabled = true,
    this.disabledHint,
    super.key,
  });

  /// URL del servidor. Vacia o `null` es "todavia no hay imagen".
  final String? imageUrl;

  final ImageSlotStatus status;

  /// La fuente ya elegida por el usuario. Nulo si cerro el selector.
  final ValueChanged<ImageSource> onPick;

  /// Reintenta con el **mismo** archivo: quien fallo subiendo una foto no
  /// quiere volver a buscarla en la galeria, quiere que se reintente.
  final VoidCallback onRetry;

  final VoidCallback? onRemove;

  final String emptyLabel;
  final IconData emptyIcon;

  /// 16/9 para el afiche, 1 para el QR.
  final double aspectRatio;

  /// En el alta no hay donde poner la imagen: la maraton todavia no tiene id.
  final bool enabled;
  final String? disabledHint;

  bool get _hasImage => (imageUrl ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Semantics(
      button: enabled,
      label: _hasImage ? t.adminImageChange : emptyLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Material(
                color: context.colors.surfaceElevated,
                child: InkWell(
                  onTap: enabled && status != ImageSlotStatus.uploading
                      ? () => _elegirFuente(context)
                      : null,
                  child: AnimatedSwitcher(
                    duration: AppDurations.base,
                    switchInCurve: AppDurations.curve,
                    child: _contenido(context),
                  ),
                ),
              ),
            ),
          ),
          if (status == ImageSlotStatus.failed) ...[
            const SizedBox(height: AppSpacing.sm),
            _AvisoDeFallo(onRetry: onRetry),
          ] else if (!enabled && disabledHint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              disabledHint!,
              style: context.text.bodySm.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contenido(BuildContext context) => switch (status) {
    ImageSlotStatus.uploading => _Subiendo(
      key: const ValueKey('subiendo'),
      debajo: _hasImage ? _Imagen(url: imageUrl!) : null,
    ),
    _ when _hasImage => _Imagen(
      // La clave lleva la URL: al subir una foto nueva el servidor devuelve
      // otra ruta, y sin esto el switcher creeria que es la misma imagen y no
      // haria la transicion.
      key: ValueKey(imageUrl),
      url: imageUrl!,
      overlay: enabled ? context.l10n.adminImageChange : null,
    ),
    _ => _Vacio(
      key: const ValueKey('vacio'),
      label: emptyLabel,
      icon: emptyIcon,
      enabled: enabled,
    ),
  };

  Future<void> _elegirFuente(BuildContext context) async {
    final t = context.l10n;
    final fuente = await showModalBottomSheet<_Accion>(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t.adminImageFromCamera),
              onTap: () => Navigator.of(hoja).pop(_Accion.camara),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.adminImageFromGallery),
              onTap: () => Navigator.of(hoja).pop(_Accion.galeria),
            ),
            if (_hasImage && onRemove != null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: context.colors.error,
                ),
                title: Text(
                  t.adminImageRemove,
                  style: TextStyle(color: context.colors.error),
                ),
                onTap: () => Navigator.of(hoja).pop(_Accion.quitar),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    switch (fuente) {
      case _Accion.camara:
        onPick(ImageSource.camera);
      case _Accion.galeria:
        onPick(ImageSource.gallery);
      case _Accion.quitar:
        onRemove?.call();
      case null:
        break;
    }
  }
}

enum _Accion { camara, galeria, quitar }

/// La imagen guardada, con la pista de que se puede cambiar.
class _Imagen extends StatelessWidget {
  const _Imagen({required this.url, this.overlay, super.key});

  final String url;
  final String? overlay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, _) =>
              ColoredBox(color: c.shimmerBase, child: const SizedBox.expand()),
          errorWidget: (context, _, _) => ColoredBox(
            color: c.surfaceElevated,
            child: Icon(Icons.broken_image_outlined, color: c.textSecondary),
          ),
        ),
        if (overlay != null) ...[
          // El degradado existe para que la pastilla se lea sobre cualquier
          // foto, clara u oscura.
          DecoratedBox(
            decoration: BoxDecoration(gradient: c.heroOverlay),
            child: const SizedBox.expand(),
          ),
          Positioned(
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: _Pastilla(icon: Icons.edit_outlined, label: overlay!),
          ),
        ],
      ],
    );
  }
}

/// El hueco sin imagen. El borde a trazos es lo que lo lee como "falta algo
/// aqui" en vez de como una tarjeta vacia mas.
class _Vacio extends StatelessWidget {
  const _Vacio({
    required this.label,
    required this.icon,
    required this.enabled,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tinte = enabled ? c.primary : c.textSecondary;

    return CustomPaint(
      painter: _BordeATrazos(color: c.border, radius: AppRadius.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tinte.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 22, color: tinte),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: context.text.labelSm.copyWith(color: tinte),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Durante la subida se deja ver la imagen anterior atenuada: el hueco no se
/// vacia, se ocupa, y asi no parece que se haya perdido lo que ya habia.
class _Subiendo extends StatelessWidget {
  const _Subiendo({this.debajo, super.key});

  final Widget? debajo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (debajo != null) Opacity(opacity: 0.35, child: debajo),
        ColoredBox(
          color: c.surfaceElevated.withValues(alpha: debajo == null ? 1 : 0.4),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.adminImageUploading,
                  style: context.text.labelSm.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// El fallo de subida vive pegado a la imagen, no en el banner de guardado:
/// son dos cosas que fallan por separado y arreglarlas es apretar botones
/// distintos.
class _AvisoDeFallo extends StatelessWidget {
  const _AvisoDeFallo({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: c.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.adminImageUploadFailed,
              style: context.text.bodySm.copyWith(color: c.error),
            ),
          ),
          AppButton(
            label: context.l10n.commonRetry,
            onPressed: onRetry,
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: c.inkPill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c.onInkPill),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(label, style: context.text.labelSm.copyWith(color: c.onInkPill)),
        ],
      ),
    );
  }
}

/// Rectangulo redondeado a trazos. Material no trae ninguno y el borde continuo
/// se confunde con el de las tarjetas, que no se pueden tocar.
class _BordeATrazos extends CustomPainter {
  const _BordeATrazos({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final contorno = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          Radius.circular(radius),
        ),
      );

    for (final tramo in contorno.computeMetrics()) {
      var d = 0.0;
      while (d < tramo.length) {
        final hasta = (d + 6).clamp(0.0, tramo.length);
        canvas.drawPath(tramo.extractPath(d, hasta), pincel);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_BordeATrazos old) =>
      old.color != color || old.radius != radius;
}
