import 'package:camrun/core/error/failure.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Cliente OAuth **de tipo Web** de Google Cloud —nunca los de tipo Android—.
/// No es un secreto: viaja dentro del APK. Llega por
/// `--dart-define-from-file=.env`.
const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

/// El dialogo de Google, reducido a lo unico que le importa a la app: el
/// `idToken` que el backend verifica en `/auth/google`.
class GoogleSignInService {
  /// `initialize()` se llama **una vez** por proceso, no una por pulsacion.
  Future<void>? _listo;

  /// Un fallo de inicializacion no se cachea: el siguiente intento reintenta.
  Future<void> _init() async {
    try {
      await (_listo ??= GoogleSignIn.instance.initialize(
        // Android conserva su configuracion nativa; iOS usa su propio cliente.
        // Si se compila desde Xcode, el SDK puede leer GIDClientID del plist.
        clientId:
            !kIsWeb &&
                defaultTargetPlatform == TargetPlatform.iOS &&
                _iosClientId.isNotEmpty
            ? _iosClientId
            : null,
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      ));
    } catch (_) {
      _listo = null;
      rethrow;
    }
  }

  /// El `idToken`, o `null` si el usuario cerro el dialogo: cancelar es una
  /// accion normal, no un error que pintar.
  Future<String?> idToken() async {
    await _init();
    try {
      final cuenta = await GoogleSignIn.instance.authenticate();
      final token = cuenta.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const UnexpectedFailure();
      }
      return token;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// Sin esto la segunda vez entra sola con la cuenta anterior sin preguntar.
  ///
  /// No propaga nada: cerrar sesion en la app no puede quedarse a medias
  /// porque el SDK de Google no arranque.
  Future<void> signOut() async {
    try {
      await _init();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      _listo = null;
    }
  }
}
