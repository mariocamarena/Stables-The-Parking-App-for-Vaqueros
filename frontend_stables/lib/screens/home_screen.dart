import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_connection.dart';
import '../utils/constants.dart';

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

  Color _capacityColor(double filledPercentage) {
    if (filledPercentage < 0.5) {
      return Colors.green;
    } else if (filledPercentage < 0.8) {
      return AppColors.utgrvOrange; 
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   elevation: 0,
      //   flexibleSpace: Container(
      //     decoration: const BoxDecoration(
      //       gradient: LinearGradient(
      //         begin: Alignment.topCenter,
      //         end: Alignment.bottomCenter,
      //         colors: [
      //           AppColors.utgrvOrange, 
      //           Color(0xFFFFA040), 
      //         ],
      //       ),
      //     ),
      //   ),
      //   title: const Text('Sensor Info', style: TextStyle(color: Colors.white, fontSize: 18)),
      //   centerTitle: true,
      // ),
      

    
      body: Container(
        color: const Color(0xFFF9F9F9),
        child: StreamBuilder<List<dynamic>>(
          stream: _sensorDataController.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final sensorData = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: sensorData.length,
                itemBuilder: (context, index) {
                  final lot = sensorData[index];
                  final int totalSpots = lot['total_spots'];
                  final int availableSpots = lot['available_spots'];
                  final double filledPercentage = (totalSpots - availableSpots) / totalSpots;
                  final double displayPercentage = filledPercentage * 100;

                  final capacityColor = _capacityColor(filledPercentage);

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Lot: ${lot['lot_id']}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Zone: ${lot['zone_type']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Total Spots: $totalSpots   |   Available Spots: $availableSpots',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: filledPercentage),
                              duration: const Duration(milliseconds: 600),
                              builder: (context, value, child) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: LinearProgressIndicator(
                                        value: value,
                                        minHeight: 12,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(capacityColor),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${displayPercentage.toStringAsFixed(1)}% Full',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: capacityColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
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
      ),
    );
  }
}
