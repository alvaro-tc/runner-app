import 'package:flutter/foundation.dart';

/// Base URL de la API.
///
/// Se pasa con `--dart-define=API_BASE_URL=...`. Sin definir cae al backend
/// local: el emulador de Android no ve `localhost` como la maquina anfitriona,
/// para el `10.0.2.2` es el alias del host.
String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
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

bool isPublicPath(String path) =>
    publicApiPaths.any((p) => path.startsWith(p) || path.contains(p));

const connectTimeout = Duration(seconds: 10);
const receiveTimeout = Duration(seconds: 20);
