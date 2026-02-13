
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:loannect/dat/AppCache.dart';
import 'package:loannect/dat/gender.dart';

part 'UserProfile.g.dart';

@JsonSerializable(includeIfNull: false)
class UserProfile {
  int? id;
  @JsonKey(name: 'full_name') final String fullName;
  final String country;
  final String phone;
  @JsonKey(toJson: dateToJson) final DateTime dob;
  @JsonKey(toJson: genderToJson, fromJson: genderFromJson) final Gender gender;
  final String? email;

  UserProfile(
    this.fullName,
    this.country,
    this.phone,
    this.dob,
    this.gender,
    {
      this.email,
      this.id
    }
  );

  //object getters
  factory UserProfile.fromJson(String json) => _$UserProfileFromJson(jsonDecode(json));
  static UserProfile? fromCache() => AppCache.loadUser();


  //json converters
  static dateToJson(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  static genderToJson(Gender gender) => gender.name.substring(0, 1);
  static genderFromJson(String json) => json == 'M'
      ? Gender.Male
      : (json == 'F' ? Gender.Female : Gender.Other);


  Future<void> cache() async {
    await AppCache.cacheUser(this);
  }

  static bool get isUserRegistered => fromCache() != null;

  Map<String, dynamic> get dict => _$UserProfileToJson(this);

  @override
  String toString() => jsonEncode(dict);
}