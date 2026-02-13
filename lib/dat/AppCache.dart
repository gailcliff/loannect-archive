
import 'package:loannect/dat/UserInsights.dart';
import 'package:loannect/dat/UserProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';

//todo use flutter_secure_storage instead of shared preferences (API Level >= 18)

class AppCache {
  static late SharedPreferences _cache;

  static Future<void> init() async {
    _cache = await SharedPreferences.getInstance();
  }

  Object? get(String key) => _cache.get(key);

  static Future<void> cacheUser(UserProfile user) async {
    _cache.setString(K_USR, user.toString());
  }

  static Future<void> cacheUserInsights(UserInsights userInsights) async {
    _cache.setString(K_USR_INSIGHTS, userInsights.toString());
  }



  static UserProfile? loadUser() {
    String? cached = _cache.getString(K_USR);
    return cached != null ? UserProfile.fromJson(cached) : null;
  }

  static UserInsights? loadUserInsights() {
    String? cached = _cache.getString(K_USR_INSIGHTS);
    return cached != null ? UserInsights.fromJsonStr(cached) : null;
  }

  static const K_USR = "usr";
  static const K_USR_INSIGHTS = "usr_ins";
}