// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LoPreRequisites.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoPreRequisites _$LoPreRequisitesFromJson(Map<String, dynamic> json) =>
    LoPreRequisites(
      json['verified'] as bool,
      json['eligible'] as bool,
      json['info'] as String?,
      (json['base_rate'] as num?)?.toDouble(),
      (json['lo_tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      (json['instalments'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$LoPreRequisitesToJson(LoPreRequisites instance) =>
    <String, dynamic>{
      'verified': instance.verified,
      'eligible': instance.eligible,
      'info': instance.info,
      'base_rate': instance.baseRate,
      'lo_tags': instance.loTags,
      'instalments': instance.instalments,
    };
