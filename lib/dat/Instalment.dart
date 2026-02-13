
import 'package:json_annotation/json_annotation.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:timeago/timeago.dart' as timeago;

part 'Instalment.g.dart';

@JsonSerializable(includeIfNull: false)
class Instalment {
  int id;
  int amount;
  Map source;
  @JsonKey(
    name: 'instalment_time',
    fromJson: DataConverter.dateTimeFromJson,
    toJson: DataConverter.dateTimeToJson,
    required: true
  ) DateTime? instalmentTime;
  bool confirmed;

  Instalment(this.id, this.amount, this.source, this.instalmentTime, this.confirmed);

  factory Instalment.fromJson(Map<String, dynamic> json) => _$InstalmentFromJson(json);


  String get amountStr => DataConverter.moneyToStr(amount);

  String get instalmentTimeAgo => timeago.format(instalmentTime!);
}