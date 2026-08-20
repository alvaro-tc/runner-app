// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppConfig {

 String get currency; String get timezone; String get defaultLocale;/// Contrato: por debajo de esta version la API no garantiza nada.
 String get minAppVersion; String get deepLinkScheme; TrackingConfig get tracking; AppLimits get limits; AppFeatures get features;/// `null` cuando el cargo por servicio esta apagado — ausencia, no
/// `enabled: false`. Trae solo la etiqueta: el monto lo calcula
/// `/pricing/quote`, nunca el movil.
 ServiceFeeInfo? get serviceFee;
/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCopyWith<AppConfig> get copyWith => _$AppConfigCopyWithImpl<AppConfig>(this as AppConfig, _$identity);

  /// Serializes this AppConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfig&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.defaultLocale, defaultLocale) || other.defaultLocale == defaultLocale)&&(identical(other.minAppVersion, minAppVersion) || other.minAppVersion == minAppVersion)&&(identical(other.deepLinkScheme, deepLinkScheme) || other.deepLinkScheme == deepLinkScheme)&&(identical(other.tracking, tracking) || other.tracking == tracking)&&(identical(other.limits, limits) || other.limits == limits)&&(identical(other.features, features) || other.features == features)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,timezone,defaultLocale,minAppVersion,deepLinkScheme,tracking,limits,features,serviceFee);

@override
String toString() {
  return 'AppConfig(currency: $currency, timezone: $timezone, defaultLocale: $defaultLocale, minAppVersion: $minAppVersion, deepLinkScheme: $deepLinkScheme, tracking: $tracking, limits: $limits, features: $features, serviceFee: $serviceFee)';
}


}

/// @nodoc
abstract mixin class $AppConfigCopyWith<$Res>  {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) _then) = _$AppConfigCopyWithImpl;
@useResult
$Res call({
 String currency, String timezone, String defaultLocale, String minAppVersion, String deepLinkScheme, TrackingConfig tracking, AppLimits limits, AppFeatures features, ServiceFeeInfo? serviceFee
});


