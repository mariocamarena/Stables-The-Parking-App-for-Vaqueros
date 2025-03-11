import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'utils/constants.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/secret.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  //await dotenv.load(fileName: ".env");
  // const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
  // print('API_URL: $apiUrl');

  WidgetsFlutterBinding.ensureInitialized();
  await Config.init();

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(title: "Stables Main Screen"),
      },      

    );
  }
}
