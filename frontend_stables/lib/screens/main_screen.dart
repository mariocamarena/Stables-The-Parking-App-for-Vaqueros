import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'rewards_screen.dart';
//import 'map_screen.dart';
import 'settings_screen.dart';
import 'account_screen.dart';
import '../utils/constants.dart';



class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});

  
  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
  
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const SensorInfoScreen(),
    const RewardsScreen(),
    //const MapScreen(),
    const SettingsScreen(),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.utgrvOrange,//UTRGV Orange
        title: const Text('Stables - UTRGV Parking App',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedIndex = 3; // Switch to Settings tab
              });
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:
            const Color.fromARGB(255, 241, 200, 157), // UTRGV Orange
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_box), label: 'Account'),
        ],
      ),
    );
  }
}