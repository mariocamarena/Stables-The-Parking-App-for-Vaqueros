// main_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'home_screen.dart';
import 'map_screen.dart';
import 'account_screen.dart';
import '../utils/constants.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.title,
    this.userData,
  });

  final String title;
  final Map<String, dynamic>? userData;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  LatLng? _mapTarget;

  @override
  Widget build(BuildContext context) {
    final userId    = widget.userData?['userId']   as String? ?? '';
    final userName  = widget.userData?['userName'] as String? ?? 'Student Name';
    final userEmail = widget.userData?['userEmail']as String? ?? 'student@utrgv.edu';

    final screens = <Widget>[
      SensorInfoScreen(onLotTap: (lotId, center) {
        setState(() {
          _mapTarget      = center;
          _selectedIndex = 1;
        });
      }),
      MapScreen(target: _mapTarget, userId: userId, userName: userName),
      AccountScreen(userName: userName, userEmail: userEmail),
    ];

    return Scaffold(
      appBar: AppBar(
        // Height accommodates two‑line title
        toolbarHeight: 72,
        elevation: 2,
        backgroundColor: AppColors.utgrvOrange,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STABLES',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26),
                ],
              ),
            ),
            Text(
              'UTRGV Parking App',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => setState(() => _selectedIndex = 2),
            splashRadius: 20,
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: screens[_selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppColors.utgrvOrange.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        animationDuration: const Duration(milliseconds: 300),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
