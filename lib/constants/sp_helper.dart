import 'package:conextar/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpHelper {
  // Save Access Token:
  static Future<void> addOrUpdateAccessToken(String value) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(accessToken, value);
  }

  // Get Access Token:
  static Future<String?> getAccessToken() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString(accessToken);
    return token;
  }

  // Save Refresh Token:
  static Future<void> addOrUpdateRefreshToken(String value) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(refreshToken, value);
  }

  // Get Refresh Token:
  static Future<String?> getRefreshToken() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final token = sp.getString(refreshToken);
    return token;
  }

  static Future<bool> clearAll() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.clear();
  }
}
