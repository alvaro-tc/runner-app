import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Le pasa a [builder] el margen lateral que toca segun el ancho del hueco.
///
/// Para listas y scrolls: el margen va en su `padding` y no envolviendo el
/// scroll en una caja estrecha, asi en una tablet se puede arrastrar desde
/// cualquier punto de la pantalla y no solo desde la columna del centro.
class PageInsets extends StatelessWidget {
  const PageInsets({
    required this.builder,
    this.maxWidth = AppSizes.readableMaxWidth,
    super.key,
  });

  final double maxWidth;
  final Widget Function(BuildContext context, double inset) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) =>
        builder(context, AppLayout.inset(box.maxWidth, maxWidth: maxWidth)),
  );
}

/// La lista de una pantalla de una sola columna —ajustes, formularios, un
/// paso del alta—: el margen de siempre en telefono y, en una tablet,
/// centrada y con tope de ancho.
class PageListView extends StatelessWidget {
  const PageListView({
    required this.children,
    this.maxWidth = AppSizes.readableMaxWidth,
    this.top = AppSpacing.screenH,
    this.bottom = AppSpacing.screenH,
    this.physics,
    super.key,
  });

  final List<Widget> children;
  final double maxWidth;
  final double top;
  final double bottom;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) => PageInsets(
    maxWidth: maxWidth,
    builder: (context, inset) => ListView(
      physics: physics,
      padding: EdgeInsets.fromLTRB(inset, top, inset, bottom),
      children: children,
    ),
  );
}

/// Centra un bloque y le pone tope de ancho, sin estirarlo en alto. Para lo
/// que no es una lista: la botonera de una barra inferior, una columna dentro
/// de un `SingleChildScrollView`.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    required this.child,
    this.maxWidth = AppSizes.contentMaxWidth,
    super.key,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Rejilla de tarjetas: tantas columnas de al menos [minItemWidth] como
/// quepan, hasta [maxColumns]. Con una sola columna es una lista sin mas.
///
/// Filas y no `GridView`: las tarjetas de la app miden lo que mide su texto,
/// y una rejilla de alto fijo las cortaria con letra grande.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    this.minItemWidth = 320,
    this.maxColumns = 3,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
    this.equalHeight = false,
    super.key,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  /// Entre filas. Cero cuando cada tarjeta ya trae su margen inferior.
  final double runSpacing;

  /// Estira las tarjetas de una fila al alto de la mas alta. Solo para hijos
  /// que admiten medidas intrinsecas: nada con `LayoutBuilder` dentro.
  final bool equalHeight;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final columns = AppLayout.columns(
          box.maxWidth,
          minItemWidth: minItemWidth,
          maxColumns: maxColumns,
          spacing: spacing,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < children.length; start += columns) ...[
              if (start > 0) SizedBox(height: runSpacing),
              _row(start, columns),
            ],
          ],
        );
      },
    );
  }

  Widget _row(int start, int columns) {
    if (columns == 1) return children[start];
    final row = Row(
      crossAxisAlignment: equalHeight
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          // La ultima fila puede venir corta: los huecos vacios mantienen el
          // ancho de columna, si no la tarjeta suelta se estiraria entera.
          Expanded(
            child: start + i < children.length
                ? children[start + i]
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
    return equalHeight ? IntrinsicHeight(child: row) : row;
  }
}

/// Dos bloques: lado a lado cuando el hueco llega a [minWidth], uno encima del
/// otro si no. El orden de lectura es el mismo en los dos casos.
class AdaptiveSplit extends StatelessWidget {
  const AdaptiveSplit({
    required this.primary,
    required this.secondary,
    this.minWidth = 720,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
    this.spacing = AppSpacing.xl,
    this.stackedSpacing = AppSpacing.xl,
    super.key,
  });

  final Widget primary;
  final Widget secondary;
  final double minWidth;
  final int primaryFlex;
  final int secondaryFlex;

  /// Entre columnas.
  final double spacing;

  /// Entre bloques cuando van apilados.
  final double stackedSpacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => box.maxWidth >= minWidth
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: primaryFlex, child: primary),
              SizedBox(width: spacing),
              Expanded(flex: secondaryFlex, child: secondary),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              SizedBox(height: stackedSpacing),
              secondary,
            ],
          ),
  );
}
