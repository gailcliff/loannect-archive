// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Lo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lo _$LoFromJson(Map<String, dynamic> json) => Lo(
      json['id'] as int,
      LoProposal.fromJson(json['proposal'] as Map<String, dynamic>),
      Bid.fromJson(json['bid'] as Map<String, dynamic>),
      json['payback'] as int,
      (json['wk_instalment'] as num).toDouble(),
      (json['wk_rate'] as num).toDouble(),
      DataConverter.dateTimeFromJson(json['initiated_on'] as int?),
      json['settled'] as bool,
      (json['instalments'] as List<dynamic>)
          .map((e) => Instalment.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['next_instalment'] as int,
      json['curr_time'] as int,
      (json['fraction_complete'] as num).toDouble(),
      (json['percent_complete'] as num).toDouble(),
    )..finishedOn = json['finished_on'] == null
        ? null
        : DateTime.parse(json['finished_on'] as String);

Map<String, dynamic> _$LoToJson(Lo instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'proposal': instance.proposal,
    'bid': instance.bid,
    'payback': instance.payback,
    'wk_instalment': instance.weeklyInstalment,
    'wk_rate': instance.weeklyRate,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'initiated_on', DataConverter.dateTimeToJson(instance.initiatedOn));
  writeNotNull('finished_on', instance.finishedOn?.toIso8601String());
  val['curr_time'] = instance.currTime;
  val['instalments'] = instance.instalments;
  val['next_instalment'] = instance.nextInstalment;
  val['fraction_complete'] = instance.fractionComplete;
  val['percent_complete'] = instance.percentComplete;
  val['settled'] = instance.settled;
  return val;
}
