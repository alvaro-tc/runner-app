// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracking_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StartedSession {

 String get sessionId; String get workoutId; DateTime get startedAt;/// Solo sirve para mandar posiciones a **esta** sesion y muere con ella.
/// Por eso puede viajar mil veces por entrenamiento y el JWT no.
 String get ingestToken;
/// Create a copy of StartedSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartedSessionCopyWith<StartedSession> get copyWith => _$StartedSessionCopyWithImpl<StartedSession>(this as StartedSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartedSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.workoutId, workoutId) || other.workoutId == workoutId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.ingestToken, ingestToken) || other.ingestToken == ingestToken));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,workoutId,startedAt,ingestToken);

@override
String toString() {
  return 'StartedSession(sessionId: $sessionId, workoutId: $workoutId, startedAt: $startedAt, ingestToken: $ingestToken)';
}


}

/// @nodoc
abstract mixin class $StartedSessionCopyWith<$Res>  {
  factory $StartedSessionCopyWith(StartedSession value, $Res Function(StartedSession) _then) = _$StartedSessionCopyWithImpl;
@useResult
$Res call({
 String sessionId, String workoutId, DateTime startedAt, String ingestToken
});




}
/// @nodoc
class _$StartedSessionCopyWithImpl<$Res>
    implements $StartedSessionCopyWith<$Res> {
  _$StartedSessionCopyWithImpl(this._self, this._then);

  final StartedSession _self;
  final $Res Function(StartedSession) _then;

/// Create a copy of StartedSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? workoutId = null,Object? startedAt = null,Object? ingestToken = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,workoutId: null == workoutId ? _self.workoutId : workoutId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,ingestToken: null == ingestToken ? _self.ingestToken : ingestToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StartedSession].
extension StartedSessionPatterns on StartedSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StartedSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StartedSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StartedSession value)  $default,){
final _that = this;
switch (_that) {
case _StartedSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StartedSession value)?  $default,){
final _that = this;
switch (_that) {
case _StartedSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String workoutId,  DateTime startedAt,  String ingestToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StartedSession() when $default != null:
return $default(_that.sessionId,_that.workoutId,_that.startedAt,_that.ingestToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String workoutId,  DateTime startedAt,  String ingestToken)  $default,) {final _that = this;
switch (_that) {
case _StartedSession():
return $default(_that.sessionId,_that.workoutId,_that.startedAt,_that.ingestToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String workoutId,  DateTime startedAt,  String ingestToken)?  $default,) {final _that = this;
switch (_that) {
case _StartedSession() when $default != null:
return $default(_that.sessionId,_that.workoutId,_that.startedAt,_that.ingestToken);case _:
  return null;

}
}

}

/// @nodoc


class _StartedSession implements StartedSession {
  const _StartedSession({required this.sessionId, required this.workoutId, required this.startedAt, required this.ingestToken});
  

@override final  String sessionId;
@override final  String workoutId;
@override final  DateTime startedAt;
/// Solo sirve para mandar posiciones a **esta** sesion y muere con ella.
/// Por eso puede viajar mil veces por entrenamiento y el JWT no.
@override final  String ingestToken;

/// Create a copy of StartedSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StartedSessionCopyWith<_StartedSession> get copyWith => __$StartedSessionCopyWithImpl<_StartedSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartedSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.workoutId, workoutId) || other.workoutId == workoutId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.ingestToken, ingestToken) || other.ingestToken == ingestToken));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,workoutId,startedAt,ingestToken);

@override
String toString() {
  return 'StartedSession(sessionId: $sessionId, workoutId: $workoutId, startedAt: $startedAt, ingestToken: $ingestToken)';
}


}

/// @nodoc
abstract mixin class _$StartedSessionCopyWith<$Res> implements $StartedSessionCopyWith<$Res> {
  factory _$StartedSessionCopyWith(_StartedSession value, $Res Function(_StartedSession) _then) = __$StartedSessionCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String workoutId, DateTime startedAt, String ingestToken
});




}
/// @nodoc
class __$StartedSessionCopyWithImpl<$Res>
    implements _$StartedSessionCopyWith<$Res> {
  __$StartedSessionCopyWithImpl(this._self, this._then);

  final _StartedSession _self;
  final $Res Function(_StartedSession) _then;

/// Create a copy of StartedSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? workoutId = null,Object? startedAt = null,Object? ingestToken = null,}) {
  return _then(_StartedSession(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,workoutId: null == workoutId ? _self.workoutId : workoutId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,ingestToken: null == ingestToken ? _self.ingestToken : ingestToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$IngestResult {

 int get accepted; int get duplicated; int get rejected;
/// Create a copy of IngestResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngestResultCopyWith<IngestResult> get copyWith => _$IngestResultCopyWithImpl<IngestResult>(this as IngestResult, _$identity);

  /// Serializes this IngestResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngestResult&&(identical(other.accepted, accepted) || other.accepted == accepted)&&(identical(other.duplicated, duplicated) || other.duplicated == duplicated)&&(identical(other.rejected, rejected) || other.rejected == rejected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accepted,duplicated,rejected);

@override
String toString() {
  return 'IngestResult(accepted: $accepted, duplicated: $duplicated, rejected: $rejected)';
}


}

/// @nodoc
abstract mixin class $IngestResultCopyWith<$Res>  {
  factory $IngestResultCopyWith(IngestResult value, $Res Function(IngestResult) _then) = _$IngestResultCopyWithImpl;
@useResult
$Res call({
 int accepted, int duplicated, int rejected
});




}
/// @nodoc
class _$IngestResultCopyWithImpl<$Res>
    implements $IngestResultCopyWith<$Res> {
  _$IngestResultCopyWithImpl(this._self, this._then);

  final IngestResult _self;
  final $Res Function(IngestResult) _then;

/// Create a copy of IngestResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accepted = null,Object? duplicated = null,Object? rejected = null,}) {
  return _then(_self.copyWith(
accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as int,duplicated: null == duplicated ? _self.duplicated : duplicated // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [IngestResult].
extension IngestResultPatterns on IngestResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IngestResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IngestResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IngestResult value)  $default,){
final _that = this;
switch (_that) {
case _IngestResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IngestResult value)?  $default,){
final _that = this;
switch (_that) {
case _IngestResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int accepted,  int duplicated,  int rejected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IngestResult() when $default != null:
return $default(_that.accepted,_that.duplicated,_that.rejected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int accepted,  int duplicated,  int rejected)  $default,) {final _that = this;
switch (_that) {
case _IngestResult():
return $default(_that.accepted,_that.duplicated,_that.rejected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int accepted,  int duplicated,  int rejected)?  $default,) {final _that = this;
switch (_that) {
case _IngestResult() when $default != null:
return $default(_that.accepted,_that.duplicated,_that.rejected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IngestResult implements IngestResult {
  const _IngestResult({this.accepted = 0, this.duplicated = 0, this.rejected = 0});
  factory _IngestResult.fromJson(Map<String, dynamic> json) => _$IngestResultFromJson(json);

@override@JsonKey() final  int accepted;
@override@JsonKey() final  int duplicated;
@override@JsonKey() final  int rejected;

/// Create a copy of IngestResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IngestResultCopyWith<_IngestResult> get copyWith => __$IngestResultCopyWithImpl<_IngestResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IngestResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IngestResult&&(identical(other.accepted, accepted) || other.accepted == accepted)&&(identical(other.duplicated, duplicated) || other.duplicated == duplicated)&&(identical(other.rejected, rejected) || other.rejected == rejected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accepted,duplicated,rejected);

@override
String toString() {
  return 'IngestResult(accepted: $accepted, duplicated: $duplicated, rejected: $rejected)';
}


}

/// @nodoc
abstract mixin class _$IngestResultCopyWith<$Res> implements $IngestResultCopyWith<$Res> {
  factory _$IngestResultCopyWith(_IngestResult value, $Res Function(_IngestResult) _then) = __$IngestResultCopyWithImpl;
@override @useResult
$Res call({
 int accepted, int duplicated, int rejected
});




}
/// @nodoc
class __$IngestResultCopyWithImpl<$Res>
    implements _$IngestResultCopyWith<$Res> {
  __$IngestResultCopyWithImpl(this._self, this._then);

  final _IngestResult _self;
  final $Res Function(_IngestResult) _then;

/// Create a copy of IngestResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accepted = null,Object? duplicated = null,Object? rejected = null,}) {
  return _then(_IngestResult(
accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as int,duplicated: null == duplicated ? _self.duplicated : duplicated // ignore: cast_nullable_to_non_nullable
as int,rejected: null == rejected ? _self.rejected : rejected // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