$TrackingConfigCopyWith<$Res> get tracking;$AppLimitsCopyWith<$Res> get limits;$AppFeaturesCopyWith<$Res> get features;$ServiceFeeInfoCopyWith<$Res>? get serviceFee;

}
/// @nodoc
class _$AppConfigCopyWithImpl<$Res>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._self, this._then);

  final AppConfig _self;
  final $Res Function(AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currency = null,Object? timezone = null,Object? defaultLocale = null,Object? minAppVersion = null,Object? deepLinkScheme = null,Object? tracking = null,Object? limits = null,Object? features = null,Object? serviceFee = freezed,}) {
  return _then(_self.copyWith(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,defaultLocale: null == defaultLocale ? _self.defaultLocale : defaultLocale // ignore: cast_nullable_to_non_nullable
as String,minAppVersion: null == minAppVersion ? _self.minAppVersion : minAppVersion // ignore: cast_nullable_to_non_nullable
as String,deepLinkScheme: null == deepLinkScheme ? _self.deepLinkScheme : deepLinkScheme // ignore: cast_nullable_to_non_nullable
as String,tracking: null == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as TrackingConfig,limits: null == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as AppLimits,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as AppFeatures,serviceFee: freezed == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as ServiceFeeInfo?,
  ));
}
/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackingConfigCopyWith<$Res> get tracking {
  
  return $TrackingConfigCopyWith<$Res>(_self.tracking, (value) {
    return _then(_self.copyWith(tracking: value));
  });
}/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppLimitsCopyWith<$Res> get limits {
  
  return $AppLimitsCopyWith<$Res>(_self.limits, (value) {
    return _then(_self.copyWith(limits: value));
  });
}/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFeaturesCopyWith<$Res> get features {
  
  return $AppFeaturesCopyWith<$Res>(_self.features, (value) {
    return _then(_self.copyWith(features: value));
  });
}/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceFeeInfoCopyWith<$Res>? get serviceFee {
    if (_self.serviceFee == null) {
    return null;
  }

  return $ServiceFeeInfoCopyWith<$Res>(_self.serviceFee!, (value) {
    return _then(_self.copyWith(serviceFee: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppConfig].
extension AppConfigPatterns on AppConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppConfig value)  $default,){
final _that = this;
switch (_that) {
case _AppConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currency,  String timezone,  String defaultLocale,  String minAppVersion,  String deepLinkScheme,  TrackingConfig tracking,  AppLimits limits,  AppFeatures features,  ServiceFeeInfo? serviceFee)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.currency,_that.timezone,_that.defaultLocale,_that.minAppVersion,_that.deepLinkScheme,_that.tracking,_that.limits,_that.features,_that.serviceFee);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currency,  String timezone,  String defaultLocale,  String minAppVersion,  String deepLinkScheme,  TrackingConfig tracking,  AppLimits limits,  AppFeatures features,  ServiceFeeInfo? serviceFee)  $default,) {final _that = this;
switch (_that) {
case _AppConfig():
return $default(_that.currency,_that.timezone,_that.defaultLocale,_that.minAppVersion,_that.deepLinkScheme,_that.tracking,_that.limits,_that.features,_that.serviceFee);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currency,  String timezone,  String defaultLocale,  String minAppVersion,  String deepLinkScheme,  TrackingConfig tracking,  AppLimits limits,  AppFeatures features,  ServiceFeeInfo? serviceFee)?  $default,) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.currency,_that.timezone,_that.defaultLocale,_that.minAppVersion,_that.deepLinkScheme,_that.tracking,_that.limits,_that.features,_that.serviceFee);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppConfig implements AppConfig {
  const _AppConfig({required this.currency, required this.timezone, required this.defaultLocale, required this.minAppVersion, required this.deepLinkScheme, required this.tracking, required this.limits, required this.features, this.serviceFee});
  factory _AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);

@override final  String currency;
@override final  String timezone;
@override final  String defaultLocale;
/// Contrato: por debajo de esta version la API no garantiza nada.
@override final  String minAppVersion;
@override final  String deepLinkScheme;
@override final  TrackingConfig tracking;
@override final  AppLimits limits;
@override final  AppFeatures features;
/// `null` cuando el cargo por servicio esta apagado — ausencia, no
/// `enabled: false`. Trae solo la etiqueta: el monto lo calcula
/// `/pricing/quote`, nunca el movil.
@override final  ServiceFeeInfo? serviceFee;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppConfigCopyWith<_AppConfig> get copyWith => __$AppConfigCopyWithImpl<_AppConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppConfig&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.defaultLocale, defaultLocale) || other.defaultLocale == defaultLocale)&&(identical(other.minAppVersion, minAppVersion) || other.minAppVersion == minAppVersion)&&(identical(other.deepLinkScheme, deepLinkScheme) || other.deepLinkScheme == deepLinkScheme)&&(identical(other.tracking, tracking) || other.tracking == tracking)&&(identical(other.limits, limits) || other.limits == limits)&&(identical(other.features, features) || other.features == features)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,timezone,defaultLocale,minAppVersion,deepLinkScheme,tracking,limits,features,serviceFee);

@override
String toString() {
  return 'AppConfig(currency: $currency, timezone: $timezone, defaultLocale: $defaultLocale, minAppVersion: $minAppVersion, deepLinkScheme: $deepLinkScheme, tracking: $tracking, limits: $limits, features: $features, serviceFee: $serviceFee)';
}


}

