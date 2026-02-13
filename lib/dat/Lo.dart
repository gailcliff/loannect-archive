
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/dat/Instalment.dart';
import 'package:loannect/dat/LoProposal.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:timeago/timeago.dart' as timeago;

part 'Lo.g.dart';

@JsonSerializable(includeIfNull: false)
class Lo {
  int id;
  LoProposal proposal;
  Bid bid;
  int payback;
  @JsonKey(name: 'wk_instalment') double weeklyInstalment;
  @JsonKey(name: 'wk_rate') double weeklyRate;
  @JsonKey(
    name: 'initiated_on',
    fromJson: DataConverter.dateTimeFromJson,
    toJson: DataConverter.dateTimeToJson
  ) DateTime? initiatedOn;
  @JsonKey(
    name: 'finished_on'
  ) DateTime? finishedOn;

  @JsonKey(name: 'curr_time') int currTime;
  List<Instalment> instalments;
  @JsonKey(name: 'next_instalment') int nextInstalment;

  @JsonKey(name: 'fraction_complete') double fractionComplete;
  @JsonKey(name: 'percent_complete') double percentComplete;

  bool settled;

  Lo(this.id, this.proposal, this.bid, this.payback, this.weeklyInstalment,
    this.weeklyRate, this.initiatedOn, this.settled, this.instalments,
    this.nextInstalment, this.currTime, this.fractionComplete, this.percentComplete
  );


  factory Lo.fromJson(Map<String, dynamic> json) => _$LoFromJson(json);


  String get paybackStr => DataConverter.moneyToStr(payback);

  String get interestStr => DataConverter.moneyToStr(payback - proposal.amount);

  String get weeklyInstalmentStr => DataConverter.moneyToStr(weeklyInstalment);

  int get totalPaid {
    int total = 0;

    for(Instalment instalment in instalments) {
      total += instalment.amount;
    }

    return total;
  }

  int get totalDebt {
   int debt = payback - totalPaid;

   return debt < 0 ? 0 : debt;
  }

  String get initiatedTimeAgo => timeago.format(initiatedOn!);

  int get initiatedMillis => initiatedOn!.millisecondsSinceEpoch;
  int get numWeeksInTerm => proposal.term * 4;
  static const millisInAWeek = 86400000 * 7; // millis in a day * 7
  int get deadlineMillis => initiatedMillis + (millisInAWeek * numWeeksInTerm);



  String get nextInstalmentStr => DataConverter.moneyToStr(nextInstalment);

  DateTime get nextInstalmentDueDate {
    if(currTime > deadlineMillis) {
      //if current time has surpassed the deadline, it means the loan is overdue
      return DateTime.fromMillisecondsSinceEpoch(deadlineMillis);
    }

    int nextInstalmentMillis = initiatedMillis + millisInAWeek;

    for(int weeksPassed = 1; weeksPassed <= numWeeksInTerm; weeksPassed++) {
      int millisSinceInitiationToWeekC = initiatedOn!.millisecondsSinceEpoch + (millisInAWeek * weeksPassed);

      if(millisSinceInitiationToWeekC > currTime) {
        nextInstalmentMillis = millisSinceInitiationToWeekC;
        break;
      }
    }

    //todo if user has already finished payment for week before the time it is
    //due, shift the next due date to the following week, even before the current
    // week ends

    return DateTime.fromMillisecondsSinceEpoch(nextInstalmentMillis);
  }

  TimeOfDay get nextInstalmentDueTime {
    return TimeOfDay(hour: nextInstalmentDueDate.hour, minute: nextInstalmentDueDate.minute);
  }

  String get nextInstalmentDueStr => timeago.format(nextInstalmentDueDate, allowFromNow: true);

  Instalment? get latestInstalment {
    return instalments.isEmpty ? null : instalments[instalments.length - 1];
  }


  int get numConfirmedInstalments {
    int numConfirmed = 0;
    for(Instalment instalment in instalments) {
      if(instalment.confirmed) {
        numConfirmed += 1;
      }
    }
    return numConfirmed;
  }

  int get numUnconfirmedInstalments {
    return numInstalments - numConfirmedInstalments;
  }

  int get numInstalments => instalments.length;


  // check if loan is past its final deadline
  bool get loanDeadlinePassed => currTime > deadlineMillis;

  bool get hasDefaults => nextInstalment > weeklyInstalment;
}