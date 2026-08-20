// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IngestResult _$IngestResultFromJson(Map<String, dynamic> json) =>
    _IngestResult(
      accepted: (json['accepted'] as num?)?.toInt() ?? 0,
      duplicated: (json['duplicated'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$IngestResultToJson(_IngestResult instance) =>
    <String, dynamic>{
      'accepted': instance.accepted,
      'duplicated': instance.duplicated,
      'rejected': instance.rejected,
    };
