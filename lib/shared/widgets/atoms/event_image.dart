import 'package:cached_network_image/cached_network_image.dart';
import 'package:camrun/core/extensions/context_x.dart';
import 'package:flutter/material.dart';

/// Afiche del evento. Si no hay imagen —o la descarga falla— pinta un degradado
/// de marca con el icono, no un trazado: el hueco tiene que leerse como "falta
/// el afiche", nunca como un mapa del recorrido.
class EventImage extends StatelessWidget {
  const EventImage({
    required this.imageUrl,
    this.icon = Icons.directions_run_rounded,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String imageUrl;
  final IconData icon;

  /// `contain` cuando el afiche es vertical y recortarlo se comeria la mitad
  /// del cartel; el degradado de atras rellena lo que sobre.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: context.colors.routeGradient),
    child: imageUrl.isEmpty
        ? _placeholder(context)
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, _) => _placeholder(context),
            errorWidget: (context, _, _) => _placeholder(context),
          ),
  );

  Widget _placeholder(BuildContext context) => Center(
    child: Icon(
      icon,
      size: 48,
      color: context.colors.onPrimary.withValues(alpha: 0.7),
    ),
  );
}
