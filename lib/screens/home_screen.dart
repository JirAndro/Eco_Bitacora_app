import 'package:flutter/material.dart';
import 'login_screen.dart';

//Pantalla inicio
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulamos una carga de 3 segundos y pasamos al Login
    Future.delayed(const Duration(seconds: 3), () {
      // VALIDACIÓN: Solo te manda a la pantalla del login si el widget sigue en pantalla
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'EcoBitácora CIIDIR',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
