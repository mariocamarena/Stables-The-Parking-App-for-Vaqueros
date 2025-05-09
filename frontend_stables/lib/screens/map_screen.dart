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

  final int _rows = 12;
  final List<int> _spotsPerRow = [48,47,44,43,42,41,39,38,38,38,38,36];
  final double _rowSpacingFactor = 0.2;
  final int _spacingGroups = 5;

  final LatLngBounds _lotABounds = LatLngBounds(
    const LatLng(26.303320, -98.170920),
    const LatLng(26.303680, -98.170480),
  );

  final MapController _mapController = MapController();
  late final MapOptions _mapOptions;

  Timer? _timer;
  List<dynamic> _spots = [];

  @override
  void initState() {
    super.initState();

    _mapOptions = MapOptions(
      initialCenter: widget.target ?? _lotABounds.center,
      initialZoom: 19.0,
      minZoom: 18.0,
      maxZoom: 21.0,
      //cameraConstraint: CameraConstraint.contain(bounds: _lotABounds),
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

  void _handleTapOnMap(TapPosition tapPos, LatLng latlng) async {
    final polygons = _buildPolygons();
    final hit = polygons.indexWhere((poly) => _pointInPolygon(latlng, poly.points));
    if (hit < 0) return;

    final spotId = _spots[hit]['spot_id'];
    final status = (_spots[hit]['status'] as String).toLowerCase();

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
          headers: {'Content-Type':'application/json'},
          body: jsonEncode({
            'spot_id': _myClaimedSpotId!,
            'user_id': widget.userId,
          }),
        );
        final oldIdx = _spots.indexWhere((s) => s['spot_id'] == _myClaimedSpotId);
        if (oldIdx >= 0) {
          setState(() {
            _spots[oldIdx]['status'] = 'available';
          });
        }
      }

      final resp = await http.post(
        Uri.parse('$apiUrl/parking/claim'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({'spot_id': spotId, 'user_id': widget.userId}),
      );

      if (resp.statusCode == 200) {
        _myClaimedSpotId = spotId;
        final newIdx = _spots.indexWhere((s) => s['spot_id'] == spotId);
        if (newIdx >= 0) {
          setState(() {
            _spots[newIdx]['status'] = 'claimed';
          });
        }
        await _fetchParkingData();
      } else {
        final msg = json.decode(resp.body)['error'] ?? 'Unable to claim spot';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      return;
    }

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
        headers: {'Content-Type':'application/json'},
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

  Future<void> _fetchParkingData() async {
    try {
      final apiUrl = await Config.getApiUrl();
      final resp = await http.get(Uri.parse('$apiUrl/parking?user_id=${widget.userId}'));
      if (resp.statusCode == 200) {
        final all = json.decode(resp.body) as List<dynamic>;
        final lotA = all.firstWhere((l) => l['lot_id'] == 'Lot_A');
        final fresh = lotA['parking_status'] as List<dynamic>;

        setState(() {
          if (_myClaimedSpotId != null) {
            for (var s in fresh) {
              if (s['spot_id'] == _myClaimedSpotId) s['status'] = 'claimed';
            }
          }
          _spots = fresh;
        });
      }
    } catch (_) {}
  }

  Color _spotColor(int idx) {
    final s = (_spots[idx]['status'] as String).toLowerCase();
    if (s == 'available') return Colors.green.withOpacity(0.7);
    if (s == 'claimed')   return Colors.yellow.withOpacity(0.7);
    return Colors.red.withOpacity(0.7);
  }

  List<Polygon> _buildPolygons() {
    final polys = <Polygon>[];
    int idx = 0;
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _spotsPerRow[r]; c++) {
        if (idx >= _spots.length) break;
        polys.add(Polygon(
          points: _cellPolygon(r, c),
          color: _spotColor(idx),
          borderColor: _spotColor(idx).withOpacity(0.9),
          borderStrokeWidth: 1,
        ));
        idx++;
      }
    }
    return polys;
  }

  List<LatLng> _cellPolygon(int row, int col) {
    final cols  = _spotsPerRow[row];
    final u0    = col / cols, u1 = (col + 1) / cols;
    final units = _rows + _spacingGroups * _rowSpacingFactor;
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
    final spotPolygons = _buildPolygons();

    // compute aspect ratio from Lot A bounds
    final latSpan    = _lotABounds.northEast.latitude  - _lotABounds.southWest.latitude;
    final lngSpan    = _lotABounds.northEast.longitude - _lotABounds.southWest.longitude;
    final aspectRatio = lngSpan / latSpan;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            //child: Text('UTRGV Parking Lot A', style: Theme.of(context).textTheme.titleLarge),
          ),
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
                      // original MapTiler tiles
                        TileLayer(
                          urlTemplate:
                              'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                          additionalOptions: {'accessToken': Config.mapboxToken},
                        ),

                      
                      MarkerLayer(markers: [
                        // Lot A corners
                        Marker(point: _TL, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                        Marker(point: _TR, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                        Marker(point: _BR, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                        Marker(point: _BL, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),

                        // Lot B corners
                        Marker(point: _TLB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        Marker(point: _TRB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        Marker(point: _BRB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        Marker(point: _BLB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                      ]),

                      PolygonLayer(polygons: spotPolygons),

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
