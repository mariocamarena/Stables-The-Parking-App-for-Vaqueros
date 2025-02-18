import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Settings Page",
        style: TextStyle(fontSize: 20, color: AppColors.utgrvOrange), // UTRGV Orange
      ),
    );
  }
}