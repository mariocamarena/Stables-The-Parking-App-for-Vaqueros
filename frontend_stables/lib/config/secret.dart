import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static const _apiUrlFromDefine = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const _mapboxTokenFromDefine = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: 'NO_TOKEN',
  );

  static Future<void> init() async {
    if (_apiUrlFromDefine == 'http://localhost:3000' ||
        _mapboxTokenFromDefine == 'NO_TOKEN') {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
      }
    }
  }

  static Future<String> getApiUrl() async {
    if (_apiUrlFromDefine != 'http://localhost:3000') {
      return _apiUrlFromDefine;
    }
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: ".env");
    }
    return dotenv.env['API_URL'] ?? 'http://localhost:3000';
  }

  static String get mapboxToken {
    if (_mapboxTokenFromDefine != 'NO_TOKEN') {
      return _mapboxTokenFromDefine;
    }
    return dotenv.env['MAPBOX_TOKEN'] ?? 'default_dev_token';
  }
}
