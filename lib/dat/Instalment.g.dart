// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Instalment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Instalment _$InstalmentFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['instalment_time'],
  );
  return Instalment(
    json['id'] as int,
    json['amount'] as int,
    json['source'] as Map<String, dynamic>,
    DataConverter.dateTimeFromJson(json['instalment_time'] as int?),
    json['confirmed'] as bool,
  );
}

Map<String, dynamic> _$InstalmentToJson(Instalment instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'amount': instance.amount,
    'source': instance.source,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'instalment_time', DataConverter.dateTimeToJson(instance.instalmentTime));
  val['confirmed'] = instance.confirmed;
  return val;
}
