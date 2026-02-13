
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:loannect/dat/LoProposal.dart';
import 'package:loannect/dat/UserProfile.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:timeago/timeago.dart' as timeago;

part 'Bid.g.dart';

@JsonSerializable(includeIfNull: false)
class Bid {
  @JsonKey(name: 'id') int? bidId;

  int auctioneer; // the borrower
  int bidder; // the lender
  @JsonKey(name: 'proposal') int proposalId;  // the id of the LoProposal
  Map? source;

  @JsonKey(name: 'bid_status') int? bidStatus;
  @JsonKey(
    name: 'bid_time',
    fromJson: DataConverter.dateTimeFromJson,
    toJson: DataConverter.dateTimeToJson,
  ) DateTime? bidTime;

  @JsonKey(
      name: 'close_time',
      fromJson: DataConverter.dateTimeFromJson,
      toJson: DataConverter.dateTimeToJson,
  ) DateTime? closeTime;

  @JsonKey(name: 'bid_detail', includeIfNull: false, toJson: proposalToDict) LoProposal? proposal;
  @JsonKey(name: 'bidder_info') Map? bidderInfo;


  Bid({required this.auctioneer, required this.bidder, required this.proposalId});

  Bid.fromProposal(LoProposal proposal)
  : this(auctioneer: proposal.userId!, bidder: UserProfile.fromCache()!.id!, proposalId: proposal.proposalId!);

  factory Bid.fromJson(Map<String, dynamic> json) => _$BidFromJson(json);


  bool get unsealed => bidStatus == 0;

  bool get sealed => bidStatus == 1;

  bool get cancelled => bidStatus == -1;


  String? get bidTimeAgo => bidTime == null ? null : timeago.format(bidTime!);

  String? get closeTimeAgo => closeTime == null ? null : timeago.format(closeTime!);

  Map<String, dynamic> get dict => _$BidToJson(this);

  static proposalToDict(LoProposal? loProposal) => loProposal?.dict;

  void seal() {
    bidStatus = 1;
  }

  @override
  String toString() => jsonEncode(dict);

}