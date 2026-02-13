
import 'package:intl/intl.dart';

class DataConverter {
  static DateTime? dateTimeFromJson(int? millis) =>
      millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);

  static dateTimeToJson(DateTime? time) => time?.millisecondsSinceEpoch;

  static moneyToStr(num money) {
    return NumberFormat
      .currency(customPattern: "#,###", decimalDigits: 0)
      .format(money);
  }
}