/// @nodoc
abstract mixin class _$AppConfigCopyWith<$Res> implements $AppConfigCopyWith<$Res> {
  factory _$AppConfigCopyWith(_AppConfig value, $Res Function(_AppConfig) _then) = __$AppConfigCopyWithImpl;
@override @useResult
$Res call({
 String currency, String timezone, String defaultLocale, String minAppVersion, String deepLinkScheme, TrackingConfig tracking, AppLimits limits, AppFeatures features, ServiceFeeInfo? serviceFee
});


@override $TrackingConfigCopyWith<$Res> get tracking;@override $AppLimitsCopyWith<$Res> get limits;@override $AppFeaturesCopyWith<$Res> get features;@override $ServiceFeeInfoCopyWith<$Res>? get serviceFee;

}
/// @nodoc
class __$AppConfigCopyWithImpl<$Res>
    implements _$AppConfigCopyWith<$Res> {
  __$AppConfigCopyWithImpl(this._self, this._then);

  final _AppConfig _self;
  final $Res Function(_AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currency = null,Object? timezone = null,Object? defaultLocale = null,Object? minAppVersion = null,Object? deepLinkScheme = null,Object? tracking = null,Object? limits = null,Object? features = null,Object? serviceFee = freezed,}) {
  return _then(_AppConfig(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,defaultLocale: null == defaultLocale ? _self.defaultLocale : defaultLocale // ignore: cast_nullable_to_non_nullable
as String,minAppVersion: null == minAppVersion ? _self.minAppVersion : minAppVersion // ignore: cast_nullable_to_non_nullable
as String,deepLinkScheme: null == deepLinkScheme ? _self.deepLinkScheme : deepLinkScheme // ignore: cast_nullable_to_non_nullable
as String,tracking: null == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as TrackingConfig,limits: null == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as AppLimits,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as AppFeatures,serviceFee: freezed == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as ServiceFeeInfo?,
  ));
}

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackingConfigCopyWith<$Res> get tracking {
  
  return $TrackingConfigCopyWith<$Res>(_self.tracking, (value) {
    return _then(_self.copyWith(tracking: value));
  });
}/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppLimitsCopyWith<$Res> get limits {
  
  return $AppLimitsCopyWith<$Res>(_self.limits, (value) {
    return _then(_self.copyWith(limits: value));
  });
}/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFeaturesCopyWith<$Res> get features {
  
  return $AppFeaturesCopyWith<$Res>(_self.features, (value) {
    return _then(_self.copyWith(features: value));
  });
}/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ServiceFeeInfoCopyWith<$Res>? get serviceFee {
    if (_self.serviceFee == null) {
    return null;
  }

  return $ServiceFeeInfoCopyWith<$Res>(_self.serviceFee!, (value) {
    return _then(_self.copyWith(serviceFee: value));
  });
}
}


/// @nodoc
mixin _$ServiceFeeInfo {

 String get label;
/// Create a copy of ServiceFeeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceFeeInfoCopyWith<ServiceFeeInfo> get copyWith => _$ServiceFeeInfoCopyWithImpl<ServiceFeeInfo>(this as ServiceFeeInfo, _$identity);

  /// Serializes this ServiceFeeInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceFeeInfo&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label);

@override
String toString() {
  return 'ServiceFeeInfo(label: $label)';
}


}

