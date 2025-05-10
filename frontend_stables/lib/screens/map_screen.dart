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
  final LatLng? target;
  final String userId;
  final String userName;

  const MapScreen({
    Key? key,
    this.target,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _myClaimedSpotId;

  // LOT A corners
  final LatLng _TL = const LatLng(26.303900, -98.171352);
  final LatLng _TR = const LatLng(26.303622, -98.169870);
  final LatLng _BR = const LatLng(26.302832, -98.170389);
  final LatLng _BL = const LatLng(26.302992, -98.171515);

  // LOT B corners
  final LatLng _TLB = const LatLng(26.308399, -98.176101);
  final LatLng _TRB = const LatLng(26.308442, -98.175178);
  final LatLng _BRB = const LatLng(26.308017, -98.175048);
  final LatLng _BLB = const LatLng(26.307971, -98.176042);

  // Grid definitions
  final int _rowsA = 12;
  final List<int> _spotsPerRowA = [48, 47, 44, 43, 42, 41, 39, 38, 38, 38, 38, 36];

  final int _rowsB = 6;
  final List<int> _spotsPerRowB = [25, 29, 29, 29, 29, 25];

  final double _rowSpacingFactor = 0.2;
  final int _spacingGroups = 5;

  final LatLngBounds _lotABounds = LatLngBounds(
    const LatLng(26.303320, -98.170920),
    const LatLng(26.303680, -98.170480),
  );

  final MapController _mapController = MapController();
  late final MapOptions _mapOptions;

  Timer? _timer;
  List<dynamic> _spots = []; // Combined B then A

  @override
  void initState() {
    super.initState();

    _mapOptions = MapOptions(
      initialCenter: widget.target ?? _lotABounds.center,
      initialZoom: 19.0,
      minZoom: 18.0,
      maxZoom: 21.0,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all
          | InteractiveFlag.doubleTapZoom
          | InteractiveFlag.drag
          | InteractiveFlag.pinchZoom,
      ),
      onTap: _handleTapOnMap,
    );

    _fetchParkingData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchParkingData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchParkingData() async {
    try {
      final apiUrl = await Config.getApiUrl();
      final resp = await http.get(Uri.parse('$apiUrl/parking?user_id=${widget.userId}'));
      if (resp.statusCode == 200) {
        final allLots = json.decode(resp.body) as List<dynamic>;
        final lotB = allLots.firstWhere((l) => l['lot_id'] == 'Lot_B');
        final lotA = allLots.firstWhere((l) => l['lot_id'] == 'Lot_A');

        final listB = lotB['parking_status'] as List<dynamic>;
        final listA = lotA['parking_status'] as List<dynamic>;

        final combined = [...listB, ...listA];
        if (_myClaimedSpotId != null) {
          for (var spot in combined) {
            if (spot['spot_id'] == _myClaimedSpotId) {
              spot['status'] = 'claimed';
            }
          }
        }

        setState(() => _spots = combined);
      }
    } catch (_) {}
  }

  void _handleTapOnMap(TapPosition tapPos, LatLng latlng) async {
    final polygonsB = _buildPolygonsB();
    final polygonsA = _buildPolygonsA();
    final allPolygons = [...polygonsB, ...polygonsA];

    final hit = allPolygons.indexWhere((poly) => _pointInPolygon(latlng, poly.points));
    if (hit < 0) return;

    final spot = _spots[hit];
    final spotId = spot['spot_id'] as String;
    final status = (spot['status'] as String).toLowerCase();

    if (status == 'taken') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sorry ${widget.userName}, spot $spotId is already taken')),
      );
      return;
    }

    if (status == 'available') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Hey ${widget.userName}!'),
          content: Text('Do you want to claim spot $spotId?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Yes')),
          ],
        ),
      );
      if (confirm != true) return;

      final apiUrl = await Config.getApiUrl();

      if (_myClaimedSpotId != null && _myClaimedSpotId != spotId) {
        await http.post(
          Uri.parse('$apiUrl/parking/unclaim'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'spot_id': _myClaimedSpotId, 'user_id': widget.userId}),
        );
        final oldIdx = _spots.indexWhere((s) => s['spot_id'] == _myClaimedSpotId);
        if (oldIdx >= 0) {
          setState(() => _spots[oldIdx]['status'] = 'available');
        }
      }

      final resp = await http.post(
        Uri.parse('$apiUrl/parking/claim'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'spot_id': spotId, 'user_id': widget.userId}),
      );

      if (resp.statusCode == 200) {
        _myClaimedSpotId = spotId;
        setState(() => _spots[hit]['status'] = 'claimed');
        await _fetchParkingData();
      } else {
        final msg = json.decode(resp.body)['error'] ?? 'Unable to claim spot';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      return;
    }

    // unclaim
    if (status == 'claimed' && _myClaimedSpotId == spotId) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Hey ${widget.userName}!'),
          content: Text('Unclaim spot $spotId?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Yes')),
          ],
        ),
      );
      if (confirm != true) return;

      final apiUrl = await Config.getApiUrl();
      final resp = await http.post(
        Uri.parse('$apiUrl/parking/unclaim'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'spot_id': spotId, 'user_id': widget.userId}),
      );
      if (resp.statusCode == 200) {
        _myClaimedSpotId = null;
        await _fetchParkingData();
      } else {
        final msg = json.decode(resp.body)['error'] ?? 'Unable to unclaim spot';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Color _spotColor(int idx) {
    final s = (_spots[idx]['status'] as String).toLowerCase();
    if (s == 'available') return Colors.green.withOpacity(0.7);
    if (s == 'claimed')   return Colors.yellow.withOpacity(0.7);
    return Colors.red.withOpacity(0.7);
  }

  List<Polygon> _buildPolygonsB() {
    final polys = <Polygon>[];
    int idx = 0;
    for (var r = 0; r < _rowsB; r++) {
      for (var c = 0; c < _spotsPerRowB[r]; c++) {
        if (idx >= _spots.length) break;
        polys.add(Polygon(
          points: _cellPolygonB(r, c),
          color: _spotColor(idx),
          borderColor: _spotColor(idx).withOpacity(0.9),
          borderStrokeWidth: 1,
        ));
        idx++;
      }
    }
    return polys;
  }

  List<Polygon> _buildPolygonsA() {
    final polys = <Polygon>[];
    int idx = _spotsPerRowB.reduce((a, b) => a + b); // skip B spots
    for (var r = 0; r < _rowsA; r++) {
      for (var c = 0; c < _spotsPerRowA[r]; c++) {
        if (idx >= _spots.length) break;
        polys.add(Polygon(
          points: _cellPolygonA(r, c),
          color: _spotColor(idx),
          borderColor: _spotColor(idx).withOpacity(0.9),
          borderStrokeWidth: 1,
        ));
        idx++;
      }
    }
    return polys;
  }

  // original Lot A interpolation
  List<LatLng> _cellPolygonA(int row, int col) {
    final cols  = _spotsPerRowA[row];
    final u0    = col / cols, u1 = (col + 1) / cols;
    final units = _rowsA + _spacingGroups * _rowSpacingFactor;
    final g0    = min(row ~/ 2, _spacingGroups);
    final g1    = min((row + 1) ~/ 2, _spacingGroups);
    final v0    = (row + g0 * _rowSpacingFactor) / units;
    final v1    = ((row + 1) + g1 * _rowSpacingFactor) / units;

    LatLng interp(double u, double v) {
      final lat = (1 - u) * (1 - v) * _TL.latitude +
          u * (1 - v) * _TR.latitude +
          u * v * _BR.latitude +
          (1 - u) * v * _BL.latitude;
      final lng = (1 - u) * (1 - v) * _TL.longitude +
          u * (1 - v) * _TR.longitude +
          u * v * _BR.longitude +
          (1 - u) * v * _BL.longitude;
      return LatLng(lat, lng);
    }

    final corners = [interp(u0, v0), interp(u1, v0), interp(u1, v1), interp(u0, v1)];
    const pad = 0.02;
    final center = LatLng(
      corners.map((p) => p.latitude).reduce((a, b) => a + b) / 4,
      corners.map((p) => p.longitude).reduce((a, b) => a + b) / 4,
    );
    return corners
        .map((pt) => LatLng(
              center.latitude + (pt.latitude - center.latitude) * (1 - pad),
              center.longitude + (pt.longitude - center.longitude) * (1 - pad),
            ))
        .toList();
  }

  // Lot B interpolation (same but with B corners)
  List<LatLng> _cellPolygonB(int row, int col) {
    final cols  = _spotsPerRowB[row];
    final u0    = col / cols, u1 = (col + 1) / cols;
    final units = _rowsB + _spacingGroups * _rowSpacingFactor;
    final g0    = min(row ~/ 2, _spacingGroups);
    final g1    = min((row + 1) ~/ 2, _spacingGroups);
    final v0    = (row + g0 * _rowSpacingFactor) / units;
    final v1    = ((row + 1) + g1 * _rowSpacingFactor) / units;

    LatLng interp(double u, double v) {
      final lat = (1 - u) * (1 - v) * _TLB.latitude +
          u * (1 - v) * _TRB.latitude +
          u * v * _BRB.latitude +
          (1 - u) * v * _BLB.latitude;
      final lng = (1 - u) * (1 - v) * _TLB.longitude +
          u * (1 - v) * _TRB.longitude +
          u * v * _BRB.longitude +
          (1 - u) * v * _BLB.longitude;
      return LatLng(lat, lng);
    }

    final corners = [interp(u0, v0), interp(u1, v0), interp(u1, v1), interp(u0, v1)];
    const pad = 0.02;
    final center = LatLng(
      corners.map((p) => p.latitude).reduce((a, b) => a + b) / 4,
      corners.map((p) => p.longitude).reduce((a, b) => a + b) / 4,
    );
    return corners
        .map((pt) => LatLng(
              center.latitude + (pt.latitude - center.latitude) * (1 - pad),
              center.longitude + (pt.longitude - center.longitude) * (1 - pad),
            ))
        .toList();
  }

  bool _pointInPolygon(LatLng point, List<LatLng> poly) {
    final x = point.longitude, y = point.latitude;
    var inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].longitude, yi = poly[i].latitude;
      final xj = poly[j].longitude, yj = poly[j].latitude;
      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  @override
  void didUpdateWidget(covariant MapScreen old) {
    super.didUpdateWidget(old);
    if (widget.target != old.target && widget.target != null) {
      // final currentZoom = _mapController.zoom;
      // _mapController.move(widget.target!, currentZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lotBPolygons = _buildPolygonsB();
    final lotAPolygons = _buildPolygonsA();

    // compute aspect ratio from Lot A bounds
    final latSpan    = _lotABounds.northEast.latitude  - _lotABounds.southWest.latitude;
    final lngSpan    = _lotABounds.northEast.longitude - _lotABounds.southWest.longitude;
    final aspectRatio = lngSpan / latSpan;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: _mapOptions,
                    children: [
                      // Base map tiles
                          TileLayer(
                          urlTemplate:
                              'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                          additionalOptions: {'accessToken': Config.mapboxToken},
                        ),

                      // Corner markers for both lots
                      MarkerLayer(markers: [
                        // Lot A
                        Marker(point: _TL, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.rectangle))),
                        Marker(point: _TR, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                        Marker(point: _BR, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                        Marker(point: _BL, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                        // Lot B
                        Marker(point: _TLB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        Marker(point: _TRB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        Marker(point: _BRB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        Marker(point: _BLB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),


                        // Lot C
                        Marker(point: _TLB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle))),
                        Marker(point: _TRB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle))),
                        Marker(point: _BRB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle))),
                        Marker(point: _BLB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle))),

                      ]),

                      // Lot B availability
                      PolygonLayer(polygons: lotBPolygons),

                      // Lot A availability
                      PolygonLayer(polygons: lotAPolygons),

                      // Decorative overlay
                      IgnorePointer(child: Container()),
                    ],
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
