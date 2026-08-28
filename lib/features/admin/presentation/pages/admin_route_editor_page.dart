import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/formatters/formatters.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:camrun/shared/widgets/atoms/app_button.dart';
import 'package:camrun/shared/widgets/organisms/route_map_view.dart';
import 'package:flutter/material.dart';

/// Marcar el recorrido tocando el mapa.
///
/// Es un editor de **vertices**, no de calles: cada toque agrega un punto y la
/// linea los une en orden. No sigue el trazado de la via porque eso necesita un
/// servicio de rutas —una dependencia, una clave de API y una tarifa— para algo
/// que en una carrera se resuelve poniendo un punto en cada esquina.
///
/// ponytail: sin ajuste a calles. Si algun dia hace falta, el sitio es este y
/// lo que cambia es de donde sale [_puntos]; el resto de la pantalla no se
/// entera.
class AdminRouteEditorPage extends StatefulWidget {
  const AdminRouteEditorPage({required this.initial, super.key});

  /// El trazado que ya tenia la maraton. Se puede seguir editando encima.
  final List<GeoPoint> initial;

  @override
  State<AdminRouteEditorPage> createState() => _AdminRouteEditorPageState();
}

class _AdminRouteEditorPageState extends State<AdminRouteEditorPage> {
  late List<GeoPoint> _puntos = [...widget.initial];

  /// Ida y vuelta por el mismo sitio.
  ///
  /// Es el caso de casi cualquier carrera en avenida recta: se marca solo la
  /// ida y la vuelta es la misma linea al reves. Se guarda **duplicado** y no
  /// como una bandera porque asi la distancia, el mapa del corredor y los
  /// marcadores de kilometro salen bien sin que nadie mas tenga que saber que
  /// esta ruta era especial.
  bool _idaYVuelta = false;

  /// Lo que se guarda: la ida, mas la vuelta si toca. El punto de giro no se
  /// repite —seria un punto a distancia cero— asi que la vuelta empieza en el
  /// penultimo.
  List<GeoPoint> get _trazado {
    if (!_idaYVuelta || _puntos.length < 2) return _puntos;
    return [..._puntos, ..._puntos.reversed.skip(1)];
  }

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
      body: Column(
        children: [
          Expanded(
            child: RouteMapView(
              route: const [],
              guideRoute: trazado,
              onTap: _agregar,
              // Sin el punto de giro marcado, una ida y vuelta se ve como una
              // sola linea y no hay forma de saber donde se da media vuelta.
              pins: [
                for (var i = 0; i < _puntos.length; i++)
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
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _puntos.isEmpty
                        ? t.adminRouteHint
                        : t.adminRoutePoints(_puntos.length, Fmt.distance(_km)),
                    style: context.text.bodySm.copyWith(color: c.textSecondary),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _idaYVuelta,
                    onChanged: (v) => setState(() => _idaYVuelta = v),
                    title: Text(
                      t.adminRouteOutAndBack,
                      style: context.text.bodyMd,
                    ),
                    subtitle: Text(
                      t.adminRouteOutAndBackHint,
                      style: context.text.bodySm.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: t.commonSave,
                    icon: Icons.check_rounded,
                    // Un punto suelto no es un recorrido: sin dos, el mapa del
                    // corredor no tiene ninguna linea que seguir.
                    onPressed: _puntos.length < 2
                        ? null
                        : () => Navigator.of(context).pop(trazado),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
