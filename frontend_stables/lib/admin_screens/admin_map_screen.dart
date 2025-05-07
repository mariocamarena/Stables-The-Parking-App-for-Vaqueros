
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AdminMapScreen extends StatelessWidget {
  const AdminMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Parking Overview'),
        backgroundColor: AppColors.utgrvOrange,
      ),
      body: Center(
        child: Text(
          'Parking data and analytics coming soon...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}