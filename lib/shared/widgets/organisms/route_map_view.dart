import 'dart:math' as math;

import 'package:camrun/core/extensions/context_x.dart';
import 'package:camrun/core/theme/app_spacing.dart';
import 'package:camrun/features/train/domain/entities/training_run.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// latlong2 exports its own generic `Path<T>`, which shadows dart:ui's.
import 'package:latlong2/latlong.dart' hide Path;

/// Una chinche suelta sobre el mapa.
@immutable
class MapPin {
  const MapPin({
    required this.lat,
    required this.lng,
    required this.child,
    this.size = 32,
  });

  final double lat;
  final double lng;
  final Widget child;
  final double size;
}

/// Every map in the app goes through this widget. Swapping flutter_map for
/// google_maps_flutter is a change inside this file only.
class RouteMapView extends StatefulWidget {
  const RouteMapView({
    required this.route,
    this.guideRoute = const [],
    this.follow,
    this.interactive = true,
    this.showStartFinish = true,
    this.markerEveryKm,
    this.userMarker,
    this.pins = const [],
    this.onTap,
    super.key,
  });

  final List<GeoPoint> route;

  /// Trazado de referencia, dibujado **debajo** del recorrido real y en gris.
  ///
  /// Es el circuito oficial de una carrera. Va aparte de [route] porque no es
  /// por donde se paso: es por donde habria que pasar, y pintarlo igual haria
  /// imposible ver si el corredor se salio.
  final List<GeoPoint> guideRoute;

  /// When set, the camera keeps this position centred (live session).
  final GeoPoint? follow;
  final bool interactive;
  final bool showStartFinish;

  /// Drops a numbered pin at each multiple of this distance.
  final int? markerEveryKm;
  final Widget? userMarker;

  /// Chinches sueltas encima del mapa: los corredores del mapa en vivo, los
  /// vertices del editor de recorrido. Van aparte de [route] porque no son un
  /// trazado —no hay orden entre ellas— y pintarlas como polilinea uniria por
  /// una raya a dos corredores que no tienen nada que ver.
  final List<MapPin> pins;

  /// Un toque sobre el mapa, con la coordenada. Solo el editor de recorrido lo
  /// usa; sin el, el mapa no reacciona a los toques.
  final void Function(double lat, double lng)? onTap;

  @override
  State<RouteMapView> createState() => RouteMapViewState();
}

class RouteMapViewState extends State<RouteMapView> {
  final MapController _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(RouteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final f = widget.follow;
    if (_ready && f != null && f != oldWidget.follow) {
      _controller.move(LatLng(f.lat, f.lng), _controller.camera.zoom);
    }
  }

  /// Re-centres on the live position, or refits the whole route.
  void recenter() {
    if (!_ready) return;
    final f = widget.follow;
    if (f != null) {
      _controller.move(LatLng(f.lat, f.lng), 16);
    } else {
      _fitRoute();
    }
  }

