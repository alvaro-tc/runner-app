import 'dart:convert';
import 'dart:math';

import 'package:camrun/core/error/failure.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Lo que el servidor necesita de una autorizacion de Sign in with Apple.
@immutable
class AppleCredential {
  const AppleCredential({
    required this.identityToken,
    required this.authorizationCode,
    required this.rawNonce,
    required this.userIdentifier,
    this.givenName,
    this.familyName,
  });

  final String identityToken;

  /// Un solo uso, cinco minutos: el servidor lo canjea por el token que
  /// revoca al borrar la cuenta.
  final String authorizationCode;

  /// El nonce **sin** hashear. Apple recibio su SHA-256 y lo devuelve dentro
  /// del token; el servidor comprueba que coincidan.
  final String rawNonce;

  /// Identificador estable de la Apple Account para esta app. Es con lo que se
  /// consulta despues si la autorizacion sigue viva.
  final String userIdentifier;

  /// Solo la primera vez que alguien autoriza la app. Apple no los repite.
  final String? givenName;
  final String? familyName;
}

/// Sign in with Apple, reducido a lo que la app necesita: la credencial para el
/// servidor y saber si la autorizacion de este dispositivo sigue viva.
///
/// Solo en iOS (iPhone y iPad): ahi el flujo y el boton son los nativos del
/// sistema, como pide la guia de Apple. En Android no se ofrece.
class AppleSignInService {
  AppleSignInService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  /// La vista nativa del boton del sistema (`ASAuthorizationAppleIDButton`)
  /// que registra `AppDelegate.swift`. Su canal de pulsaciones es este mismo
  /// nombre seguido de `/<id de la vista>`.
  static const buttonViewType = 'camrun/apple_id_button';

  static const _usuario = 'auth.appleUserId';
  static const _nombre = 'auth.appleName.';

  final FlutterSecureStorage _storage;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// La hoja de Apple, con nombre y correo. `null` si el usuario la cerro:
  /// cancelar es una accion normal, no un error que pintar.
  Future<AppleCredential?> credential() async {
    final nonce = _nonce();
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // A Apple va el hash; el original solo lo conocen la app y el servidor.
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    final token = apple.identityToken;
    final usuario = apple.userIdentifier;
    if (token == null || token.isEmpty || usuario == null || usuario.isEmpty) {
      throw const UnexpectedFailure();
    }

    final nombre = await _nombreRecordado(
      usuario,
      apple.givenName,
      apple.familyName,
    );

    return AppleCredential(
      identityToken: token,
      authorizationCode: apple.authorizationCode,
      rawNonce: nonce,
      userIdentifier: usuario,
      givenName: nombre.$1,
      familyName: nombre.$2,
    );
  }

  /// El servidor ya creo o abrio la cuenta: se recuerda quien entro, para
  /// comprobar en cada arranque que la autorizacion sigue viva, y se suelta el
  /// nombre guardado, que ya esta a salvo en la cuenta.
  Future<void> remember(String userIdentifier) async {
    await _storage.write(key: _usuario, value: userIdentifier);
    await _storage.delete(key: '$_nombre$userIdentifier');
  }

  /// Al cerrar sesion o borrar la cuenta. No propaga nada: salir no puede
  /// quedarse a medias por el llavero.
  Future<void> forget() async {
    if (!isSupported) return;
    try {
      await _storage.delete(key: _usuario);
    } catch (_) {}
  }

  /// `true` si la sesion que se abrio con Apple en este dispositivo ya no
  /// vale: el usuario dejo de usar Sign in with Apple con la app, borro su
  /// Apple Account o el dispositivo tiene ahora otra. Es la comprobacion local
  /// y barata (`getCredentialState`) que recomienda Apple para atar la sesion.
  Future<bool> wasRevoked() async {
    if (!isSupported) return false;
    try {
      final usuario = await _storage.read(key: _usuario);
      if (usuario == null || usuario.isEmpty) return false;
      final estado = await SignInWithApple.getCredentialState(usuario);
      return estado != CredentialState.authorized;
    } catch (_) {
      // Sin respuesta no se echa a nadie: se vuelve a mirar al volver a la app.
      return false;
    }
  }

  /// Apple manda el nombre **una sola vez**. Si la peticion al servidor falla
  /// —sin red, en ese preciso momento—, el siguiente intento ya no lo trae.
  /// Por eso, como pide Apple, se guarda en cuanto llega y se reusa hasta que
  /// la cuenta exista.
  Future<(String?, String?)> _nombreRecordado(
    String usuario,
    String? nombre,
    String? apellido,
  ) async {
    final clave = '$_nombre$usuario';
    if ((nombre?.isNotEmpty ?? false) || (apellido?.isNotEmpty ?? false)) {
      await _storage.write(
        key: clave,
        value: jsonEncode({'given': nombre, 'family': apellido}),
      );
      return (nombre, apellido);
    }
    try {
      final guardado = await _storage.read(key: clave);
      if (guardado == null) return (null, null);
      final datos = jsonDecode(guardado) as Map<String, dynamic>;
      return (datos['given'] as String?, datos['family'] as String?);
    } catch (_) {
      return (null, null);
    }
  }

  /// 32 caracteres aleatorios de un generador criptografico.
  String _nonce([int largo = 32]) {
    const alfabeto =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final azar = Random.secure();
    return List.generate(
      largo,
      (_) => alfabeto[azar.nextInt(alfabeto.length)],
    ).join();
  }
}
