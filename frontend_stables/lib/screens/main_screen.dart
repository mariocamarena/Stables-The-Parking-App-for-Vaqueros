import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'home_screen.dart';
import 'rewards_screen.dart';
import 'map_screen.dart';
import 'account_screen.dart';
import '../utils/constants.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title, this.userData});
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
    
    final String userId    = widget.userData?['userId']   as String? ?? '';
    final String userName  = widget.userData?['userName'] as String? ?? 'Student Name';
    final String userEmail = widget.userData?['userEmail'] as String? ?? 'student@utrgv.edu';

    final List<Widget> _screens = [
      SensorInfoScreen(
        
        onLotTap: (String lotId, LatLng center) {
          setState(() {
            _mapTarget    = center;
            _selectedIndex = 2; 
          });
        },
      ),
      const RewardsScreen(),
      MapScreen(
        target:   _mapTarget,
        userId:   userId,
        userName: userName,
      ),
      AccountScreen(
        userName: userName,
        userEmail: userEmail,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.utgrvOrange,
                Color(0xFFFFA040),
              ],
            ),
          ),
        ),
        title: const Text(
          'Stables - UTRGV Parking App',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedIndex = 3; // Account tab
              });
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 241, 200, 157),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.account_box), label: 'Account'),
        ],
      ),
    );
  }
}
