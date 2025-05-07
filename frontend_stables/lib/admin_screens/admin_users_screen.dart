import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - User List'),
        backgroundColor: AppColors.utgrvOrange,
      ),
      body: Center(
        child: Text(
          'User management coming soon...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}