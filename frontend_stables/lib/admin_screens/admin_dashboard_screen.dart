// admin_dashboard_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/secret.dart';

class AdminDashboardFlutter extends StatefulWidget {
  const AdminDashboardFlutter({Key? key}) : super(key: key);

  @override
  _AdminDashboardFlutterState createState() => _AdminDashboardFlutterState();
}

class _AdminDashboardFlutterState extends State<AdminDashboardFlutter> {
  List<dynamic> lots = [];
  bool isLoading = true;
  String? errorMessage;
  String currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initialLoad();
    // Poll every second without hiding the UI
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshDashboardData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // First‐time load shows spinner
  Future<void> _initialLoad() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await _fetchAndParse();
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Subsequent polls update data only
  Future<void> _refreshDashboardData() async {
    try {
      await _fetchAndParse();
    } catch (e) {
      // Optionally log or show a toast, but don’t clear the UI
      debugPrint('Polling error: $e');
    }
  }

  // Shared fetch + parse logic
  Future<void> _fetchAndParse() async {
    final apiUrl = await Config.getApiUrl();
    final response = await http.get(Uri.parse('$apiUrl/parking'));

    if (response.statusCode != 200) {
      throw Exception('Status code ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    List<dynamic> newLots;
    String? newTime;

    if (decoded is Map<String, dynamic> && decoded.containsKey('lots')) {
      newLots = decoded['lots'] as List<dynamic>;
      newTime = decoded['current_time'] as String?;
    } else if (decoded is List) {
      newLots = decoded;
    } else {
      throw FormatException('Unexpected JSON format');
    }

    setState(() {
      lots = newLots;
      if (newTime != null) currentTime = newTime;
    });
  }

  Widget _buildLotGrid(List<dynamic> parkingStatus) {
    const spotsPerRow = 38;
    final rowCount = (parkingStatus.length / spotsPerRow).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        final start = rowIndex * spotsPerRow;
        final end = (start + spotsPerRow).clamp(0, parkingStatus.length);
        final rowSpots = parkingStatus.sublist(start, end);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: rowSpots.map((spot) {
              final map = spot as Map<String, dynamic>;
              final statusStr = (map['status'] as String).trim().toLowerCase();
              final isAvailable = statusStr == 'available';
              final label = (map['spot_id'] as String).split('_').last;

              return Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green : Colors.red,
                  border: Border.all(color: Colors.black12),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stables Parking Dashboard'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (currentTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Current Time: $currentTime',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ...lots.map((lot) {
            final lotMap = lot as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lotMap['lot_id']} (${lotMap['zone_type']})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Available: ${lotMap['available_spots']} / ${lotMap['total_spots']}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  _buildLotGrid(lotMap['parking_status'] as List<dynamic>),
                  const Divider(height: 30),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
