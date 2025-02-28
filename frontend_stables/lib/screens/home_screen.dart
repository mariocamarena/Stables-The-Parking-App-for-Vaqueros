import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_connection.dart';

class SensorInfoScreen extends StatefulWidget {
  const SensorInfoScreen({Key? key}) : super(key: key);

  @override
  _SensorInfoScreenState createState() => _SensorInfoScreenState();
}

class _SensorInfoScreenState extends State<SensorInfoScreen> {
  Timer? _timer;
  final StreamController<List<dynamic>> _sensorDataController = StreamController<List<dynamic>>();

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchSensorData();
    });
  }

  void _fetchSensorData() async {
    try {
      final sensorData = await SensorService.fetchSensorData();
      _sensorDataController.add(sensorData);
    } catch (error) {
      _sensorDataController.addError(error);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorDataController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sensor Info',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _sensorDataController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final sensorData = snapshot.data!;
            return ListView.builder(
              itemCount: sensorData.length,
              itemBuilder: (context, index) {
                final lot = sensorData[index];
                final int totalSpots = lot['total_spots'];
                final int availableSpots = lot['available_spots'];
                final double filledPercentage = (totalSpots - availableSpots) / totalSpots;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lot: ${lot['lot_id']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Zone: ${lot['zone_type']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Total Spots: $totalSpots\nAvailable Spots: $availableSpots',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: LinearProgressIndicator(
                          value: filledPercentage,
                          minHeight: 12,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(filledPercentage * 100).toStringAsFixed(1)}% Full',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