  void _fitRoute() {
    // Con guia, el encuadre la incluye: al empezar una carrera no hay recorrido
    // todavia y el mapa se abriria en ninguna parte.
    final puntos = [...widget.guideRoute, ...widget.route];
    if (puntos.length < 2) return;
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          for (final p in puntos) LatLng(p.lat, p.lng),
        ]),
        padding: const EdgeInsets.all(AppSpacing.xxl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final points = [for (final p in widget.route) LatLng(p.lat, p.lng)];
    final guide = [for (final p in widget.guideRoute) LatLng(p.lat, p.lng)];
    final encuadre = points.isEmpty ? guide : points;
    final center = widget.follow != null
        ? LatLng(widget.follow!.lat, widget.follow!.lng)
        : encuadre.isEmpty
        ? const LatLng(-6.2088, 106.8456)
        : encuadre[encuadre.length ~/ 2];

    return ColoredBox(
      color: c.primaryContainer,
      child: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: widget.follow != null ? 16 : 14,
          interactionOptions: InteractionOptions(
            flags: widget.interactive
                ? InteractiveFlag.all & ~InteractiveFlag.rotate
                : InteractiveFlag.none,
          ),
          onMapReady: () {
            _ready = true;
            if (widget.follow == null) _fitRoute();
          },
          onTap: widget.onTap == null
              ? null
              : (_, punto) => widget.onTap!(punto.latitude, punto.longitude),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.camrun.app',
            tileBuilder: c.isDark ? _darkenTile : null,
          ),
          // La guia primero: va por debajo del recorrido real.
          if (guide.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: guide,
                  strokeWidth: 5,
                  color: c.textSecondary.withValues(alpha: 0.45),
                ),
              ],
            ),
          if (points.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 6,
                  gradientColors: [c.primary, c.accentBlue],
                ),
              ],
            ),
          MarkerLayer(markers: _markers(points, c.isDark)),
        ],
      ),
    );
  }

  List<Marker> _markers(List<LatLng> points, bool isDark) {
    final c = context.colors;
    final markers = <Marker>[];

    // Con guia, la largada y la meta son las del circuito oficial: son puntos
    // fijos de la carrera, no los extremos de lo que se lleve corrido.
    final banderas = widget.guideRoute.isEmpty
        ? points
        : [for (final p in widget.guideRoute) LatLng(p.lat, p.lng)];

    if (widget.showStartFinish && banderas.length > 1) {
      markers
        ..add(_flag(banderas.first, Icons.flag_rounded, c.success))
        ..add(_flag(banderas.last, Icons.sports_score_rounded, c.error));
    }

    final every = widget.markerEveryKm;
    if (every != null && widget.route.length > 2) {
      var metres = 0.0;
      var next = every * 1000.0;
      for (var i = 1; i < widget.route.length; i++) {
        metres += widget.route[i - 1].distanceTo(widget.route[i]);
        if (metres >= next) {
          markers.add(_kmPin(points[i], '${next ~/ 1000}'));
          next += every * 1000;
        }
      }
    }

    for (final pin in widget.pins) {
      markers.add(
        Marker(
          point: LatLng(pin.lat, pin.lng),
          width: pin.size,
          height: pin.size,
          child: pin.child,
        ),
      );
    }

    final f = widget.follow;
    if (f != null) {
      markers.add(
        Marker(
          point: LatLng(f.lat, f.lng),
          width: 54,
          height: 54,
          child: widget.userMarker ?? const _UserDot(),
        ),
      );
    }
    return markers;
  }

  Marker _flag(LatLng at, IconData icon, Color color) => Marker(
    point: at,
    width: 32,
    height: 32,
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: context.colors.surface, width: 2),
      ),
      child: Icon(icon, size: 15, color: context.colors.onPrimary),
    ),
  );

  Marker _kmPin(LatLng at, String label) => Marker(
    point: at,
    width: 26,
    height: 26,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.surface,
        border: Border.all(color: context.colors.primary, width: 2),
      ),
      child: Text(
        label,
        style: context.text.labelSm.copyWith(
          color: context.colors.primary,
          fontSize: 9,
        ),
      ),
    ),
  );

  /// OSM ships light tiles only; invert + hue-rotate keeps dark mode readable.
  Widget _darkenTile(BuildContext context, Widget tile, TileImage image) =>
      ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -0.6,
          -0.2,
          -0.2,
          0,
          235,
          -0.2,
          -0.6,
          -0.2,
          0,
          235,
          -0.2,
          -0.2,
          -0.6,
          0,
          235,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: tile,
      );
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.primary,
        border: Border.all(color: c.surface, width: 4),
        boxShadow: c.floatingShadow,
      ),
      child: Icon(Icons.navigation_rounded, size: 20, color: c.onPrimary),
    );
  }
}

/// Non-interactive route thumbnail for history rows — no tiles, just the trace,
/// which keeps long lists cheap and works with no network.
class RouteThumbnail extends StatelessWidget {
  const RouteThumbnail({required this.route, this.size = 64, super.key});

  final List<GeoPoint> route;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _TracePainter(route: route, gradient: c.routeGradient),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({required this.route, required this.gradient});

  final List<GeoPoint> route;
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (route.length < 2) return;
    var minLat = route.first.lat, maxLat = route.first.lat;
    var minLng = route.first.lng, maxLng = route.first.lng;
    for (final p in route) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    final spanLat = math.max(maxLat - minLat, 1e-6);
    final spanLng = math.max(maxLng - minLng, 1e-6);
    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    final path = Path();
    for (var i = 0; i < route.length; i++) {
      final x = pad + (route[i].lng - minLng) / spanLng * w;
      final y = pad + (1 - (route[i].lat - minLat) / spanLat) * h;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = gradient.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_TracePainter old) => old.route != route;
}
