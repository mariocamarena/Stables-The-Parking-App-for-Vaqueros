import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_connection.dart';
import '../utils/constants.dart';

class AdminParkingOverview extends StatefulWidget {
  const AdminParkingOverview({Key? key}) : super(key: key);

  @override
  _AdminParkingOverviewState createState() => _AdminParkingOverviewState();
}

class _AdminParkingOverviewState extends State<AdminParkingOverview> {
  Timer? _timer;
  final StreamController<List<dynamic>> _sensorDataController = StreamController<List<dynamic>>();

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchSensorData());
  }

  void _fetchSensorData() async {
    try {
      final sensorData = await SensorService.fetchSensorData();
      _sensorDataController.add(sensorData);
    } catch (error) {
      _sensorDataController.addError(error);
    }
  }

  void _goToDashboard() {
    Navigator.pushNamed(context, '/admin-dashboard');
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
        title: const Text('Admin - Parking Overview'),
        backgroundColor: AppColors.utgrvOrange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _sensorDataController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final lot = data[index];
                final totalSpots = lot['total_spots'] as int;
                final availableSpots = lot['available_spots'] as int;
                final filledPct = (totalSpots - availableSpots) / totalSpots;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    onTap: _goToDashboard,
                    title: Text('Lot: ${lot['lot_id']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Zone: ${lot['zone_type']}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text('Total: $totalSpots | Available: $availableSpots'),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: filledPct,
                            minHeight: 12,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              filledPct < 0.5
                                  ? Colors.green
                                  : filledPct < 0.8
                                      ? AppColors.utgrvOrange
                                      : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${(filledPct * 100).toStringAsFixed(1)}% Full',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),

      // ← Add this bottom button
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _goToDashboard,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.utgrvOrange,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'View Parking Dashboard',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
