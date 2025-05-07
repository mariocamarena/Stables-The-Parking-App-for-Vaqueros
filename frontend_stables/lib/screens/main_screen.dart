import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'rewards_screen.dart';
import 'map_screen.dart';
// import 'settings_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const SensorInfoScreen(),
      const RewardsScreen(),
      MapScreen(
      userId:   widget.userData?['userId']   as String, 
      userName: widget.userData?['userName'] as String,
      ),
      AccountScreen(
        userName: widget.userData?['userName'] ?? 'Student Name',
        userEmail: widget.userData?['userEmail'] ?? 'student@utrgv.edu',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        //backgroundColor: AppColors.utgrvOrange, // UTRGV Orange
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
        title: const Text('Stables - UTRGV Parking App', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedIndex = 3; 
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
        selectedItemColor: const Color.fromARGB(255, 241, 200, 157), // UTRGV Orange
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