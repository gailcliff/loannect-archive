
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:loannect/dat/AppCache.dart';

part 'UserInsights.g.dart';

@JsonSerializable()
class UserInsights {
  @JsonKey(name: 'nat_id') String nationalId;
  String address;
  @JsonKey(name: 'occupation') Map<String, dynamic> occupationDetails;
  @JsonKey(name: 'other_jobs') String otherJobs;
  @JsonKey(name: 'income') Map<String, dynamic> incomeDetails;

  UserInsights(this.nationalId, this.address, this.occupationDetails,
      this.otherJobs, this.incomeDetails);


  factory UserInsights.fromJson(Map<String, dynamic> json) => _$UserInsightsFromJson(json);
  factory UserInsights.fromJsonStr(String json) => _$UserInsightsFromJson(jsonDecode(json));

  static UserInsights? fromCache() => AppCache.loadUserInsights();

  Map<String, dynamic> get dict => _$UserInsightsToJson(this);

  void cache() async {
    AppCache.cacheUserInsights(this);
  }

  @override
  String toString() => jsonEncode(dict); //todo always remember to use jsonEncode instead of dict.tostring()
}