

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:timeago/timeago.dart' as timeago;

part 'LoProposal.g.dart';

@JsonSerializable()
class LoProposal {
  int amount;
  String purpose;
  List<String> tags;
  int term;
  @JsonKey(name: 'repayment_plan') String repaymentPlan;
  Map destination;

  @JsonKey(name: 'id') int? proposalId; // id of this proposal
  @JsonKey(name: 'user') int? userId; // the borrower
  @JsonKey(name: 'user_profile', includeIfNull: false) Map<String, dynamic>? userProfile; // the borrower's info
  @JsonKey(
    name: 'proposed_on',
    fromJson: DataConverter.dateTimeFromJson,
    toJson: DataConverter.dateTimeToJson,
    includeIfNull: false
  ) DateTime? timeProposed;

  @JsonKey(includeFromJson: false, includeToJson: false) Color decorColor;
  @JsonKey(includeFromJson: false, includeToJson: false) Map? analytics;

  @JsonKey(includeFromJson: false, includeToJson: false) bool bookmarked = false;
  @JsonKey(includeFromJson: false, includeToJson: false) late int listPos;


  LoProposal(this.amount, this.purpose, this.tags, this.term, this.repaymentPlan, this.destination)
      : decorColor = _colors[_random.nextInt(_colors.length)] {
    //shuffle for more randomization
   _colors.shuffle();
  }



  factory LoProposal.fromJsonStr(String json) => _$LoProposalFromJson(jsonDecode(json));

  factory LoProposal.fromJson(Map<String, dynamic> json) => _$LoProposalFromJson(json);

  Map<String, dynamic> get dict => _$LoProposalToJson(this);

  String get amountStr => DataConverter.moneyToStr(amount);

  String get termStr => "$term ${term == 1 ? "month": "months"}";

  String? get timeAgoProposed => timeProposed == null ? null : timeago.format(timeProposed!);

  String get tagsStr {
    StringBuffer tags = StringBuffer();

    for(String tag in this.tags) {
      tags.write("#$tag ");
    }

    return tags.toString();
  }


  @override
  String toString() => jsonEncode(dict);



  static final _colors = [
    Colors.green, Colors.pink, Colors.blue,
    Colors.blueGrey, Colors.red, Colors.indigoAccent,
    // Colors.greenAccent,
    Colors.deepPurpleAccent, Colors.cyan, Colors.deepOrange,
    Colors.black, Colors.lightBlue,
    Colors.redAccent, Colors.grey, Colors.teal, Colors.indigo, Colors.purple,
    Colors.lightBlueAccent, Colors.orange, Colors.cyan, Colors.pinkAccent,
    Colors.deepPurple, Colors.lightGreen, Colors.amber, Colors.blueAccent
  ];
  static final _random = Random();



  Future<ApiResponse> loadAnalytics() async {
    final analytics = await Api.getInstance().getBorrowerAnalytics(this);

    if(analytics.exists) {
      print("Borrower analytics: ${analytics.data}");

      this.analytics = analytics.data as Map;
    }

    return analytics;
  }

  void bookmark() {
    bookmarked = true;
  }

  void unBookmark() {
    bookmarked = false;
  }
}