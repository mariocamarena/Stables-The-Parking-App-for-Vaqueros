import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static const _tokenFromDefine =
      String.fromEnvironment('MAPBOX_TOKEN', defaultValue: 'NO_TOKEN');

  static Future<void> init() async {

    if (_tokenFromDefine == 'NO_TOKEN') {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
      }
    }
  }


  static String get mapboxToken {
    if (_tokenFromDefine != 'NO_TOKEN') {
      return _tokenFromDefine;
    }
    return dotenv.env['MAPBOX_TOKEN'] ?? 'default_dev_token';
  }
}