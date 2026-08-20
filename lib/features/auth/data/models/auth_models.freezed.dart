// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthUser {

 String get id; String get email; String get name; String get role;/// `null` = todavia no vio los slides. Vive en el backend ademas de en
/// local, asi que sobrevive a una reinstalacion.
 DateTime? get onboardingSeenAt;
/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUserCopyWith<AuthUser> get copyWith => _$AuthUserCopyWithImpl<AuthUser>(this as AuthUser, _$identity);

  /// Serializes this AuthUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.onboardingSeenAt, onboardingSeenAt) || other.onboardingSeenAt == onboardingSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,name,role,onboardingSeenAt);

@override
String toString() {
  return 'AuthUser(id: $id, email: $email, name: $name, role: $role, onboardingSeenAt: $onboardingSeenAt)';
}


}

/// @nodoc
abstract mixin class $AuthUserCopyWith<$Res>  {
  factory $AuthUserCopyWith(AuthUser value, $Res Function(AuthUser) _then) = _$AuthUserCopyWithImpl;
@useResult
$Res call({
 String id, String email, String name, String role, DateTime? onboardingSeenAt
});




}
/// @nodoc
class _$AuthUserCopyWithImpl<$Res>
    implements $AuthUserCopyWith<$Res> {
  _$AuthUserCopyWithImpl(this._self, this._then);

  final AuthUser _self;
  final $Res Function(AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? name = null,Object? role = null,Object? onboardingSeenAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,onboardingSeenAt: freezed == onboardingSeenAt ? _self.onboardingSeenAt : onboardingSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthUser].
extension AuthUserPatterns on AuthUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthUser value)  $default,){
final _that = this;
switch (_that) {
case _AuthUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthUser value)?  $default,){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email,  String name,  String role,  DateTime? onboardingSeenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.id,_that.email,_that.name,_that.role,_that.onboardingSeenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email,  String name,  String role,  DateTime? onboardingSeenAt)  $default,) {final _that = this;
switch (_that) {
case _AuthUser():
return $default(_that.id,_that.email,_that.name,_that.role,_that.onboardingSeenAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email,  String name,  String role,  DateTime? onboardingSeenAt)?  $default,) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.id,_that.email,_that.name,_that.role,_that.onboardingSeenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthUser implements AuthUser {
  const _AuthUser({required this.id, required this.email, required this.name, required this.role, this.onboardingSeenAt});
  factory _AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);

@override final  String id;
@override final  String email;
@override final  String name;
@override final  String role;
/// `null` = todavia no vio los slides. Vive en el backend ademas de en
/// local, asi que sobrevive a una reinstalacion.
@override final  DateTime? onboardingSeenAt;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthUserCopyWith<_AuthUser> get copyWith => __$AuthUserCopyWithImpl<_AuthUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthUser&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.onboardingSeenAt, onboardingSeenAt) || other.onboardingSeenAt == onboardingSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,name,role,onboardingSeenAt);

@override
String toString() {
  return 'AuthUser(id: $id, email: $email, name: $name, role: $role, onboardingSeenAt: $onboardingSeenAt)';
}


}

/// @nodoc
abstract mixin class _$AuthUserCopyWith<$Res> implements $AuthUserCopyWith<$Res> {
  factory _$AuthUserCopyWith(_AuthUser value, $Res Function(_AuthUser) _then) = __$AuthUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, String name, String role, DateTime? onboardingSeenAt
});




}
/// @nodoc
class __$AuthUserCopyWithImpl<$Res>
    implements _$AuthUserCopyWith<$Res> {
  __$AuthUserCopyWithImpl(this._self, this._then);

  final _AuthUser _self;
  final $Res Function(_AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? name = null,Object? role = null,Object? onboardingSeenAt = freezed,}) {
  return _then(_AuthUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,onboardingSeenAt: freezed == onboardingSeenAt ? _self.onboardingSeenAt : onboardingSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AuthSession {

 String get accessToken; String get refreshToken;/// Segundos de vida del access token (900).
 int get expiresIn; AuthUser? get user;
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSessionCopyWith<AuthSession> get copyWith => _$AuthSessionCopyWithImpl<AuthSession>(this as AuthSession, _$identity);

  /// Serializes this AuthSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSession&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,user);

@override
String toString() {
  return 'AuthSession(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthSessionCopyWith<$Res>  {
  factory $AuthSessionCopyWith(AuthSession value, $Res Function(AuthSession) _then) = _$AuthSessionCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, int expiresIn, AuthUser? user
});


$AuthUserCopyWith<$Res>? get user;

}
/// @nodoc
class _$AuthSessionCopyWithImpl<$Res>
    implements $AuthSessionCopyWith<$Res> {
  _$AuthSessionCopyWithImpl(this._self, this._then);

  final AuthSession _self;
  final $Res Function(AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? user = freezed,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser?,
  ));
}
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $AuthUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthSession].
extension AuthSessionPatterns on AuthSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthSession value)  $default,){
final _that = this;
switch (_that) {
case _AuthSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthSession value)?  $default,){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  int expiresIn,  AuthUser? user)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  int expiresIn,  AuthUser? user)  $default,) {final _that = this;
switch (_that) {
case _AuthSession():
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.user);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  int expiresIn,  AuthUser? user)?  $default,) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.user);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthSession implements AuthSession {
  const _AuthSession({required this.accessToken, required this.refreshToken, required this.expiresIn, this.user});
  factory _AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
/// Segundos de vida del access token (900).
@override final  int expiresIn;
@override final  AuthUser? user;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthSessionCopyWith<_AuthSession> get copyWith => __$AuthSessionCopyWithImpl<_AuthSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthSession&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,user);

@override
String toString() {
  return 'AuthSession(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, user: $user)';
}


}

