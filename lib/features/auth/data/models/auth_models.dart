import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// Usuario autenticado tal como lo devuelven login, registro y `/auth/me`.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String email,
    required String name,
    required String role,

    /// `null` = todavia no vio los slides. Vive en el backend ademas de en
    /// local, asi que sobrevive a una reinstalacion.
    DateTime? onboardingSeenAt,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}

/// Respuesta de `/auth/login`, `/auth/register` y `/auth/refresh`.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String accessToken,
    required String refreshToken,

    /// Segundos de vida del access token (900).
    required int expiresIn,
    AuthUser? user,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}

/// Una fila de `GET /auth/sessions`: un dispositivo con sesion abierta.
@freezed
abstract class DeviceSession with _$DeviceSession {
  const factory DeviceSession({
    required String id,
    required String deviceId,
    required DateTime lastUsedAt,
    required DateTime expiresAt,
    @Default(false) bool current,
    String? deviceName,
    String? platform,
  }) = _DeviceSession;

  factory DeviceSession.fromJson(Map<String, dynamic> json) =>
      _$DeviceSessionFromJson(json);
}
