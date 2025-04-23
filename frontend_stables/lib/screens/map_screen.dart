import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../config/secret.dart';
import '../utils/constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  //    Top-Left of Lot A
  final LatLng _gridTopLeft     = const LatLng(26.303848, -98.171352);
  //    Bottom-Right of Lot A
  final LatLng _gridBottomRight = const LatLng(26.302832, -98.170389);
  final int _rows = 12, _cols = 38;


  final LatLngBounds _lotABounds = LatLngBounds(
    // SW = bottom-left stall
    const LatLng(26.302992, -98.171515),
    // NE = top-right stall
    const LatLng(26.303622, -98.169870),
  );

  // 3) Rotation setup (unchanged)
  final double _rotationAngle = -0.1745; // ~ –10°
  late final LatLng _rotationCenter;

  // 4) Map init (unchanged)
  final LatLng _initialCenter = const LatLng(26.303400, -98.170700);
  final MapController _mapController = MapController();
  late final MapOptions _mapOptions;

  Timer? _timer;
  List<dynamic> _spots = [];

  @override
  void initState() {
    super.initState();

    _rotationCenter = LatLng(
      (_gridTopLeft.latitude + _gridBottomRight.latitude) / 2,
      (_gridTopLeft.longitude + _gridBottomRight.longitude) / 2,
    );

    _mapOptions = MapOptions(
      initialCenter: _initialCenter,
      initialZoom: 20.0,
      minZoom: 18.0,
      maxZoom: 21.0,
      cameraConstraint: CameraConstraint.contain(bounds: _lotABounds),
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
      ),
    );

    _fetchParkingData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchParkingData());
  }

  Future<void> _fetchParkingData() async {
    try {
      final apiUrl = await Config.getApiUrl();
      final resp   = await http.get(Uri.parse('$apiUrl/parking'));
      if (resp.statusCode == 200) {
        final all  = json.decode(resp.body) as List<dynamic>;
        final lotA = all.firstWhere((l) => l['lot_id']=='Lot_A');
        setState(() => _spots = lotA['parking_status'] as List<dynamic>);
      }
    } catch (_) {/* ignore */}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _spotColor(int idx) {
    final status = (_spots[idx]['status'] as String).toLowerCase();
    return status == 'available'
      ? Colors.green.withOpacity(0.7)
      : Colors.red.withOpacity(0.7);
  }

  List<LatLng> _cellPolygon(int row, int col) {
    final latSpan = _gridTopLeft.latitude   - _gridBottomRight.latitude;
    final lngSpan = _gridBottomRight.longitude - _gridTopLeft.longitude;
    final cellLat = latSpan / _rows;
    final cellLng = lngSpan / _cols;

    final north = _gridTopLeft.latitude   - row * cellLat;
    final south = north              - cellLat;
    final west  = _gridTopLeft.longitude + col * cellLng;
    final east  = west               + cellLng;
    final padLat = cellLat * 0.05, padLng = cellLng * 0.05;

    final corners = [
      LatLng(north - padLat, west  + padLng),
      LatLng(north - padLat, east  - padLng),
      LatLng(south + padLat, east  - padLng),
      LatLng(south + padLat, west  + padLng),
    ];

    final cosA = cos(_rotationAngle), sinA = sin(_rotationAngle);
    return corners.map((pt) {
      final dx = pt.longitude - _rotationCenter.longitude;
      final dy = pt.latitude  - _rotationCenter.latitude;
      final lng = dx * cosA - dy * sinA + _rotationCenter.longitude;
      final lat = dx * sinA + dy * cosA + _rotationCenter.latitude;
      return LatLng(lat, lng);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final polygons = <Polygon>[];
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final idx = r * _cols + c;
        if (idx >= _spots.length) break;
        polygons.add(Polygon(
          points: _cellPolygon(r, c),
          color: _spotColor(idx),
          borderColor: _spotColor(idx).withOpacity(0.9),
          borderStrokeWidth: 1,
        ));
      }
    }

    final latSpan = _lotABounds.northEast.latitude  - _lotABounds.southWest.latitude;
    final lngSpan = _lotABounds.northEast.longitude - _lotABounds.southWest.longitude;
    final aspectRatio = lngSpan / latSpan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Spots Map'),
        backgroundColor: AppColors.utgrvOrange,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'UTRGV Parking Lot A',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: _mapOptions,
                      children: [
                        TileLayer(
                          urlTemplate:
                            'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                          additionalOptions: {
                            'accessToken': Config.mapboxToken,
                          },
                        ),
                        PolygonLayer(polygons: polygons),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
