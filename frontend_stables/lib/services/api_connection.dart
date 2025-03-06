import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secret.dart';

class SensorService {
  
  //static const String _sensorUrl = 'http://localhost:3000/parking';

  static Future<List<dynamic>> fetchSensorData() async {
    const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
    final sensorUrl = '$apiUrl/parking';
    final response = await http.get(Uri.parse(sensorUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load sensor data');
    }
  }
}

