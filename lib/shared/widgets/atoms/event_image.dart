import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Afiche del evento. Si no hay imagen —o la descarga falla— pinta un degradado
/// de marca con el icono, no un trazado: el hueco tiene que leerse como "falta
/// el afiche", nunca como un mapa del recorrido.
class EventImage extends StatelessWidget {
  const EventImage({
    required this.imageUrl,
    this.icon = Icons.directions_run_rounded,
    this.fit = BoxFit.cover,
    this.blurBackdrop = false,
    this.background,
    super.key,
  });

  final String imageUrl;
  final IconData icon;

  /// `contain` cuando recortar se comeria parte del cartel; lo que sobre lo
  /// rellena el fondo (o [blurBackdrop]).
  final BoxFit fit;

  /// Rellena lo que deja `contain` con la misma imagen ampliada y difuminada:
  /// el afiche se ve entero y el hueco no queda con franjas de otro color. Es
  /// lo que evita recortar un cartel vertical en un hueco apaisado.
  final bool blurBackdrop;

  /// Fondo bajo la imagen. `null` = el degradado de marca.
  final Gradient? background;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: background ?? context.colors.routeGradient,
    ),
    child: imageUrl.isEmpty
        ? _placeholder(context)
        : kIsWeb
        // En web la descarga va por XHR y el servidor de imagenes no manda
        // cabeceras CORS: falla y solo quedaria el hueco. La etiqueta <img>
        // del navegador pinta igual sin pedir permiso, pero un filtro de Flutter
        // no la alcanza: en web no hay fondo difuminado.
        ? Image.network(
            imageUrl,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (context, _, _) => _placeholder(context),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final pixelRatio = MediaQuery.devicePixelRatioOf(context);
              // Se decodifica por el lado largo del hueco, no por el ancho:
              // con `cover` en un hueco alto la imagen se escala por el alto,
              // y decodificarla al ancho la dejaba borrosa.
              final lado = math.max(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final decodeWidth = lado.isFinite
                  ? (lado * pixelRatio).ceil().clamp(1, 4096)
                  : null;
              // Un solo proveedor para la imagen y su fondo: una descarga y una
              // decodificacion, y si falla fallan las dos juntas.
              final proveedor = ResizeImage.resizeIfNeeded(
                decodeWidth,
                null,
                CachedNetworkImageProvider(imageUrl),
              );
              final imagen = _image(context, proveedor, fit);
              if (!blurBackdrop) return imagen;
              return Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: _image(
                      context,
                      proveedor,
                      BoxFit.cover,
                      quiet: true,
                    ),
                  ),
                  ColoredBox(
                    color: context.colors.inkPill.withValues(alpha: 0.18),
                  ),
                  imagen,
                ],
              );
            },
          ),
  );

  /// [quiet] para la copia de fondo: sin icono propio mientras carga, que si
  /// no se veria doble bajo el de la imagen principal.
  Widget _image(
    BuildContext context,
    ImageProvider proveedor,
    BoxFit fit, {
    bool quiet = false,
  }) => Image(
    image: proveedor,
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    gaplessPlayback: true,
    frameBuilder: (context, child, frame, sincrono) => frame != null || sincrono
        ? child
        : (quiet ? const SizedBox.shrink() : _placeholder(context)),
    errorBuilder: (context, _, _) =>
        quiet ? const SizedBox.shrink() : _placeholder(context),
  );

  Widget _placeholder(BuildContext context) => Center(
    child: Icon(
      icon,
      size: 48,
      color: context.colors.onPrimary.withValues(alpha: 0.7),
    ),
  );
}
