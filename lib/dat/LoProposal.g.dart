// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LoProposal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoProposal _$LoProposalFromJson(Map<String, dynamic> json) => LoProposal(
      json['amount'] as int,
      json['purpose'] as String,
      (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      json['term'] as int,
      json['repayment_plan'] as String,
      json['destination'] as Map<String, dynamic>,
    )
      ..proposalId = json['id'] as int?
      ..userId = json['user'] as int?
      ..userProfile = json['user_profile'] as Map<String, dynamic>?
      ..timeProposed =
          DataConverter.dateTimeFromJson(json['proposed_on'] as int?);

Map<String, dynamic> _$LoProposalToJson(LoProposal instance) {
  final val = <String, dynamic>{
    'amount': instance.amount,
    'purpose': instance.purpose,
    'tags': instance.tags,
    'term': instance.term,
    'repayment_plan': instance.repaymentPlan,
    'destination': instance.destination,
    'id': instance.proposalId,
    'user': instance.userId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('user_profile', instance.userProfile);
  writeNotNull(
      'proposed_on', DataConverter.dateTimeToJson(instance.timeProposed));
  return val;
}
