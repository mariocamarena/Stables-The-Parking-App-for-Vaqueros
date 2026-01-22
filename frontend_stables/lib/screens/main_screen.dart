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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  LatLng? _mapTarget;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Navbar animation controller
  late AnimationController _navController;
  late Animation<double> _navAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    // Navbar indicator animation
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _navAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _navController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _navController.dispose();
    super.dispose();
  }

  void _onTabChanged(int idx) {
    if (idx == _selectedIndex) return;

    // Animate navbar indicator
    _navAnimation = Tween<double>(
      begin: _selectedIndex.toDouble(),
      end: idx.toDouble(),
    ).animate(
      CurvedAnimation(parent: _navController, curve: Curves.easeOutBack),
    );
    _navController.forward(from: 0.0);

    // Fade transition for content
    _fadeController.reverse().then((_) {
      setState(() => _selectedIndex = idx);
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userData?['userId'] as String? ?? '';
    final userName = widget.userData?['userName'] as String? ?? 'Student Name';
    final userEmail = widget.userData?['userEmail'] as String? ?? 'student@utrgv.edu';

    final screens = <Widget>[
      SensorInfoScreen(onLotTap: (lotId, center) {
        setState(() {
          _mapTarget = center;
        });
        _onTabChanged(1);
      }),
      MapScreen(target: _mapTarget, userId: userId, userName: userName),
      AccountScreen(userName: userName, userEmail: userEmail),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.utgrvOrange, Color(0xFFE67300)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.utgrvOrange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Balance for settings icon
                  Text(
                    'STABLES',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 22, color: Colors.white),
                      onPressed: () => _onTabChanged(2),
                      splashRadius: 22,
                      tooltip: 'Settings',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: _buildCustomNavBar(),
    );
  }

  Widget _buildCustomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final navWidth = constraints.maxWidth;
          final itemWidth = navWidth / 3;
          final indicatorWidth = itemWidth - 16;
          final padding = 8.0;

          return AnimatedBuilder(
            animation: _navAnimation,
            builder: (context, child) {
              // Use animation value for smooth interpolation
              final animatedPosition = padding + (_navAnimation.value * itemWidth);

              return Stack(
                children: [
                  // Sliding indicator pill - uses Transform for smooth animation
                  Positioned(
                    left: animatedPosition,
                    top: 8,
                    child: Container(
                      width: indicatorWidth,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.utgrvOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  // Nav items row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: 'Home',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.map_outlined,
                        selectedIcon: Icons.map_rounded,
                        label: 'Map',
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.person_outline_rounded,
                        selectedIcon: Icons.person_rounded,
                        label: 'Account',
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        behavior: HitTestBehavior.opaque,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 1.0 + (value * 0.15),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: Color.lerp(
                      Colors.grey[500],
                      AppColors.utgrvOrange,
                      value,
                    ),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: Color.lerp(
                      Colors.grey[500],
                      AppColors.utgrvOrange,
                      value,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
