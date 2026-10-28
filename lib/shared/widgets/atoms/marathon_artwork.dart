import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/features/home/domain/entities/marathon.dart';
import 'package:camrun/shared/widgets/atoms/event_image.dart';
import 'package:flutter/material.dart';

/// La imagen de una carrera en cualquier hueco, **sin recortar nunca**.
///
/// Mide el hueco y pide a [Marathon.artworkFor] la imagen de esa forma: en un
/// hueco alto el logo vertical, en uno apaisado el horizontal. La imagen va
/// entera, y lo que sobra lo llena una copia suya difuminada. Antes el afiche
/// iba con `cover` y un cartel vertical en una tarjeta ancha perdia arriba y
/// abajo justo el nombre y la fecha.
class MarathonArtwork extends StatelessWidget {
  const MarathonArtwork({
    required this.marathon,
    this.logoPadding = 0,
    this.pickFor,
    super.key,
  });

  final Marathon marathon;

  /// Aire alrededor de la imagen, como fraccion del lado corto del hueco.
  /// Cero por defecto: lo que se sube son artes completos y un marco blanco
  /// alrededor solo los achica.
  final double logoPadding;

  /// Elige la imagen para esta forma (ancho / alto) en vez de medir el hueco.
  /// Lo usa [MarathonArtworkHero]: durante el vuelo el hueco cambia de forma y,
  /// midiendo, la imagen saltaria del logo vertical al horizontal a la mitad.
  final double? pickFor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final medido = box.hasBoundedHeight && box.maxHeight > 0
          ? box.maxWidth / box.maxHeight
          : 1.0;
      final art = marathon.artworkFor(pickFor ?? medido);
      // Lo que se sube como "logo" suele ser un arte completo —un afiche, un
      // banner—, asi que va como el afiche: entero y a sangre cuando la forma
      // coincide, con su copia difuminada en lo que sobre. Bajo todo, el fondo
      // claro: un logo con transparencia se ve sobre blanco, no sobre morado.
      return Padding(
        padding: EdgeInsets.all(box.biggest.shortestSide * logoPadding),
        child: EventImage(
          imageUrl: art.url,
          fit: BoxFit.contain,
          blurBackdrop: true,
          background: art.isLogo ? context.colors.logoBackdrop : null,
        ),
      );
    },
  );
}

/// [MarathonArtwork] con su Hero: la imagen de la carrera viaja entre el
/// inicio, el detalle y las tarjetas.
///
/// Cada lado elige su imagen por su propia forma ([aspectRatio]) y en el vuelo
/// una se funde en la otra: el afiche vertical del inicio se convierte en el
/// banner horizontal del detalle sin un salto a medio camino.
class MarathonArtworkHero extends StatelessWidget {
  const MarathonArtworkHero({
    required this.marathon,
    required this.aspectRatio,
    this.radius = 0,
    this.logoPadding = 0,
    super.key,
  });

  final Marathon marathon;
  final double aspectRatio;
  final double radius;
  final double logoPadding;

  static Widget _fundido(
    BuildContext _,
    Animation<double> animation,
    HeroFlightDirection direccion,
    BuildContext desde,
    BuildContext hacia,
  ) {
    final origen = (desde.widget as Hero).child;
    final destino = (hacia.widget as Hero).child;
    return Stack(
      fit: StackFit.expand,
      children: [
        origen,
        FadeTransition(
          // Al volver la animacion de la ruta corre al reves: el destino
          // tiene que aparecer igual, de transparente a opaco.
          opacity: direccion == HeroFlightDirection.push
              ? animation
              : ReverseAnimation(animation),
          child: destino,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Hero(
    tag: 'marathon-${marathon.id}',
    flightShuttleBuilder: _fundido,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: MarathonArtwork(
        marathon: marathon,
        pickFor: aspectRatio,
        logoPadding: logoPadding,
      ),
    ),
  );
}
