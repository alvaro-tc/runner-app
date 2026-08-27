// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => _AuthUser(
  id: json['id'] as String,
  name: json['name'] as String,
  role: json['role'] as String,
  email: json['email'] as String?,
  ci: json['ci'] as String?,
  mustChangePassword: json['mustChangePassword'] as bool? ?? false,
  onboardingSeenAt: json['onboardingSeenAt'] == null
      ? null
      : DateTime.parse(json['onboardingSeenAt'] as String),
);

Map<String, dynamic> _$AuthUserToJson(_AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'role': instance.role,
  'email': instance.email,
  'ci': instance.ci,
  'mustChangePassword': instance.mustChangePassword,
  'onboardingSeenAt': instance.onboardingSeenAt?.toIso8601String(),
};

_AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => _AuthSession(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresIn: (json['expiresIn'] as num).toInt(),
  user: json['user'] == null
      ? null
      : AuthUser.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthSessionToJson(_AuthSession instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'user': instance.user,
    };

_DeviceSession _$DeviceSessionFromJson(Map<String, dynamic> json) =>
    _DeviceSession(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      current: json['current'] as bool? ?? false,
      deviceName: json['deviceName'] as String?,
      platform: json['platform'] as String?,
    );

Map<String, dynamic> _$DeviceSessionToJson(_DeviceSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'lastUsedAt': instance.lastUsedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'current': instance.current,
      'deviceName': instance.deviceName,
      'platform': instance.platform,
    };
