// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserInsights.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInsights _$UserInsightsFromJson(Map<String, dynamic> json) => UserInsights(
      json['nat_id'] as String,
      json['address'] as String,
      json['occupation'] as Map<String, dynamic>,
      json['other_jobs'] as String,
      json['income'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$UserInsightsToJson(UserInsights instance) =>
    <String, dynamic>{
      'nat_id': instance.nationalId,
      'address': instance.address,
      'occupation': instance.occupationDetails,
      'other_jobs': instance.otherJobs,
      'income': instance.incomeDetails,
    };