/// @nodoc
abstract mixin class $ServiceFeeInfoCopyWith<$Res>  {
  factory $ServiceFeeInfoCopyWith(ServiceFeeInfo value, $Res Function(ServiceFeeInfo) _then) = _$ServiceFeeInfoCopyWithImpl;
@useResult
$Res call({
 String label
});




}
/// @nodoc
class _$ServiceFeeInfoCopyWithImpl<$Res>
    implements $ServiceFeeInfoCopyWith<$Res> {
  _$ServiceFeeInfoCopyWithImpl(this._self, this._then);

  final ServiceFeeInfo _self;
  final $Res Function(ServiceFeeInfo) _then;

/// Create a copy of ServiceFeeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceFeeInfo].
extension ServiceFeeInfoPatterns on ServiceFeeInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceFeeInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceFeeInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceFeeInfo value)  $default,){
final _that = this;
switch (_that) {
case _ServiceFeeInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceFeeInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceFeeInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceFeeInfo() when $default != null:
return $default(_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label)  $default,) {final _that = this;
switch (_that) {
case _ServiceFeeInfo():
return $default(_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label)?  $default,) {final _that = this;
switch (_that) {
case _ServiceFeeInfo() when $default != null:
return $default(_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceFeeInfo implements ServiceFeeInfo {
  const _ServiceFeeInfo({required this.label});
  factory _ServiceFeeInfo.fromJson(Map<String, dynamic> json) => _$ServiceFeeInfoFromJson(json);

@override final  String label;

/// Create a copy of ServiceFeeInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceFeeInfoCopyWith<_ServiceFeeInfo> get copyWith => __$ServiceFeeInfoCopyWithImpl<_ServiceFeeInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceFeeInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceFeeInfo&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label);

@override
String toString() {
  return 'ServiceFeeInfo(label: $label)';
}


}

/// @nodoc
abstract mixin class _$ServiceFeeInfoCopyWith<$Res> implements $ServiceFeeInfoCopyWith<$Res> {
  factory _$ServiceFeeInfoCopyWith(_ServiceFeeInfo value, $Res Function(_ServiceFeeInfo) _then) = __$ServiceFeeInfoCopyWithImpl;
@override @useResult
$Res call({
 String label
});




}
/// @nodoc
class __$ServiceFeeInfoCopyWithImpl<$Res>
    implements _$ServiceFeeInfoCopyWith<$Res> {
  __$ServiceFeeInfoCopyWithImpl(this._self, this._then);

  final _ServiceFeeInfo _self;
  final $Res Function(_ServiceFeeInfo) _then;

/// Create a copy of ServiceFeeInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,}) {
  return _then(_ServiceFeeInfo(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TrackingConfig {

 int get maxAccuracyMeters; int get maxBatchesPerMinute; int get suggestedBatchSeconds;
/// Create a copy of TrackingConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackingConfigCopyWith<TrackingConfig> get copyWith => _$TrackingConfigCopyWithImpl<TrackingConfig>(this as TrackingConfig, _$identity);

  /// Serializes this TrackingConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackingConfig&&(identical(other.maxAccuracyMeters, maxAccuracyMeters) || other.maxAccuracyMeters == maxAccuracyMeters)&&(identical(other.maxBatchesPerMinute, maxBatchesPerMinute) || other.maxBatchesPerMinute == maxBatchesPerMinute)&&(identical(other.suggestedBatchSeconds, suggestedBatchSeconds) || other.suggestedBatchSeconds == suggestedBatchSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxAccuracyMeters,maxBatchesPerMinute,suggestedBatchSeconds);

@override
String toString() {
  return 'TrackingConfig(maxAccuracyMeters: $maxAccuracyMeters, maxBatchesPerMinute: $maxBatchesPerMinute, suggestedBatchSeconds: $suggestedBatchSeconds)';
}


}

/// @nodoc
abstract mixin class $TrackingConfigCopyWith<$Res>  {
  factory $TrackingConfigCopyWith(TrackingConfig value, $Res Function(TrackingConfig) _then) = _$TrackingConfigCopyWithImpl;
@useResult
$Res call({
 int maxAccuracyMeters, int maxBatchesPerMinute, int suggestedBatchSeconds
});




}
/// @nodoc
class _$TrackingConfigCopyWithImpl<$Res>
    implements $TrackingConfigCopyWith<$Res> {
  _$TrackingConfigCopyWithImpl(this._self, this._then);

  final TrackingConfig _self;
  final $Res Function(TrackingConfig) _then;

/// Create a copy of TrackingConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxAccuracyMeters = null,Object? maxBatchesPerMinute = null,Object? suggestedBatchSeconds = null,}) {
  return _then(_self.copyWith(
maxAccuracyMeters: null == maxAccuracyMeters ? _self.maxAccuracyMeters : maxAccuracyMeters // ignore: cast_nullable_to_non_nullable
as int,maxBatchesPerMinute: null == maxBatchesPerMinute ? _self.maxBatchesPerMinute : maxBatchesPerMinute // ignore: cast_nullable_to_non_nullable
as int,suggestedBatchSeconds: null == suggestedBatchSeconds ? _self.suggestedBatchSeconds : suggestedBatchSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackingConfig].
extension TrackingConfigPatterns on TrackingConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackingConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackingConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackingConfig value)  $default,){
final _that = this;
switch (_that) {
case _TrackingConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackingConfig value)?  $default,){
final _that = this;
switch (_that) {
case _TrackingConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxAccuracyMeters,  int maxBatchesPerMinute,  int suggestedBatchSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackingConfig() when $default != null:
return $default(_that.maxAccuracyMeters,_that.maxBatchesPerMinute,_that.suggestedBatchSeconds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxAccuracyMeters,  int maxBatchesPerMinute,  int suggestedBatchSeconds)  $default,) {final _that = this;
switch (_that) {
case _TrackingConfig():
return $default(_that.maxAccuracyMeters,_that.maxBatchesPerMinute,_that.suggestedBatchSeconds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxAccuracyMeters,  int maxBatchesPerMinute,  int suggestedBatchSeconds)?  $default,) {final _that = this;
switch (_that) {
case _TrackingConfig() when $default != null:
return $default(_that.maxAccuracyMeters,_that.maxBatchesPerMinute,_that.suggestedBatchSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackingConfig implements TrackingConfig {
  const _TrackingConfig({required this.maxAccuracyMeters, required this.maxBatchesPerMinute, required this.suggestedBatchSeconds});
  factory _TrackingConfig.fromJson(Map<String, dynamic> json) => _$TrackingConfigFromJson(json);

@override final  int maxAccuracyMeters;
@override final  int maxBatchesPerMinute;
@override final  int suggestedBatchSeconds;

/// Create a copy of TrackingConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackingConfigCopyWith<_TrackingConfig> get copyWith => __$TrackingConfigCopyWithImpl<_TrackingConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackingConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackingConfig&&(identical(other.maxAccuracyMeters, maxAccuracyMeters) || other.maxAccuracyMeters == maxAccuracyMeters)&&(identical(other.maxBatchesPerMinute, maxBatchesPerMinute) || other.maxBatchesPerMinute == maxBatchesPerMinute)&&(identical(other.suggestedBatchSeconds, suggestedBatchSeconds) || other.suggestedBatchSeconds == suggestedBatchSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxAccuracyMeters,maxBatchesPerMinute,suggestedBatchSeconds);

@override
String toString() {
  return 'TrackingConfig(maxAccuracyMeters: $maxAccuracyMeters, maxBatchesPerMinute: $maxBatchesPerMinute, suggestedBatchSeconds: $suggestedBatchSeconds)';
}


}

/// @nodoc
abstract mixin class _$TrackingConfigCopyWith<$Res> implements $TrackingConfigCopyWith<$Res> {
  factory _$TrackingConfigCopyWith(_TrackingConfig value, $Res Function(_TrackingConfig) _then) = __$TrackingConfigCopyWithImpl;
@override @useResult
$Res call({
 int maxAccuracyMeters, int maxBatchesPerMinute, int suggestedBatchSeconds
});




}
/// @nodoc
class __$TrackingConfigCopyWithImpl<$Res>
    implements _$TrackingConfigCopyWith<$Res> {
  __$TrackingConfigCopyWithImpl(this._self, this._then);

  final _TrackingConfig _self;
  final $Res Function(_TrackingConfig) _then;

/// Create a copy of TrackingConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxAccuracyMeters = null,Object? maxBatchesPerMinute = null,Object? suggestedBatchSeconds = null,}) {
  return _then(_TrackingConfig(
maxAccuracyMeters: null == maxAccuracyMeters ? _self.maxAccuracyMeters : maxAccuracyMeters // ignore: cast_nullable_to_non_nullable
as int,maxBatchesPerMinute: null == maxBatchesPerMinute ? _self.maxBatchesPerMinute : maxBatchesPerMinute // ignore: cast_nullable_to_non_nullable
as int,suggestedBatchSeconds: null == suggestedBatchSeconds ? _self.suggestedBatchSeconds : suggestedBatchSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AppLimits {

 int get avatarMaxBytes; int get requestsPerMinute; int get shoeAlertThresholdMeters;
/// Create a copy of AppLimits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppLimitsCopyWith<AppLimits> get copyWith => _$AppLimitsCopyWithImpl<AppLimits>(this as AppLimits, _$identity);

  /// Serializes this AppLimits to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppLimits&&(identical(other.avatarMaxBytes, avatarMaxBytes) || other.avatarMaxBytes == avatarMaxBytes)&&(identical(other.requestsPerMinute, requestsPerMinute) || other.requestsPerMinute == requestsPerMinute)&&(identical(other.shoeAlertThresholdMeters, shoeAlertThresholdMeters) || other.shoeAlertThresholdMeters == shoeAlertThresholdMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avatarMaxBytes,requestsPerMinute,shoeAlertThresholdMeters);

@override
String toString() {
  return 'AppLimits(avatarMaxBytes: $avatarMaxBytes, requestsPerMinute: $requestsPerMinute, shoeAlertThresholdMeters: $shoeAlertThresholdMeters)';
}


}

/// @nodoc
abstract mixin class $AppLimitsCopyWith<$Res>  {
  factory $AppLimitsCopyWith(AppLimits value, $Res Function(AppLimits) _then) = _$AppLimitsCopyWithImpl;
@useResult
$Res call({
 int avatarMaxBytes, int requestsPerMinute, int shoeAlertThresholdMeters
});




}
/// @nodoc
class _$AppLimitsCopyWithImpl<$Res>
    implements $AppLimitsCopyWith<$Res> {
  _$AppLimitsCopyWithImpl(this._self, this._then);

  final AppLimits _self;
  final $Res Function(AppLimits) _then;

/// Create a copy of AppLimits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? avatarMaxBytes = null,Object? requestsPerMinute = null,Object? shoeAlertThresholdMeters = null,}) {
  return _then(_self.copyWith(
avatarMaxBytes: null == avatarMaxBytes ? _self.avatarMaxBytes : avatarMaxBytes // ignore: cast_nullable_to_non_nullable
as int,requestsPerMinute: null == requestsPerMinute ? _self.requestsPerMinute : requestsPerMinute // ignore: cast_nullable_to_non_nullable
as int,shoeAlertThresholdMeters: null == shoeAlertThresholdMeters ? _self.shoeAlertThresholdMeters : shoeAlertThresholdMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AppLimits].
extension AppLimitsPatterns on AppLimits {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppLimits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppLimits() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppLimits value)  $default,){
final _that = this;
switch (_that) {
case _AppLimits():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppLimits value)?  $default,){
final _that = this;
switch (_that) {
case _AppLimits() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int avatarMaxBytes,  int requestsPerMinute,  int shoeAlertThresholdMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppLimits() when $default != null:
return $default(_that.avatarMaxBytes,_that.requestsPerMinute,_that.shoeAlertThresholdMeters);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int avatarMaxBytes,  int requestsPerMinute,  int shoeAlertThresholdMeters)  $default,) {final _that = this;
switch (_that) {
case _AppLimits():
return $default(_that.avatarMaxBytes,_that.requestsPerMinute,_that.shoeAlertThresholdMeters);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int avatarMaxBytes,  int requestsPerMinute,  int shoeAlertThresholdMeters)?  $default,) {final _that = this;
switch (_that) {
case _AppLimits() when $default != null:
return $default(_that.avatarMaxBytes,_that.requestsPerMinute,_that.shoeAlertThresholdMeters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppLimits implements AppLimits {
  const _AppLimits({required this.avatarMaxBytes, required this.requestsPerMinute, required this.shoeAlertThresholdMeters});
  factory _AppLimits.fromJson(Map<String, dynamic> json) => _$AppLimitsFromJson(json);

@override final  int avatarMaxBytes;
@override final  int requestsPerMinute;
@override final  int shoeAlertThresholdMeters;

/// Create a copy of AppLimits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppLimitsCopyWith<_AppLimits> get copyWith => __$AppLimitsCopyWithImpl<_AppLimits>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppLimitsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppLimits&&(identical(other.avatarMaxBytes, avatarMaxBytes) || other.avatarMaxBytes == avatarMaxBytes)&&(identical(other.requestsPerMinute, requestsPerMinute) || other.requestsPerMinute == requestsPerMinute)&&(identical(other.shoeAlertThresholdMeters, shoeAlertThresholdMeters) || other.shoeAlertThresholdMeters == shoeAlertThresholdMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avatarMaxBytes,requestsPerMinute,shoeAlertThresholdMeters);

@override
String toString() {
  return 'AppLimits(avatarMaxBytes: $avatarMaxBytes, requestsPerMinute: $requestsPerMinute, shoeAlertThresholdMeters: $shoeAlertThresholdMeters)';
}


}

/// @nodoc
abstract mixin class _$AppLimitsCopyWith<$Res> implements $AppLimitsCopyWith<$Res> {
  factory _$AppLimitsCopyWith(_AppLimits value, $Res Function(_AppLimits) _then) = __$AppLimitsCopyWithImpl;
@override @useResult
$Res call({
 int avatarMaxBytes, int requestsPerMinute, int shoeAlertThresholdMeters
});




}
/// @nodoc
class __$AppLimitsCopyWithImpl<$Res>
    implements _$AppLimitsCopyWith<$Res> {
  __$AppLimitsCopyWithImpl(this._self, this._then);

  final _AppLimits _self;
  final $Res Function(_AppLimits) _then;

/// Create a copy of AppLimits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? avatarMaxBytes = null,Object? requestsPerMinute = null,Object? shoeAlertThresholdMeters = null,}) {
  return _then(_AppLimits(
avatarMaxBytes: null == avatarMaxBytes ? _self.avatarMaxBytes : avatarMaxBytes // ignore: cast_nullable_to_non_nullable
as int,requestsPerMinute: null == requestsPerMinute ? _self.requestsPerMinute : requestsPerMinute // ignore: cast_nullable_to_non_nullable
as int,shoeAlertThresholdMeters: null == shoeAlertThresholdMeters ? _self.shoeAlertThresholdMeters : shoeAlertThresholdMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AppFeatures {

 bool get gpsSimulation; bool get liveTracking; bool get socialLogin;
/// Create a copy of AppFeatures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppFeaturesCopyWith<AppFeatures> get copyWith => _$AppFeaturesCopyWithImpl<AppFeatures>(this as AppFeatures, _$identity);

  /// Serializes this AppFeatures to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFeatures&&(identical(other.gpsSimulation, gpsSimulation) || other.gpsSimulation == gpsSimulation)&&(identical(other.liveTracking, liveTracking) || other.liveTracking == liveTracking)&&(identical(other.socialLogin, socialLogin) || other.socialLogin == socialLogin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gpsSimulation,liveTracking,socialLogin);

@override
String toString() {
  return 'AppFeatures(gpsSimulation: $gpsSimulation, liveTracking: $liveTracking, socialLogin: $socialLogin)';
}


}

/// @nodoc
abstract mixin class $AppFeaturesCopyWith<$Res>  {
  factory $AppFeaturesCopyWith(AppFeatures value, $Res Function(AppFeatures) _then) = _$AppFeaturesCopyWithImpl;
@useResult
$Res call({
 bool gpsSimulation, bool liveTracking, bool socialLogin
});




}
/// @nodoc
class _$AppFeaturesCopyWithImpl<$Res>
    implements $AppFeaturesCopyWith<$Res> {
  _$AppFeaturesCopyWithImpl(this._self, this._then);

  final AppFeatures _self;
  final $Res Function(AppFeatures) _then;

/// Create a copy of AppFeatures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gpsSimulation = null,Object? liveTracking = null,Object? socialLogin = null,}) {
  return _then(_self.copyWith(
gpsSimulation: null == gpsSimulation ? _self.gpsSimulation : gpsSimulation // ignore: cast_nullable_to_non_nullable
as bool,liveTracking: null == liveTracking ? _self.liveTracking : liveTracking // ignore: cast_nullable_to_non_nullable
as bool,socialLogin: null == socialLogin ? _self.socialLogin : socialLogin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppFeatures].
extension AppFeaturesPatterns on AppFeatures {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppFeatures value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppFeatures() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppFeatures value)  $default,){
final _that = this;
switch (_that) {
case _AppFeatures():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppFeatures value)?  $default,){
final _that = this;
switch (_that) {
case _AppFeatures() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool gpsSimulation,  bool liveTracking,  bool socialLogin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppFeatures() when $default != null:
return $default(_that.gpsSimulation,_that.liveTracking,_that.socialLogin);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool gpsSimulation,  bool liveTracking,  bool socialLogin)  $default,) {final _that = this;
switch (_that) {
case _AppFeatures():
return $default(_that.gpsSimulation,_that.liveTracking,_that.socialLogin);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool gpsSimulation,  bool liveTracking,  bool socialLogin)?  $default,) {final _that = this;
switch (_that) {
case _AppFeatures() when $default != null:
return $default(_that.gpsSimulation,_that.liveTracking,_that.socialLogin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppFeatures implements AppFeatures {
  const _AppFeatures({this.gpsSimulation = false, this.liveTracking = false, this.socialLogin = false});
  factory _AppFeatures.fromJson(Map<String, dynamic> json) => _$AppFeaturesFromJson(json);

@override@JsonKey() final  bool gpsSimulation;
@override@JsonKey() final  bool liveTracking;
@override@JsonKey() final  bool socialLogin;

/// Create a copy of AppFeatures
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppFeaturesCopyWith<_AppFeatures> get copyWith => __$AppFeaturesCopyWithImpl<_AppFeatures>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppFeaturesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppFeatures&&(identical(other.gpsSimulation, gpsSimulation) || other.gpsSimulation == gpsSimulation)&&(identical(other.liveTracking, liveTracking) || other.liveTracking == liveTracking)&&(identical(other.socialLogin, socialLogin) || other.socialLogin == socialLogin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gpsSimulation,liveTracking,socialLogin);

@override
String toString() {
  return 'AppFeatures(gpsSimulation: $gpsSimulation, liveTracking: $liveTracking, socialLogin: $socialLogin)';
}


}

/// @nodoc
abstract mixin class _$AppFeaturesCopyWith<$Res> implements $AppFeaturesCopyWith<$Res> {
  factory _$AppFeaturesCopyWith(_AppFeatures value, $Res Function(_AppFeatures) _then) = __$AppFeaturesCopyWithImpl;
@override @useResult
$Res call({
 bool gpsSimulation, bool liveTracking, bool socialLogin
});




}
/// @nodoc
class __$AppFeaturesCopyWithImpl<$Res>
    implements _$AppFeaturesCopyWith<$Res> {
  __$AppFeaturesCopyWithImpl(this._self, this._then);

  final _AppFeatures _self;
  final $Res Function(_AppFeatures) _then;

/// Create a copy of AppFeatures
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gpsSimulation = null,Object? liveTracking = null,Object? socialLogin = null,}) {
  return _then(_AppFeatures(
gpsSimulation: null == gpsSimulation ? _self.gpsSimulation : gpsSimulation // ignore: cast_nullable_to_non_nullable
as bool,liveTracking: null == liveTracking ? _self.liveTracking : liveTracking // ignore: cast_nullable_to_non_nullable
as bool,socialLogin: null == socialLogin ? _self.socialLogin : socialLogin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
