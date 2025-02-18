import 'package:flutter/material.dart';
import '../utils/constants.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Welcome to Home!",
        style: TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
  }
}