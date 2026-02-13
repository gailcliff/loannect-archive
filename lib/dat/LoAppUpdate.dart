
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/dat/LoProposal.dart';

part 'LoAppUpdate.g.dart';

@JsonSerializable()
class LoAppUpdate {
  @JsonKey(name: 'has_pending') bool hasUpdates;
  @JsonKey(includeIfNull: false, readValue: getApplicationInfo) LoProposal? application;
  @JsonKey(includeIfNull: false, readValue: getApplicationInfo) List<Bid>? bids;


  LoAppUpdate(this.hasUpdates);

  factory LoAppUpdate.fromJson(Map<String, dynamic> json) => _$LoAppUpdateFromJson(json);

  Map<String, dynamic> get dict => _$LoAppUpdateToJson(this);

  static getApplicationInfo(Map data, String key) => data['pending']?[key];

  @override
  String toString() => jsonEncode(dict);
}