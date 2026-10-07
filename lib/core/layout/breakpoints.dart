import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:camrun/core/theme/app_spacing.dart';

/// Las clases de ventana de Material 3. Deciden la navegacion —barra abajo o
/// rail al costado— y cuantas columnas caben; nunca el tamano del texto.
///
/// Se clasifica por **ancho de ventana** y no por dispositivo: un iPad en
/// Split View puede ser tan estrecho como un telefono. Que el aparato sea
/// telefono o tablet solo decide si puede girar, ver `AppBreakpoints.isTablet`.
enum WindowClass {
  /// Telefono vertical, o una tablet partida a la mitad.
  compact,

  /// Tablet vertical, o una tablet apaisada partida en Split View.
  medium,

  /// Tablet apaisada.
  expanded,

  /// Tablet grande apaisada, escritorio.
  large;

  bool get isCompact => this == compact;

  bool isAtLeast(WindowClass other) => index >= other.index;
}

abstract final class AppBreakpoints {
  static const medium = 600.0;
  static const expanded = 840.0;
  static const large = 1200.0;

  /// Si el aparato es una tablet, por el lado corto de la **pantalla** en
  /// puntos —no de la ventana: un iPad en Split View sigue siendo una
  /// tablet—. El telefono mas grande no llega a 600; la tablet mas chica,
  /// si.
  static bool isTablet(Size screen) => screen.shortestSide >= medium;

  static WindowClass classify(double width) => switch (width) {
    < medium => WindowClass.compact,
    < expanded => WindowClass.medium,
    < large => WindowClass.expanded,
    _ => WindowClass.large,
  };
}

/// Cuentas de maquetacion que dependen del ancho disponible.
///
/// Reciben el ancho del **hueco** y no el de la pantalla: dentro del armazon
/// el rail se come su franja, y una pagina que midiera la pantalla entera
/// creeria tener mas sitio del que tiene.
abstract final class AppLayout {
  /// El margen lateral minimo: el de siempre en telefono, algo mas holgado en
  /// cuanto hay sitio para que el contenido no vaya pegado al borde.
  static double gutter(double width) => width < AppBreakpoints.medium
      ? AppSpacing.screenH
      : AppSpacing.screenHWide;

  /// Margen lateral para que el contenido quede centrado y no pase de
  /// [maxWidth]. En telefono coincide con [gutter].
  static double inset(double width, {required double maxWidth}) =>
      math.max(gutter(width), (width - maxWidth) / 2);

  /// Lo que sobra a cada lado cuando el contenido se queda en [maxWidth]; cero
  /// mientras quepa. Para filas que ya traen su propio margen por dentro.
  static double surplus(double width, {required double maxWidth}) =>
      math.max(0, (width - maxWidth) / 2);

  /// Si una pantalla de mapa lleva sus controles en una columna al costado
  /// en vez de debajo: con ancho de tablet, o en una ventana mas ancha que
  /// alta, donde un panel abajo dejaria el mapa en una rendija.
  static bool mapSidePanel(double width, double height) =>
      width >= AppBreakpoints.expanded ||
      (width >= AppBreakpoints.medium && width > height);

  /// Cuantas columnas de al menos [minItemWidth] caben en [width], separadas
  /// por [spacing], sin pasar de [maxColumns].
  static int columns(
    double width, {
    required double minItemWidth,
    int maxColumns = 3,
    double spacing = AppSpacing.md,
  }) => ((width + spacing) / (minItemWidth + spacing)).floor().clamp(
    1,
    maxColumns,
  );
}
