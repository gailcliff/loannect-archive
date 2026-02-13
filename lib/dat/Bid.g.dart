// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Bid.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bid _$BidFromJson(Map<String, dynamic> json) => Bid(
      auctioneer: json['auctioneer'] as int,
      bidder: json['bidder'] as int,
      proposalId: json['proposal'] as int,
    )
      ..bidId = json['id'] as int?
      ..source = json['source'] as Map<String, dynamic>?
      ..bidStatus = json['bid_status'] as int?
      ..bidTime = DataConverter.dateTimeFromJson(json['bid_time'] as int?)
      ..closeTime = DataConverter.dateTimeFromJson(json['close_time'] as int?)
      ..proposal = json['bid_detail'] == null
          ? null
          : LoProposal.fromJson(json['bid_detail'] as Map<String, dynamic>)
      ..bidderInfo = json['bidder_info'] as Map<String, dynamic>?;

Map<String, dynamic> _$BidToJson(Bid instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.bidId);
  val['auctioneer'] = instance.auctioneer;
  val['bidder'] = instance.bidder;
  val['proposal'] = instance.proposalId;
  writeNotNull('source', instance.source);
  writeNotNull('bid_status', instance.bidStatus);
  writeNotNull('bid_time', DataConverter.dateTimeToJson(instance.bidTime));
  writeNotNull('close_time', DataConverter.dateTimeToJson(instance.closeTime));
  writeNotNull('bid_detail', Bid.proposalToDict(instance.proposal));
  writeNotNull('bidder_info', instance.bidderInfo);
  return val;
}
