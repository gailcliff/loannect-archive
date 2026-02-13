
import 'package:intl/intl.dart';

void main() {
  // bar();

  var foo = [1,2,3,5,''];
  var bar = foo;
  bar = [3,3,6,3];
  print(foo);

  Map<String, dynamic> baz = {'bar': ''};
  print((baz['bar'] as String).trim().isNotEmpty);

  int? c;
  print("my int is $c");

  print("null.toString() == null: ${"null" == null})");

  final lar = [];
  print(lar.first);
}

void bar() {
  final date = DateTime.now();

  print(DateFormat('yyyy-MM-dd').format(date));


}