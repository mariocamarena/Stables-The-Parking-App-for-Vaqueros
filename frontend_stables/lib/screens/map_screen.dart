// lib/map_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../config/secret.dart';
import '../utils/constants.dart';
import '../services/claim_manager.dart';

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

  // LOT C corners
  final LatLng _TLC = const LatLng(26.311594, -98.174191);
  final LatLng _TRC = const LatLng(26.311509, -98.173632);
  final LatLng _BRC = const LatLng(26.310747, -98.173772);
  final LatLng _BLC = const LatLng(26.310827, -98.174326);

  // grid definitions
  final int _rowsA = 12;
  final List<int> _spotsPerRowA = [48, 47, 44, 43, 42, 41, 39, 38, 38, 38, 38, 36];
  final int _rowsB = 6;
  final List<int> _spotsPerRowB = [25, 29, 29, 29, 29, 25];
  final int _rowsC = 10;
  final List<int> _spotsPerRowC = [18, 18, 18, 18, 18, 18, 20, 20, 20, 20];

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
  int _lenC = 0;
  int _lenB = 0;

  @override
  void initState() {
    super.initState();
    _mapOptions = MapOptions(
      initialCenter: widget.target ?? _lotABounds.center,
      initialZoom: 19.0,
      minZoom: 18.0,
      maxZoom: 21.0,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all |
               InteractiveFlag.doubleTapZoom |
               InteractiveFlag.drag |
               InteractiveFlag.pinchZoom,
      ),
      onTap: _handleTapOnMap,
    );
    _fetchParkingData();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchParkingData());
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
        final listC = (allLots.firstWhere((l) => l['lot_id'] == 'Lot_C')['parking_status'] as List<dynamic>);
        final listB = (allLots.firstWhere((l) => l['lot_id'] == 'Lot_B')['parking_status'] as List<dynamic>);
        final listA = (allLots.firstWhere((l) => l['lot_id'] == 'Lot_A')['parking_status'] as List<dynamic>);

        final combined = [...listC, ...listB, ...listA];
        // ensure our global claim is reflected
        if (ClaimManager.claimedSpotId != null) {
          for (var spot in combined) {
            if (spot['spot_id'] == ClaimManager.claimedSpotId) {
              spot['status'] = 'claimed';
            }
          }
        }

        setState(() {
          _lenC = listC.length;
          _lenB = listB.length;
          _spots = combined;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleTapOnMap(TapPosition tapPos, LatLng latlng) async {
    final polygons = [
      ..._buildPolygonsC(),
      ..._buildPolygonsB(),
      ..._buildPolygonsA(),
    ];
    final hit = polygons.indexWhere((poly) => _pointInPolygon(latlng, poly.points));
    if (hit < 0) return;

    final spot   = _spots[hit];
    final spotId = spot['spot_id'] as String;
    final status = (spot['status'] as String).toLowerCase();
    final apiUrl = await Config.getApiUrl();

    if (status == 'taken') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sorry ${widget.userName}, spot $spotId is already taken')),
      );
      return;
    }

    if (status == 'available') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => _buildClaimDialog(
          userName: widget.userName,
          spotId: spotId,
          isClaim: true,
        ),
      );
      if (confirm != true) return;

      if (ClaimManager.hasClaim && ClaimManager.claimedSpotId != spotId) {
        // unclaim previous
        await http.post(
          Uri.parse('$apiUrl/parking/unclaim'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'spot_id': ClaimManager.claimedSpotId, 'user_id': widget.userId}),
        );
        ClaimManager.clearClaim();
        await _fetchParkingData();
      }

      final respClaim = await http.post(
        Uri.parse('$apiUrl/parking/claim'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'spot_id': spotId, 'user_id': widget.userId}),
      );
      if (respClaim.statusCode == 200) {
        ClaimManager.setClaim(spotId);
        await _fetchParkingData();
      } else {
        final msg = json.decode(respClaim.body)['error'] ?? 'Unable to claim spot';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      return;
    }

    if (status == 'claimed' && ClaimManager.claimedSpotId == spotId) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => _buildClaimDialog(
          userName: widget.userName,
          spotId: spotId,
          isClaim: false,
        ),
      );
      if (confirm != true) return;

      final respUnclaim = await http.post(
        Uri.parse('$apiUrl/parking/unclaim'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'spot_id': spotId, 'user_id': widget.userId}),
      );
      if (respUnclaim.statusCode == 200) {
        ClaimManager.clearClaim();
        await _fetchParkingData();
      } else {
        final msg = json.decode(respUnclaim.body)['error'] ?? 'Unable to unclaim spot';
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

  List<Polygon> _buildPolygonsC() {
    final polys = <Polygon>[];
    int idx = 0;
    for (var r = 0; r < _rowsC; r++) {
      for (var c = 0; c < _spotsPerRowC[r]; c++) {
        if (idx >= _lenC) break;
        polys.add(Polygon(
          points: _cellPolygonC(r, c),
          color: _spotColor(idx),
          borderColor: _spotColor(idx).withOpacity(0.9),
          borderStrokeWidth: 1,
        ));
        idx++;
      }
    }
    return polys;
  }

  List<Polygon> _buildPolygonsB() {
    final polys = <Polygon>[];
    int idx = _lenC;
    for (var r = 0; r < _rowsB; r++) {
      for (var c = 0; c < _spotsPerRowB[r]; c++) {
        if (idx >= _lenC + _lenB) break;
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
    int idx = _lenC + _lenB;
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

  List<LatLng> _cellPolygonC(int row, int col) {
    final cols = _spotsPerRowC[row];
    final u0 = col / cols, u1 = (col + 1) / cols;
    final units = _rowsC + _spacingGroups * _rowSpacingFactor;
    final g0 = min(row ~/ 2, _spacingGroups);
    final g1 = min((row + 1) ~/ 2, _spacingGroups);
    final v0 = (row + g0 * _rowSpacingFactor) / units;
    final v1 = ((row + 1) + g1 * _rowSpacingFactor) / units;
    LatLng interp(double u, double v) {
      final lat = (1 - u) * (1 - v) * _TLC.latitude +
                  u * (1 - v) * _TRC.latitude +
                  u * v       * _BRC.latitude +
                 (1 - u) * v * _BLC.latitude;
      final lng = (1 - u) * (1 - v) * _TLC.longitude +
                  u * (1 - v) * _TRC.longitude +
                  u * v       * _BRC.longitude +
                 (1 - u) * v * _BLC.longitude;
      return LatLng(lat, lng);
    }
    final corners = [
      interp(u0, v0),
      interp(u1, v0),
      interp(u1, v1),
      interp(u0, v1),
    ];
    const pad = 0.02;
    final center = LatLng(
      corners.map((p) => p.latitude).reduce((a, b) => a + b) / 4,
      corners.map((p) => p.longitude).reduce((a, b) => a + b) / 4,
    );
    return corners.map((pt) => LatLng(
      center.latitude  + (pt.latitude  - center.latitude)  * (1 - pad),
      center.longitude + (pt.longitude - center.longitude) * (1 - pad),
    )).toList();
  }

  List<LatLng> _cellPolygonB(int row, int col) {
    final cols = _spotsPerRowB[row];
    final u0 = col / cols, u1 = (col + 1) / cols;
    final units = _rowsB + _spacingGroups * _rowSpacingFactor;
    final g0 = min(row ~/ 2, _spacingGroups);
    final g1 = min((row + 1) ~/ 2, _spacingGroups);
    final v0 = (row + g0 * _rowSpacingFactor) / units;
    final v1 = ((row + 1) + g1 * _rowSpacingFactor) / units;
    LatLng interp(double u, double v) {
      final lat = (1 - u) * (1 - v) * _TLB.latitude +
                  u * (1 - v) * _TRB.latitude +
                  u * v       * _BRB.latitude +
                 (1 - u) * v * _BLB.latitude;
      final lng = (1 - u) * (1 - v) * _TLB.longitude +
                  u * (1 - v) * _TRB.longitude +
                  u * v       * _BRB.longitude +
                 (1 - u) * v * _BLB.longitude;
      return LatLng(lat, lng);
    }
    final corners = [
      interp(u0, v0),
      interp(u1, v0),
      interp(u1, v1),
      interp(u0, v1),
    ];
    const pad = 0.02;
    final center = LatLng(
      corners.map((p) => p.latitude).reduce((a, b) => a + b) / 4,
      corners.map((p) => p.longitude).reduce((a, b) => a + b) / 4,
    );
    return corners.map((pt) => LatLng(
      center.latitude  + (pt.latitude  - center.latitude)  * (1 - pad),
      center.longitude + (pt.longitude - center.longitude) * (1 - pad),
    )).toList();
  }

  List<LatLng> _cellPolygonA(int row, int col) {
    final cols = _spotsPerRowA[row];
    final u0 = col / cols, u1 = (col + 1) / cols;
    final units = _rowsA + _spacingGroups * _rowSpacingFactor;
    final g0 = min(row ~/ 2, _spacingGroups);
    final g1 = min((row + 1) ~/ 2, _spacingGroups);
    final v0 = (row + g0 * _rowSpacingFactor) / units;
    final v1 = ((row + 1) + g1 * _rowSpacingFactor) / units;
    LatLng interp(double u, double v) {
      final lat = (1 - u) * (1 - v) * _TL.latitude +
                  u * (1 - v) * _TR.latitude +
                  u * v       * _BR.latitude +
                 (1 - u) * v * _BL.latitude;
      final lng = (1 - u) * (1 - v) * _TL.longitude +
                  u * (1 - v) * _TR.longitude +
                  u * v       * _BR.longitude +
                 (1 - u) * v * _BL.longitude;
      return LatLng(lat, lng);
    }
    final corners = [
      interp(u0, v0),
      interp(u1, v0),
      interp(u1, v1),
      interp(u0, v1),
    ];
    const pad = 0.02;
    final center = LatLng(
      corners.map((p) => p.latitude).reduce((a, b) => a + b) / 4,
      corners.map((p) => p.longitude).reduce((a, b) => a + b) / 4,
    );
    return corners.map((pt) => LatLng(
      center.latitude  + (pt.latitude  - center.latitude)  * (1 - pad),
      center.longitude + (pt.longitude - center.longitude) * (1 - pad),
    )).toList();
  }

  bool _pointInPolygon(LatLng point, List<LatLng> poly) {
    final x = point.longitude;
    final y = point.latitude;
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

  Widget _buildClaimDialog({
    required String userName,
    required String spotId,
    required bool isClaim,
  }) {
    final spotName = spotId.replaceAll('_', ' ');
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isClaim
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : AppColors.utgrvOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isClaim ? Icons.add_location_alt_rounded : Icons.location_off_rounded,
                color: isClaim ? const Color(0xFF4CAF50) : AppColors.utgrvOrange,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Hey $userName!',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            // Message
            Text(
              isClaim
                  ? 'Would you like to claim $spotName?'
                  : 'Release $spotName?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            if (isClaim)
              Text(
                'This will reserve the spot for you',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isClaim
                            ? const Color(0xFF4CAF50)
                            : AppColors.utgrvOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isClaim ? 'Claim' : 'Release',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lotC = _buildPolygonsC();
    final lotB = _buildPolygonsB();
    final lotA = _buildPolygonsA();

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: _mapOptions,
                  children: [
                    TileLayer(
                      urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                      additionalOptions: {'accessToken': Config.mapboxToken},
                    ),
                    MarkerLayer(markers: [
                      Marker(point: _TL,  width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                      Marker(point: _TR,  width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                      Marker(point: _BR,  width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                      Marker(point: _BL,  width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))),
                      Marker(point: _TLB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red,  shape: BoxShape.circle))),
                      Marker(point: _TRB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red,  shape: BoxShape.circle))),
                      Marker(point: _BRB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red,  shape: BoxShape.circle))),
                      Marker(point: _BLB, width: 8, height: 8, child: Container(decoration: const BoxDecoration(color: Colors.red,  shape: BoxShape.circle))),
                    ]),
                    PolygonLayer(polygons: lotC),
                    PolygonLayer(polygons: lotB),
                    PolygonLayer(polygons: lotA),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
