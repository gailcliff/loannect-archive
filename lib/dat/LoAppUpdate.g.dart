// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LoAppUpdate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoAppUpdate _$LoAppUpdateFromJson(Map<String, dynamic> json) => LoAppUpdate(
      json['has_pending'] as bool,
    )
      ..application =
          LoAppUpdate.getApplicationInfo(json, 'application') == null
              ? null
              : LoProposal.fromJson(
                  LoAppUpdate.getApplicationInfo(json, 'application')
                      as Map<String, dynamic>)
      ..bids = (LoAppUpdate.getApplicationInfo(json, 'bids') as List<dynamic>?)
          ?.map((e) => Bid.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$LoAppUpdateToJson(LoAppUpdate instance) {
  final val = <String, dynamic>{
    'has_pending': instance.hasUpdates,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('application', instance.application);
  writeNotNull('bids', instance.bids);
  return val;
}
