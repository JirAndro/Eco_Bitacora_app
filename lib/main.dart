import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Solo importamos lo necesario para el arranque
import 'screens/home_screen.dart'; // Splash
import 'screens/home_menu_screen.dart'; // Menú principal

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(showHome: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool showHome;
  const MyApp({super.key, required this.showHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco-Bitácora CIIDIR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Si ya está logueado, va al Menú. Si no, al Splash.
      home: showHome ? const HomeMenuScreen() : const SplashScreen(),
    );
  }
}
