
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:loannect/dat/LoProposal.dart';

part 'LoPreRequisites.g.dart';

@JsonSerializable()
class LoPreRequisites {
  bool verified;
  bool eligible;

  String? info;
  @JsonKey(name: "base_rate") double? baseRate;
  @JsonKey(name: "lo_tags") List<String>? loTags;
  Map<String, double>? instalments;

  @JsonKey(includeToJson: false, includeFromJson: false) int? userId;
  @JsonKey(includeToJson: false, includeFromJson: false) LoProposal? preset;

  LoPreRequisites(this.verified, this.eligible, this.info, this.baseRate, this.loTags, this.instalments, [this.preset]);

  factory LoPreRequisites.fromJsonStr(String json) => _$LoPreRequisitesFromJson(jsonDecode(json));

  factory LoPreRequisites.fromJson(Map<String, dynamic> json) => _$LoPreRequisitesFromJson(json);

  Map<String, dynamic> get dict => _$LoPreRequisitesToJson(this);

  @override
  String toString() => jsonEncode(dict);
}