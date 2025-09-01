// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShiftTemplateImpl _$$ShiftTemplateImplFromJson(Map<String, dynamic> json) =>
    _$ShiftTemplateImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String? ?? '#3B82F6',
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      description: json['description'] as String?,
      familyId: json['familyId'] as String?,
      createdAt: const DateTimeConverter().fromJson(json['createdAt']),
      updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$ShiftTemplateImplToJson(_$ShiftTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorHex': instance.colorHex,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'description': instance.description,
      'familyId': instance.familyId,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
    };
