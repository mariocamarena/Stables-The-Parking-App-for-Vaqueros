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

  //final LatLng _TL = const LatLng(26.303848, -98.171352);
  final LatLng _TL = const LatLng(26.303900, -98.171352);

  final LatLng _TR = const LatLng(26.303622, -98.169870);
  final LatLng _BR = const LatLng(26.302832, -98.170389);
  final LatLng _BL = const LatLng(26.302992, -98.171515);

 
  final int _rows = 12;
  final List<int> _spotsPerRow = [
    48, 47, 44, 43, 42, 41, 39, 38, 38, 38, 38, 36
  ];
  final double _rowSpacingFactor = 0.2;   
  final int _spacingGroups = 5;          


  final LatLngBounds _lotABounds = LatLngBounds(
    const LatLng(26.303320, -98.170920), // SW
    const LatLng(26.303680, -98.170480), // NE
  );

  final LatLng _initialCenter = const LatLng(26.303400, -98.170700);
  final MapController _mapController = MapController();
  late final MapOptions _mapOptions;

  Timer? _timer;
  List<dynamic> _spots = [];

  @override
  void initState() {
    super.initState();

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
    } catch (_) {}
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
    // how many spots in this row
    final int cols = _spotsPerRow[row];


    final double u0 =  col     / cols;
    final double u1 = (col+1) / cols;

    final double totalUnits = _rows + _spacingGroups * _rowSpacingFactor;
    final int g0 = min(row    ~/ 2, _spacingGroups);
    final int g1 = min((row+1)~/ 2, _spacingGroups);
    final double v0 = (row    + g0 * _rowSpacingFactor) / totalUnits;
    final double v1 = ((row+1)+ g1 * _rowSpacingFactor) / totalUnits;

    LatLng interp(double u, double v) {
      final lat = (1-u)*(1-v)*_TL.latitude
                 +   u *(1-v)*_TR.latitude
                 +   u *   v *_BR.latitude
                 + (1-u)*   v *_BL.latitude;
      final lng = (1-u)*(1-v)*_TL.longitude
                 +   u *(1-v)*_TR.longitude
                 +   u *   v *_BR.longitude
                 + (1-u)*   v *_BL.longitude;
      return LatLng(lat, lng);
    }

    final corners = [
      interp(u0, v0),
      interp(u1, v0),
      interp(u1, v1),
      interp(u0, v1),
    ];

    const padFactor = 0.02;
    final center = LatLng(
      corners.map((p) => p.latitude).reduce((a,b) => a+b) / 4,
      corners.map((p) => p.longitude).reduce((a,b) => a+b) / 4,
    );
    final padded = corners.map((pt) {
      final dLat = pt.latitude  - center.latitude;
      final dLng = pt.longitude - center.longitude;
      return LatLng(
        center.latitude  + dLat * (1 - padFactor),
        center.longitude + dLng * (1 - padFactor),
      );
    }).toList();
    return padded;
  }

  @override
  Widget build(BuildContext context) {
    // build your parking-spot polygons
    final polygons = <Polygon>[];
    int idx = 0;
    for (var r = 0; r < _rows; r++) {
      final rowCount = _spotsPerRow[r];
      for (var c = 0; c < rowCount; c++) {
        if (idx >= _spots.length) break;
        polygons.add(Polygon(
          points: _cellPolygon(r, c),
          color: _spotColor(idx),
          borderColor: _spotColor(idx).withOpacity(0.9),
          borderStrokeWidth: 1,
        ));
        idx++;
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
                        MarkerLayer(
                          markers: [
                            Marker(point: _TL, width: 8, height: 8, child: Container(color: Colors.blue)),
                            Marker(point: _TR, width: 8, height: 8, child: Container(color: Colors.blue)),
                            Marker(point: _BR, width: 8, height: 8, child: Container(color: Colors.blue)),
                            Marker(point: _BL, width: 8, height: 8, child: Container(color: Colors.blue)),
                          ],
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
