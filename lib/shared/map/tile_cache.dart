import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

/// Esri Canvas: gratis y sin clave, manda CORS —tile.openstreetmap.org bloquea
/// a las apps— y tiene version clara y oscura con los nombres de las calles.
/// CARTO se cayo de la lista: desde 2025 estampa un "API KEY REQUIRED" encima
/// de cada tesela anonima.
///
/// Los argumentos son String y no int para que el mapa pueda pedir la plantilla
/// (`{z}/{y}/{x}`) por la misma puerta que la precarga pide teselas concretas:
/// una sola URL en todo el proyecto.
String tileUrl(String z, String x, String y, {required bool dark}) =>
    'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/'
    'World_${dark ? 'Dark' : 'Light'}_Gray_Base/MapServer/tile/$z/$y/$x';

/// Donde viven las teselas guardadas.
///
/// Se guardan en disco porque el mapa se queda en gris justo donde mas se corre
/// —cerros, afueras, tuneles—, y al volver sobre la misma ruta se descargaria
/// otra vez lo ya visto.
final tileCache = CacheManager(
  Config(
    'camrun_map_tiles',
    stalePeriod: const Duration(days: 60),
    // ponytail: tope por numero de teselas, no por MB, que es lo unico que
    // ofrece flutter_cache_manager. ~20 KB cada una: unos 60 MB.
    maxNrOfCacheObjects: 3000,
  ),
);

/// El [TileProvider] que sirve el mapa desde [tileCache].
class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      CachedNetworkImageProvider(
        getTileUrl(coordinates, options),
        headers: headers,
        cacheManager: tileCache,
      );
}

/// La tesela que cubre un punto en un nivel de zoom (esquema Web Mercator).
math.Point<int> tileOf(double lat, double lng, int zoom) {
  final n = 1 << zoom;
  final latRad = lat * math.pi / 180;
  final x = ((lng + 180) / 360 * n).floor();
  final y =
      ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
              2 *
              n)
          .floor();
  return math.Point(x.clamp(0, n - 1), y.clamp(0, n - 1));
}

/// La Paz y El Alto: la app es del CAM y sus maratones se corren aqui, asi que
/// esta es la ciudad que vale la pena tener guardada aunque nadie la haya
/// abierto todavia.
const laPazCenter = (lat: -16.4955, lng: -68.1336);
const _laPazBounds = (south: -16.58, west: -68.22, north: -16.46, east: -68.06);

/// Zooms de ciudad: ver el barrio y la calle. El 16, que es el de correr, se
/// deja para [precacheRoute]: la ciudad entera a ese nivel son ~14 MB de
/// teselas que en su mayoria nadie mira.
const _cityZooms = [13, 14, 15];
const _routeZooms = [14, 15, 16];

bool _laPazDone = false;

/// Baja el mapa de La Paz de fondo, una vez por arranque.
Future<void> precacheLaPaz({required bool dark}) async {
  if (_laPazDone) return;
  _laPazDone = true;
  await _download(_cityTiles(), dark: dark);
}

/// Baja el mapa alrededor de un recorrido, para que el dia de la carrera se vea
/// aunque se llegue a la largada sin datos.
///
/// Solo las teselas por las que pasa el trazado y sus vecinas: el rectangulo
/// que lo contiene traeria media ciudad para un circuito que ocupa una avenida.
Future<void> precacheRoute(
  List<({double lat, double lng})> route, {
  required bool dark,
}) async {
  if (route.isEmpty) return;
  final tiles = <(int, int, int)>{};
  for (final z in _routeZooms) {
    for (final p in route) {
      final t = tileOf(p.lat, p.lng, z);
      // Las vecinas tambien: al mover el mapa un dedo se sale de la tesela.
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          tiles.add((z, t.x + dx, t.y + dy));
        }
      }
    }
  }
  await _download(tiles, dark: dark);
}

Set<(int, int, int)> _cityTiles() {
  final tiles = <(int, int, int)>{};
  for (final z in _cityZooms) {
    final a = tileOf(_laPazBounds.north, _laPazBounds.west, z);
    final b = tileOf(_laPazBounds.south, _laPazBounds.east, z);
    for (var x = a.x; x <= b.x; x++) {
      for (var y = a.y; y <= b.y; y++) {
        tiles.add((z, x, y));
      }
    }
  }
  return tiles;
}

/// De ocho en ocho: en fila seria eterno y todas a la vez ahogaria la conexion
/// del movil justo mientras se corre.
Future<void> _download(Set<(int, int, int)> tiles, {required bool dark}) async {
  if (kIsWeb) return; // Sin disco donde guardarlas; el navegador ya cachea.
  final pending = tiles.toList();
  for (var i = 0; i < pending.length; i += 8) {
    await Future.wait([
      for (final (z, x, y) in pending.skip(i).take(8))
        _one(tileUrl('$z', '$x', '$y', dark: dark)),
    ]);
  }
}

Future<void> _one(String url) async {
  try {
    await tileCache.downloadFile(url);
  } on Object {
    // Sin cobertura o con la tesela caida no pasa nada: se pedira sola cuando
    // el mapa la necesite.
  }
}
