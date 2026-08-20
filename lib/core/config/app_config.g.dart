// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => _AppConfig(
  currency: json['currency'] as String,
  timezone: json['timezone'] as String,
  defaultLocale: json['defaultLocale'] as String,
  minAppVersion: json['minAppVersion'] as String,
  deepLinkScheme: json['deepLinkScheme'] as String,
  tracking: TrackingConfig.fromJson(json['tracking'] as Map<String, dynamic>),
  limits: AppLimits.fromJson(json['limits'] as Map<String, dynamic>),
  features: AppFeatures.fromJson(json['features'] as Map<String, dynamic>),
  serviceFee: json['serviceFee'] == null
      ? null
      : ServiceFeeInfo.fromJson(json['serviceFee'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AppConfigToJson(_AppConfig instance) =>
    <String, dynamic>{
      'currency': instance.currency,
      'timezone': instance.timezone,
      'defaultLocale': instance.defaultLocale,
      'minAppVersion': instance.minAppVersion,
      'deepLinkScheme': instance.deepLinkScheme,
      'tracking': instance.tracking,
      'limits': instance.limits,
      'features': instance.features,
      'serviceFee': instance.serviceFee,
    };

_ServiceFeeInfo _$ServiceFeeInfoFromJson(Map<String, dynamic> json) =>
    _ServiceFeeInfo(label: json['label'] as String);

Map<String, dynamic> _$ServiceFeeInfoToJson(_ServiceFeeInfo instance) =>
    <String, dynamic>{'label': instance.label};

_TrackingConfig _$TrackingConfigFromJson(Map<String, dynamic> json) =>
    _TrackingConfig(
      maxAccuracyMeters: (json['maxAccuracyMeters'] as num).toInt(),
      maxBatchesPerMinute: (json['maxBatchesPerMinute'] as num).toInt(),
      suggestedBatchSeconds: (json['suggestedBatchSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$TrackingConfigToJson(_TrackingConfig instance) =>
    <String, dynamic>{
      'maxAccuracyMeters': instance.maxAccuracyMeters,
      'maxBatchesPerMinute': instance.maxBatchesPerMinute,
      'suggestedBatchSeconds': instance.suggestedBatchSeconds,
    };

_AppLimits _$AppLimitsFromJson(Map<String, dynamic> json) => _AppLimits(
  avatarMaxBytes: (json['avatarMaxBytes'] as num).toInt(),
  requestsPerMinute: (json['requestsPerMinute'] as num).toInt(),
  shoeAlertThresholdMeters: (json['shoeAlertThresholdMeters'] as num).toInt(),
);

Map<String, dynamic> _$AppLimitsToJson(_AppLimits instance) =>
    <String, dynamic>{
      'avatarMaxBytes': instance.avatarMaxBytes,
      'requestsPerMinute': instance.requestsPerMinute,
      'shoeAlertThresholdMeters': instance.shoeAlertThresholdMeters,
    };

_AppFeatures _$AppFeaturesFromJson(Map<String, dynamic> json) => _AppFeatures(
  gpsSimulation: json['gpsSimulation'] as bool? ?? false,
  liveTracking: json['liveTracking'] as bool? ?? false,
  socialLogin: json['socialLogin'] as bool? ?? false,
);

Map<String, dynamic> _$AppFeaturesToJson(_AppFeatures instance) =>
    <String, dynamic>{
      'gpsSimulation': instance.gpsSimulation,
      'liveTracking': instance.liveTracking,
      'socialLogin': instance.socialLogin,
    };
