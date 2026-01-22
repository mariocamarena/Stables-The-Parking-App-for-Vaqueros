// home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _SensorInfoScreenState extends State<SensorInfoScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  final StreamController<List<dynamic>> _sensorDataController = StreamController();
  bool _initialLoadComplete = false;

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchSensorData();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchSensorData());
  }

  Future<void> _fetchSensorData() async {
    try {
      final sensorData = await SensorService.fetchSensorData();
      _sensorDataController.add(sensorData);
      if (!_initialLoadComplete) {
        _initialLoadComplete = true;
        _staggerController.forward();
      }
    } catch (e) {
      _sensorDataController.addError(e);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorDataController.close();
    _staggerController.dispose();
    super.dispose();
  }

  Color _capacityColor(double filled) {
    if (filled < 0.5) return const Color(0xFF4CAF50);
    if (filled < 0.8) return AppColors.utgrvOrange;
    return const Color(0xFFE53935);
  }

  String _capacityLabel(double filled) {
    if (filled < 0.5) return 'Low Traffic';
    if (filled < 0.8) return 'Moderate';
    return 'High Traffic';
  }

  IconData _capacityIcon(double filled) {
    if (filled < 0.5) return Icons.check_circle_outline;
    if (filled < 0.8) return Icons.remove_circle_outline;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: StreamBuilder<List<dynamic>>(
        stream: _sensorDataController.stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !_initialLoadComplete) {
            return _buildLoadingState();
          } else if (snap.hasError) {
            return _buildErrorState(snap.error.toString());
          } else if (snap.data == null || snap.data!.isEmpty) {
            return _buildEmptyState();
          }

          final data = snap.data!;
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: data.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return _buildHeader();
              }

              final lot = data[i - 1];
              final lotId = lot['lot_id'] as String;
              final total = lot['total_spots'] as int;
              final available = lot['available_spots'] as int;
              final filled = (total - available) / total;
              final color = _capacityColor(filled);

              // Staggered animation for each card
              final delay = (i - 1) * 0.15;
              final animation = CurvedAnimation(
                parent: _staggerController,
                curve: Interval(
                  delay.clamp(0.0, 0.7),
                  (delay + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              );

              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 20 * (1 - animation.value)),
                  child: Opacity(
                    opacity: animation.value,
                    child: child,
                  ),
                ),
                child: _buildLotCard(
                  lotId: lotId,
                  zoneType: lot['zone_type'] as String,
                  total: total,
                  available: available,
                  filled: filled,
                  color: color,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parking Overview',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a lot to view on map',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotCard({
    required String lotId,
    required String zoneType,
    required int total,
    required int available,
    required double filled,
    required Color color,
  }) {
    final lotName = lotId.replaceAll('_', ' ');
    final percent = (filled * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final center = _lotCenters[lotId] ?? _lotCenters['Lot_A']!;
            widget.onLotTap?.call(lotId, center);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lotName,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  zoneType,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _capacityIcon(filled),
                                size: 14,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _capacityLabel(filled),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    _buildStatItem(
                      label: 'Available',
                      value: available.toString(),
                      valueColor: const Color(0xFF4CAF50),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey[200],
                    ),
                    _buildStatItem(
                      label: 'Occupied',
                      value: (total - available).toString(),
                      valueColor: Colors.grey[600]!,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey[200],
                    ),
                    _buildStatItem(
                      label: 'Total',
                      value: total.toString(),
                      valueColor: Colors.grey[800]!,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: filled),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$percent% occupied',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.utgrvOrange),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading parking data...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load data',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No parking data available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
