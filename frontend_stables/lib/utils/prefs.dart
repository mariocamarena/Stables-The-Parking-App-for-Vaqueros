import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static const _gpsKey = 'gps_enabled';

  static Future<bool> getGpsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gpsKey) ?? false;
  }

  static Future<void> setGpsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gpsKey, value);
  }
}