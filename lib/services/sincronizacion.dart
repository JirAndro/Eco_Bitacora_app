import 'dart:convert';
import 'package:http/http.dart' as http;
// Importamos SharedPreferences para leer la llave de seguridad
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class Sincronizacion {
  // Como ya está en producción, usamos una constante directa
  static const String apiUrl = 'https://eco-bitacora-backend.onrender.com/api';

  static Future<bool> sincronizarDatos(int userId) async {
    final dbHelper = DatabaseHelper();

    try {
      final pendientes = await dbHelper.obtenerRegistrosPendientes();

      if (pendientes.isEmpty) {
        print('Todo al día: No hay registros pendientes.');
        return true;
      }

      // --- 1. RECUPERAMOS EL TOKEN MAESTRO DE LA MEMORIA ---
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      List<Map<String, dynamic>> registrosArray = pendientes.map((r) {
        return {
          'uuid': r.uuid,
          'fecha': r.fecha,
          'timestamp': r.timestamp,
          'eje': r.eje,
          'categoria': r.categoria,
          'subcategoria': r.subcategoria,
          'cantidad': r.cantidad,
          'observaciones': r.observaciones,
          'latitud': r.latitud,
          'longitud': r.longitud,
        };
      }).toList();

      final payload = {'user_id': userId, 'registros': registrosArray};

      // --- 2. ENVIAMOS LA PETICIÓN CON EL CANDADO DE SEGURIDAD ---
      final response = await http
          .post(
            Uri.parse('$apiUrl/sincronizar'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              // Si el token existe, lo adjuntamos como salvoconducto
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      // 3. ANALIZAMOS LA RESPUESTA
      if (response.statusCode == 200) {
        List<String> uuidsEnviados = pendientes.map((r) => r.uuid).toList();
        await dbHelper.marcarComoSincronizados(uuidsEnviados);

        print('¡Éxito!: ${response.body}');
        return true;
      } else {
        // Si el token falló, Laravel responderá con un 401 Unauthorized aquí
        print('Error del servidor: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Falla de red o conexión rechazada: $e');
      return false;
    }
  }
}
