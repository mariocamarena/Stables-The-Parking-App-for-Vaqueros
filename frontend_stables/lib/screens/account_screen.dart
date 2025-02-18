import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Account Screen",
        style: TextStyle(fontSize: 20, color: AppColors.utgrvOrange), // UTRGV Orange
      ),
    );
  }
}