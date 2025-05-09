import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_connection.dart';
import '../utils/constants.dart';

/// simple mapping from lot IDs to center points
const Map<String, LatLng> _lotCenters = {
  'Lot_A': LatLng(26.303400, -98.170700), 
  'Lot_B': LatLng(26.308293, -98.175614),
  'Lot_C': LatLng(26.311297, -98.173968),
};

class SensorInfoScreen extends StatefulWidget {
  /// called when a lot tile is tapped
  final void Function(String lotId, LatLng center)? onLotTap;

  const SensorInfoScreen({Key? key, this.onLotTap}) : super(key: key);

  @override
  _SensorInfoScreenState createState() => _SensorInfoScreenState();
}

class _SensorInfoScreenState extends State<SensorInfoScreen> {
  Timer? _timer;
  final StreamController<List<dynamic>> _sensorDataController = StreamController();

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
    } catch (e) {
      _sensorDataController.addError(e);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorDataController.close();
    super.dispose();
  }

  Color _capacityColor(double filled) {
    if (filled < 0.5) return Colors.green;
    if (filled < 0.8) return AppColors.utgrvOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF9F9F9),
        child: StreamBuilder<List<dynamic>>(
          stream: _sensorDataController.stream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            } else if (!snap.hasData || snap.data!.isEmpty) {
              return const Center(child: Text('No data available'));
            }

            final data = snap.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: data.length,
              itemBuilder: (context, i) {
                final lot = data[i];
                final String lotId = lot['lot_id'];
                final int total     = lot['total_spots'];
                final int available = lot['available_spots'];
                final double filled = (total - available) / total;
                final percentText  = (filled * 100).toStringAsFixed(1) + '% Full';
                final color        = _capacityColor(filled);

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      // new: notify MainScreen
                      final center = _lotCenters[lotId] ?? _lotCenters['Lot_A']!;
                      widget.onLotTap?.call(lotId, center);
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
                                'Lot: $lotId',
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
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Total Spots: $total   |   Available Spots: $available',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 16),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: filled),
                            duration: const Duration(milliseconds: 600),
                            builder: (_, value, __) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    minHeight: 12,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation(color),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  percentText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
