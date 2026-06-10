import 'dart:convert';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;
import 'package:eco_bitacora/screens/home_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool isLogin = true;
  bool _procesando = false; // Indicador de carga para bloquear el botón

  // Getter de IP dinámica (Igual que en sincronizacion.dart)
  String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    return 'http://192.168.1.75:8000/api'; // <-- CAMBIA ESTO POR TU IP REAL
  }

  // Ahora guardamos la sesión y el ID real devuelto por la nube
  Future<void> _guardarSesion(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('user_id', userId);
  }

  void _procesarFormulario() async {
    String user = _userController.text.trim();
    String pass = _passController.text;

    if (user.isEmpty || pass.length < 4) {
      _mostrarError('Usuario o contraseña inválidos (mínimo 4 caracteres)');
      return;
    }

    setState(() => _procesando = true);
    FocusScope.of(context).unfocus(); // Ocultamos el teclado

    try {
      if (!isLogin) {
        // --- PETICIÓN DE REGISTRO ---
        if (pass != _confirmPassController.text) {
          _mostrarError('Las contraseñas no coinciden');
          setState(() => _procesando = false);
          return;
        }
        final response = await http
            .post(
              Uri.parse('$baseUrl/registro'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'usuario': user, 'password': pass}),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _guardarSesion(data['user_id']);
          _navegarAlHome();
        } else {
          final data = jsonDecode(response.body);
          _mostrarError(data['error'] ?? 'Error al registrar usuario');
        }
      } else {
        // --- PETICIÓN DE LOGIN ---
        final response = await http
            .post(
              Uri.parse('$baseUrl/login'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'usuario': user, 'password': pass}),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _guardarSesion(data['user_id']);
          _navegarAlHome();
        } else {
          _mostrarError('Credenciales inválidas o usuario no existe');
        }
      }
    } catch (e) {
      _mostrarError('No hay conexión con el servidor. Revisa tu internet.');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _navegarAlHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeMenuScreen()),
      (route) => false,
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.green),
              const SizedBox(height: 10),
              Text(
                isLogin ? 'Identificación de Alumno' : 'Registro de Alumno',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Usuario / Matrícula',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              if (!isLogin) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: _confirmPassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
              const SizedBox(height: 25),

              // Botón con indicador de carga
              ElevatedButton(
                onPressed: _procesando ? null : _procesarFormulario,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _procesando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        isLogin ? 'INICIAR SESIÓN' : 'REGISTRARSE',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: _procesando
                    ? null
                    : () {
                        setState(() {
                          isLogin = !isLogin;
                          _userController.clear();
                          _passController.clear();
                          _confirmPassController.clear();
                        });
                      },
                child: Text(
                  isLogin
                      ? '¿No tienes cuenta? Regístrate aquí'
                      : '¿Ya tienes cuenta? Inicia sesión',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
