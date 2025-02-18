import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Rewards Page",
        style: TextStyle(fontSize: 20, color: AppColors.utgrvOrange), // UTRGV Orange
      ),
    );
  }
}