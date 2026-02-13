// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserProfile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      json['full_name'] as String,
      json['country'] as String,
      json['phone'] as String,
      DateTime.parse(json['dob'] as String),
      UserProfile.genderFromJson(json['gender'] as String),
      email: json['email'] as String?,
      id: json['id'] as int?,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['full_name'] = instance.fullName;
  val['country'] = instance.country;
  val['phone'] = instance.phone;
  writeNotNull('dob', UserProfile.dateToJson(instance.dob));
  writeNotNull('gender', UserProfile.genderToJson(instance.gender));
  writeNotNull('email', instance.email);
  return val;
}
