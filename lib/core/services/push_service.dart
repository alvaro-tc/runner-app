import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Config del proyecto de Firebase. No son secretos —viajan dentro del APK—, y
// van por `--dart-define-from-file=.env` en vez de `google-services.json` para
// que un clon sin Firebase siga compilando: sin ellas, el push se apaga.
const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

/// El timbre del telefono con la app cerrada: FCM entrega y Android pinta la
/// notificacion sin despertar a Flutter. Con la app abierta ya avisa el socket.
///
/// ponytail: solo Android. iOS pide la clave APNs en Firebase y el capability
/// de push en Xcode; se enciende aqui quitando el filtro de plataforma.
class PushService {
  static bool get _enabled => Firebase.apps.isNotEmpty;

  /// En `bootstrap()`. Un Firebase mal configurado no puede tumbar el arranque:
  /// la bandeja sigue funcionando por el socket y el sondeo.
  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_projectId.isEmpty) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _senderId,
          projectId: _projectId,
        ),
      );
    } catch (e) {
      debugPrint('[Push] Firebase no arranca: $e');
    }
  }

  /// Pide el permiso (Android 13+) y devuelve el token, o `null` si no hay
  /// Firebase o el usuario lo nego.
  Future<String?> token() async {
    if (!_enabled) return null;
    try {
      final ajustes = await FirebaseMessaging.instance.requestPermission();
      if (ajustes.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[Push] sin token: $e');
      return null;
    }
  }

  Stream<String> get tokenRefresh => _enabled
      ? FirebaseMessaging.instance.onTokenRefresh
      : const Stream.empty();

  /// Llego un push con la app en primer plano: Android no lo pinta.
  Stream<void> get foreground =>
      _enabled ? FirebaseMessaging.onMessage : const Stream.empty();

  /// El usuario toco la notificacion con la app en segundo plano.
  Stream<void> get opened =>
      _enabled ? FirebaseMessaging.onMessageOpenedApp : const Stream.empty();

  /// La app arranco desde cero por tocar una notificacion. Una sola vez.
  Future<bool> launchedFromPush() async =>
      _enabled && await FirebaseMessaging.instance.getInitialMessage() != null;

  /// Al cerrar sesion: el token muere y FCM deja de entregar a este telefono;
  /// el backend lo borra del `Device` en el siguiente envio.
  Future<void> forget() async {
    if (!_enabled) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService());
