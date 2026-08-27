import 'package:camrun/core/db/app_database.dart';
import 'package:camrun/core/error/failure.dart';

/// Lectura offline-first: emite lo que hay en local **de inmediato** y despues
/// lo que traiga la red, ya guardado en cache.
///
/// La pantalla nunca se queda en blanco esperando al servidor. Y si no hay red
/// pero si cache, el fallo se traga: el usuario ve datos viejos, que es mejor
/// que un error. Sin cache no hay nada que ensenar y el fallo sube.
Stream<T> readThrough<T>({
  required AppDatabase db,
  required String key,
  required Future<Map<String, dynamic>> Function() fetch,
  required T Function(Map<String, dynamic>) parse,
}) async* {
  final local = await db.readDoc(key);
  if (local != null) yield parse(local);

  try {
    final fresco = await fetch();
    await db.writeDoc(key, fresco);
    yield parse(fresco);
  } on Failure {
    if (local == null) rethrow;
  }
}
