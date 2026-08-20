import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

/// `GET /config/app`: lo que el cliente no debe hardcodear. Se pide una vez al
/// arrancar, antes de pintar nada. Un valor copiado dentro del APK es una
/// mentira el dia que alguien lo cambie desde el panel.
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    required String currency,
    required String timezone,
    required String defaultLocale,

    /// Contrato: por debajo de esta version la API no garantiza nada.
    required String minAppVersion,
    required String deepLinkScheme,
    required TrackingConfig tracking,
    required AppLimits limits,
    required AppFeatures features,

    /// `null` cuando el cargo por servicio esta apagado — ausencia, no
    /// `enabled: false`. Trae solo la etiqueta: el monto lo calcula
    /// `/pricing/quote`, nunca el movil.
    ServiceFeeInfo? serviceFee,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}

@freezed
abstract class ServiceFeeInfo with _$ServiceFeeInfo {
  const factory ServiceFeeInfo({required String label}) = _ServiceFeeInfo;

  factory ServiceFeeInfo.fromJson(Map<String, dynamic> json) =>
      _$ServiceFeeInfoFromJson(json);
}

@freezed
abstract class TrackingConfig with _$TrackingConfig {
  const factory TrackingConfig({
    required int maxAccuracyMeters,
    required int maxBatchesPerMinute,
    required int suggestedBatchSeconds,
  }) = _TrackingConfig;

  factory TrackingConfig.fromJson(Map<String, dynamic> json) =>
      _$TrackingConfigFromJson(json);
}

@freezed
abstract class AppLimits with _$AppLimits {
  const factory AppLimits({
    required int avatarMaxBytes,
    required int requestsPerMinute,
    required int shoeAlertThresholdMeters,
  }) = _AppLimits;

  factory AppLimits.fromJson(Map<String, dynamic> json) =>
      _$AppLimitsFromJson(json);
}

@freezed
abstract class AppFeatures with _$AppFeatures {
  const factory AppFeatures({
    @Default(false) bool gpsSimulation,
    @Default(false) bool liveTracking,
    @Default(false) bool socialLogin,
  }) = _AppFeatures;

  factory AppFeatures.fromJson(Map<String, dynamic> json) =>
      _$AppFeaturesFromJson(json);
}
