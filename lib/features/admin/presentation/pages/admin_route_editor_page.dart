import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/layout/breakpoints.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter/material.dart';

/// Como se cierra el trazado que se marca.
enum RouteShape {
  /// Salida en el primer punto, meta en el ultimo.
  line,

  /// Se marca la ida; la vuelta es la misma linea al reves.
  outAndBack,

  /// Se marca la vuelta entera; el ultimo punto se une al primero, que es a la
  /// vez salida y meta.
  loop,
}

/// Lo que se guarda para los vertices marcados en cada forma.
///
/// Ida y vuelta y circular se guardan **expandidos** —la vuelta duplicada, el
/// cierre repetido— y no como una bandera: asi la distancia, el mapa del
/// corredor y los marcadores de kilometro salen bien sin que nadie mas tenga
/// que saber que esta ruta era especial.
List<GeoPoint> routeForShape(List<GeoPoint> puntos, RouteShape forma) {
  if (puntos.length < 2) return puntos;
  return switch (forma) {
    RouteShape.line => puntos,
    // El punto de giro no se repite: seria un tramo de distancia cero.
    RouteShape.outAndBack => [...puntos, ...puntos.reversed.skip(1)],
    RouteShape.loop => [...puntos, puntos.first],
  };
}

/// Marcar el recorrido tocando el mapa.
///
/// Es un editor de **vertices**, no de calles: cada toque agrega un punto y la
/// linea los une en orden.
///
/// ponytail: sin ajuste a calles. Si algun dia hace falta, el sitio es este y
/// lo que cambia es de donde sale [_puntos]; el resto de la pantalla no se
/// entera.
class AdminRouteEditorPage extends StatefulWidget {
  const AdminRouteEditorPage({required this.initial, super.key});

  /// El trazado que ya tenia la carrera. Se puede seguir editando encima.
  final List<GeoPoint> initial;

  @override
  State<AdminRouteEditorPage> createState() => _AdminRouteEditorPageState();
}

class _AdminRouteEditorPageState extends State<AdminRouteEditorPage> {
  // Un circuito guardado trae el cierre repetido: se quita para editar los
  // vertices, y se vuelve a poner al guardar.
  late final bool _eraCircular = isClosedLoop([
    for (final p in widget.initial) (lat: p.lat, lng: p.lng),
  ]);
  late RouteShape _forma = _eraCircular ? RouteShape.loop : RouteShape.line;
  late List<GeoPoint> _puntos = _eraCircular
      ? widget.initial.sublist(0, widget.initial.length - 1)
      : [...widget.initial];

  List<GeoPoint> get _trazado => routeForShape(_puntos, _forma);

  /// Un circuito con dos puntos es una ida y vuelta: hacen falta tres.
  int get _minimo => _forma == RouteShape.loop ? 3 : 2;

  double get _km {
    final ruta = _trazado;
    var metros = 0.0;
    for (var i = 1; i < ruta.length; i++) {
      metros += ruta[i - 1].distanceTo(ruta[i]);
    }
    return metros / 1000;
  }

  void _agregar(double lat, double lng) {
    setState(() {
      _puntos = [
        ..._puntos,
        GeoPoint(lat: lat, lng: lng, timestamp: DateTime(2000)),
      ];
    });
  }

  void _deshacer() {
    if (_puntos.isEmpty) return;
    setState(() => _puntos = _puntos.sublist(0, _puntos.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.l10n;
    final trazado = _trazado;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminRouteTitle),
        actions: [
          IconButton(
            onPressed: _puntos.isEmpty ? null : _deshacer,
            icon: const Icon(Icons.undo_rounded),
            tooltip: t.adminRouteUndo,
          ),
          IconButton(
            onPressed: _puntos.isEmpty
                ? null
                : () => setState(() => _puntos = const []),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: t.adminRouteClear,
          ),
        ],
      ),
      // Apaisada, los controles van a un costado: abajo dejarian el mapa en
      // una rendija justo cuando hay que tocar en el.
      body: LayoutBuilder(
        builder: (context, box) {
          final side = AppLayout.mapSidePanel(box.maxWidth, box.maxHeight);
          final map = RouteMapView(
            route: const [],
            guideRoute: trazado,
            onTap: _agregar,
            pins: [
              // El primero ya lo marca la bandera de salida en cuanto hay
              // linea; un punto encima la taparia.
              for (var i = trazado.length > 1 ? 1 : 0; i < _puntos.length; i++)
                MapPin(
                  lat: _puntos[i].lat,
                  lng: _puntos[i].lng,
                  size: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary,
                      border: Border.all(color: c.surface, width: 2),
                    ),
                  ),
                ),
            ],
          );
          final panel = Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: SafeArea(
              top: false,
              left: !side,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<RouteShape>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: RouteShape.line,
                        icon: const Icon(Icons.trending_flat_rounded),
                        label: Text(t.adminRouteModeLine),
                      ),
                      ButtonSegment(
                        value: RouteShape.outAndBack,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(t.adminRouteOutAndBack),
                      ),
                      ButtonSegment(
                        value: RouteShape.loop,
                        icon: const Icon(Icons.loop_rounded),
                        label: Text(t.adminRouteModeLoop),
                      ),
                    ],
                    selected: {_forma},
                    onSelectionChanged: (s) => setState(() => _forma = s.first),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // La pista cambia con la forma: es lo que explica que hacer
                  // en el mapa, y un cambio sin transicion pasa desapercibido.
                  AnimatedSwitcher(
                    duration: context.reduceMotion
                        ? Duration.zero
                        : AppDurations.base,
                    switchInCurve: AppDurations.curve,
                    child: Text(
                      switch (_forma) {
                        RouteShape.line => t.adminRouteLineHint,
                        RouteShape.outAndBack => t.adminRouteOutAndBackHint,
                        RouteShape.loop => t.adminRouteLoopHint,
                      },
                      key: ValueKey(_forma),
                      style: context.text.bodySm.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _puntos.isEmpty
                        ? t.adminRouteHint
                        : t.adminRoutePoints(_puntos.length, Fmt.distance(_km)),
                    style: context.text.labelSm.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  AppButton(
                    label: t.commonSave,
                    icon: Icons.check_rounded,
                    onPressed: _puntos.length < _minimo
                        ? null
                        : () => Navigator.of(context).pop(trazado),
                  ),
                ],
              ),
            ),
          );

          if (side) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: map),
                SizedBox(
                  width: AppSizes.sidePanelWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      border: Border(left: BorderSide(color: c.border)),
                    ),
                    child: SingleChildScrollView(child: panel),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: map),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: panel,
              ),
            ],
          );
        },
      ),
    );
  }
}