/// @nodoc
abstract mixin class _$AuthSessionCopyWith<$Res> implements $AuthSessionCopyWith<$Res> {
  factory _$AuthSessionCopyWith(_AuthSession value, $Res Function(_AuthSession) _then) = __$AuthSessionCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, int expiresIn, AuthUser? user
});


@override $AuthUserCopyWith<$Res>? get user;

}
/// @nodoc
class __$AuthSessionCopyWithImpl<$Res>
    implements _$AuthSessionCopyWith<$Res> {
  __$AuthSessionCopyWithImpl(this._self, this._then);

  final _AuthSession _self;
  final $Res Function(_AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? user = freezed,}) {
  return _then(_AuthSession(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser?,
  ));
}

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $AuthUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$DeviceSession {

 String get id; String get deviceId; DateTime get lastUsedAt; DateTime get expiresAt; bool get current; String? get deviceName; String? get platform;
/// Create a copy of DeviceSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceSessionCopyWith<DeviceSession> get copyWith => _$DeviceSessionCopyWithImpl<DeviceSession>(this as DeviceSession, _$identity);

  /// Serializes this DeviceSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceSession&&(identical(other.id, id) || other.id == id)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.current, current) || other.current == current)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.platform, platform) || other.platform == platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deviceId,lastUsedAt,expiresAt,current,deviceName,platform);

@override
String toString() {
  return 'DeviceSession(id: $id, deviceId: $deviceId, lastUsedAt: $lastUsedAt, expiresAt: $expiresAt, current: $current, deviceName: $deviceName, platform: $platform)';
}


}

/// @nodoc
abstract mixin class $DeviceSessionCopyWith<$Res>  {
  factory $DeviceSessionCopyWith(DeviceSession value, $Res Function(DeviceSession) _then) = _$DeviceSessionCopyWithImpl;
@useResult
$Res call({
 String id, String deviceId, DateTime lastUsedAt, DateTime expiresAt, bool current, String? deviceName, String? platform
});




}
/// @nodoc
class _$DeviceSessionCopyWithImpl<$Res>
    implements $DeviceSessionCopyWith<$Res> {
  _$DeviceSessionCopyWithImpl(this._self, this._then);

  final DeviceSession _self;
  final $Res Function(DeviceSession) _then;

/// Create a copy of DeviceSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? deviceId = null,Object? lastUsedAt = null,Object? expiresAt = null,Object? current = null,Object? deviceName = freezed,Object? platform = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,lastUsedAt: null == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceSession].
extension DeviceSessionPatterns on DeviceSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceSession value)  $default,){
final _that = this;
switch (_that) {
case _DeviceSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceSession value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String deviceId,  DateTime lastUsedAt,  DateTime expiresAt,  bool current,  String? deviceName,  String? platform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceSession() when $default != null:
return $default(_that.id,_that.deviceId,_that.lastUsedAt,_that.expiresAt,_that.current,_that.deviceName,_that.platform);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String deviceId,  DateTime lastUsedAt,  DateTime expiresAt,  bool current,  String? deviceName,  String? platform)  $default,) {final _that = this;
switch (_that) {
case _DeviceSession():
return $default(_that.id,_that.deviceId,_that.lastUsedAt,_that.expiresAt,_that.current,_that.deviceName,_that.platform);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String deviceId,  DateTime lastUsedAt,  DateTime expiresAt,  bool current,  String? deviceName,  String? platform)?  $default,) {final _that = this;
switch (_that) {
case _DeviceSession() when $default != null:
return $default(_that.id,_that.deviceId,_that.lastUsedAt,_that.expiresAt,_that.current,_that.deviceName,_that.platform);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceSession implements DeviceSession {
  const _DeviceSession({required this.id, required this.deviceId, required this.lastUsedAt, required this.expiresAt, this.current = false, this.deviceName, this.platform});
  factory _DeviceSession.fromJson(Map<String, dynamic> json) => _$DeviceSessionFromJson(json);

@override final  String id;
@override final  String deviceId;
@override final  DateTime lastUsedAt;
@override final  DateTime expiresAt;
@override@JsonKey() final  bool current;
@override final  String? deviceName;
@override final  String? platform;

/// Create a copy of DeviceSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceSessionCopyWith<_DeviceSession> get copyWith => __$DeviceSessionCopyWithImpl<_DeviceSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceSession&&(identical(other.id, id) || other.id == id)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.current, current) || other.current == current)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.platform, platform) || other.platform == platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deviceId,lastUsedAt,expiresAt,current,deviceName,platform);

@override
String toString() {
  return 'DeviceSession(id: $id, deviceId: $deviceId, lastUsedAt: $lastUsedAt, expiresAt: $expiresAt, current: $current, deviceName: $deviceName, platform: $platform)';
}


}

/// @nodoc
abstract mixin class _$DeviceSessionCopyWith<$Res> implements $DeviceSessionCopyWith<$Res> {
  factory _$DeviceSessionCopyWith(_DeviceSession value, $Res Function(_DeviceSession) _then) = __$DeviceSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String deviceId, DateTime lastUsedAt, DateTime expiresAt, bool current, String? deviceName, String? platform
});




}
/// @nodoc
class __$DeviceSessionCopyWithImpl<$Res>
    implements _$DeviceSessionCopyWith<$Res> {
  __$DeviceSessionCopyWithImpl(this._self, this._then);

  final _DeviceSession _self;
  final $Res Function(_DeviceSession) _then;

/// Create a copy of DeviceSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? deviceId = null,Object? lastUsedAt = null,Object? expiresAt = null,Object? current = null,Object? deviceName = freezed,Object? platform = freezed,}) {
  return _then(_DeviceSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,lastUsedAt: null == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
