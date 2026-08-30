import 'dart:math';

import 'package:camrun/shared/map/tile_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tileOf da la tesela Web Mercator del punto', () {
    // Comprobado contra la tesela real: esta URL devuelve el centro de
    // Cochabamba, con la plaza y las calles del sitio.
    expect(tileOf(-17.3895, -66.1568, 16), const Point<int>(20724, 35983));
    // La Paz, el centro por defecto de la app.
    expect(tileOf(laPazCenter.lat, laPazCenter.lng, 14).x, 5091);
  });

  test('tileOf no se sale del mundo en los extremos', () {
    expect(tileOf(85.0, 180.0, 3).x, 7);
    expect(tileOf(-85.0, -180.0, 3), const Point<int>(0, 7));
  });

  test('la URL cambia de estilo con el tema', () {
    expect(tileUrl('16', '1', '2', dark: false), contains('World_Light_Gray'));
    expect(tileUrl('16', '1', '2', dark: true), contains('World_Dark_Gray'));
    // Esri sirve las teselas en z/y/x, al reves que el resto del mundo.
    expect(tileUrl('16', '1', '2', dark: true), endsWith('/16/2/1'));
  });
}
