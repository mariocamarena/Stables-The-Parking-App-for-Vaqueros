import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stables UTRGV Parking App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primarySeed, 
          primary: AppColors.primary, 
          secondary: AppColors.secondary, 
          surface: AppColors.surface,
          onPrimary: Colors.white, 
          onSecondary: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(title: "Stables Main Screen",),
    );
  }
}
