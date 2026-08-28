import 'package:flutter/foundation.dart';

/// Base URL de la API.
///
/// Se pasa con `--dart-define=API_BASE_URL=...`. Sin definir cae al backend
/// local: el emulador de Android no ve `localhost` como la maquina anfitriona,
/// para el `10.0.2.2` es el alias del host.
String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;

  // Un APK compilado sin `--dart-define-from-file` se quedaba apuntando a
  // `10.0.2.2`, que solo existe dentro del emulador: en un telefono real no
  // conecta con nada y parece que "la app no funciona". Mejor que reviente al
  // arrancar, con el motivo escrito, que repartir un instalador mudo.
  if (kReleaseMode) {
    throw StateError(
      'API_BASE_URL no esta definido. Compila con '
      '`flutter build apk --release --dart-define-from-file=.env` (o `make apk`).',
    );
  }
  // `defaultTargetPlatform` y no `dart:io`: importar `Platform` rompe la
  // compilacion a web, donde esa biblioteca no existe.
  final esAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  return esAndroid
      ? 'http://10.0.2.2:3000/api/v1'
      : 'http://localhost:3000/api/v1';
}

/// Rutas que no llevan `Authorization` y a las que un 401 no dispara refresh.
const publicApiPaths = <String>[
  '/auth/login',
  '/auth/register',
  '/auth/refresh',
  '/auth/forgot-password',
  '/auth/reset-password',
  '/config/app',
  '/marathons',
  '/links/',
  // La ingesta lleva el `ingestToken` de la sesion en `Authorization`: ni se le
  // pone el JWT encima, ni un 401 suyo significa que la sesion del usuario
  // caduco —significa que el token de ingesta no vale—.
  '/tracking/',
];

/// Si [path] es una de las rutas publicas de [publicApiPaths].
///
/// Compara **por segmentos**, no por subcadena. Da lo mismo escrito asi y con
/// un `contains` hasta que aparece una ruta privada que contiene a una publica:
/// `/admin/marathons` contiene `/marathons`, y con `contains` el panel entero
/// de maratones salia sin `Authorization` y el servidor lo rechazaba con un 401
/// que, por creerse publico, ni siquiera disparaba el refresh.
///
/// Una entrada sin barra final cubre la ruta y lo que cuelgue de ella
/// (`/marathons` vale para `/marathons/upcoming`); con barra final, solo lo que
/// cuelga.
/// El `/api/v1` de [apiBaseUrl], resuelto una vez: esto se consulta en cada
/// peticion y la URL base no cambia en caliente.
final _prefijoBase = () {
  final p = Uri.parse(apiBaseUrl).path;
  return p == '/' ? '' : p;
}();

bool isPublicPath(String path) {
  var ruta = path;

  // Si llega una URL absoluta, el host sobra.
  final esquema = ruta.indexOf('://');
  if (esquema != -1) {
    final barra = ruta.indexOf('/', esquema + 3);
    ruta = barra == -1 ? '/' : ruta.substring(barra);
  }

  // La query no forma parte de la ruta.
  final query = ruta.indexOf('?');
  if (query != -1) ruta = ruta.substring(0, query);

  // `/api/v1/marathons` y `/marathons` son la misma ruta: el prefijo de la
  // base solo aparece cuando alguien pasa el path entero.
  if (_prefijoBase.isNotEmpty && ruta.startsWith(_prefijoBase)) {
    ruta = ruta.substring(_prefijoBase.length);
  }

  return publicApiPaths.any(
    (p) => p.endsWith('/')
        ? ruta.startsWith(p)
        : ruta == p || ruta.startsWith('$p/'),
  );
}

const connectTimeout = Duration(seconds: 10);
const receiveTimeout = Duration(seconds: 20);
