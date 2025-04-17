import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../config/secret.dart'; // :contentReference[oaicite:0]{index=0}
import '../utils/constants.dart';

/// Configuration for each lot is defined here.
/// For now we focus on Lot_A.
final Map<String, Map<String, dynamic>> lotConfigurations = {
  "Lot_A": {
    "boundingBox": [
      LatLng(26.303600, -98.170800), // Top left
      LatLng(26.303400, -98.170600)  // Bottom right
    ],
    "rows": 5,
    "cols": 10,
  },
};

/// Generates the polygon for a parking spot within a lot using a grid-based approach.
/// The spotIndex is 0-indexed (e.g., first spot is index 0 which becomes "Lot_A_Spot_1").
List<LatLng> generateSpotPolygon(String lotId, int spotIndex) {
  final config = lotConfigurations[lotId];
  if (config == null) {
    return [];
  }
  final List<LatLng> box = config["boundingBox"];
  final int rows = config["rows"];
  final int cols = config["cols"];

  // Calculate the height and width of the bounding box.
  final double totalLat = box[0].latitude - box[1].latitude; // vertical difference
  final double totalLng = box[1].longitude - box[0].longitude; // horizontal difference

  // Dimensions of each grid cell.
  final double cellLat = totalLat / rows;
  final double cellLng = totalLng / cols;

  // Determine the row and column for this spot.
  final int row = spotIndex ~/ cols;
  final int col = spotIndex % cols;

  // Calculate boundaries for the cell.
  final double cellTop = box[0].latitude - row * cellLat;
  final double cellLeft = box[0].longitude + col * cellLng;
  final double cellBottom = cellTop - cellLat;
  final double cellRight = cellLeft + cellLng;

  // Apply padding to better mimic real-world, non-perfect square spots.
  final double latPadding = cellLat * 0.1;
  final double lngPadding = cellLng * 0.1;

  return [
    LatLng(cellTop - latPadding, cellLeft + lngPadding),
    LatLng(cellTop - latPadding, cellRight - lngPadding),
    LatLng(cellBottom + latPadding, cellRight - lngPadding),
    LatLng(cellBottom + latPadding, cellLeft + lngPadding),
  ];
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // For centering the map on Lot_A.
  final LatLng _initialPosition = const LatLng(26.303500, -98.170700);
  Timer? _timer;
  List<dynamic> _parkingData = [];

  @override
  void initState() {
    super.initState();
    _fetchParkingData();
    // Refresh parking data every 5 seconds.
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchParkingData();
    });
  }

  Future<void> _fetchParkingData() async {
    try {
      final apiUrl = await Config.getApiUrl();
      final response = await http.get(Uri.parse('$apiUrl/parking'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Filter so that only Lot_A is used.
        setState(() {
          _parkingData = data.where((lot) => lot["lot_id"] == "Lot_A").toList();
        });
      } else {
        debugPrint('Error fetching parking data: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching parking data: $error');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Determines the color for an individual spot based on its status.
  Color _spotColor(String status) {
    if (status == "occupied") {
      return Colors.red.withOpacity(0.7);
    } else {
      return Colors.green.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Polygon> spotPolygons = [];

    // Process only Lot_A parking data.
    if (_parkingData.isNotEmpty) {
      final lot = _parkingData[0]; // Should be Lot_A.
      final String lotId = lot["lot_id"] as String;
      final List<dynamic> spots = lot["parking_status"] as List<dynamic>;
      for (int i = 0; i < spots.length; i++) {
        final spot = spots[i];
        final String status = spot["status"] as String;
        // Generate the polygon based on the spot index.
        final List<LatLng> spotPolygon = generateSpotPolygon(lotId, i);
        if (spotPolygon.isNotEmpty) {
          spotPolygons.add(
            Polygon(
              points: spotPolygon,
              borderColor: _spotColor(status).withOpacity(0.9),
              borderStrokeWidth: 1,
              color: _spotColor(status),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Spots Map"),
        backgroundColor: AppColors.utgrvOrange,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _initialPosition,
          initialZoom: 19.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
            additionalOptions: {
              'accessToken': Config.mapboxToken,
            },
          ),
          // Render overlays only for Lot_A.
          PolygonLayer(
            polygons: spotPolygons,
          ),
        ],
      ),
    );
  }
}
