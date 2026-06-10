import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Para detectar si es Web
import 'database_helper.dart';

class Sincronizacion {
  // Getter dinámico para la URL
  static String get apiUrl {
    if (kIsWeb) {
      // Si corres en Microsoft Edge
      return 'http://127.0.0.1:8000/api/sincronizar';
    } else {
      // REEMPLAZA ESTO CON LA IP QUE TE DIO EL IPCONFIG (Ej. 192.168.1.75)
      return 'http://192.168.13.63:8000/api/sincronizar';
    }
  }

  static Future<bool> sincronizarDatos(int userId) async {
    final dbHelper = DatabaseHelper();

    try {
      final pendientes = await dbHelper.obtenerRegistrosPendientes();

      if (pendientes.isEmpty) {
        print('Todo al día: No hay registros pendientes.');
        return true;
      }

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

      // Agregamos el TIMEOUT de 10 segundos para evitar que la app se congele
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<String> uuidsEnviados = pendientes.map((r) => r.uuid).toList();
        await dbHelper.marcarComoSincronizados(uuidsEnviados);

        print('¡Éxito!: ${response.body}');
        return true;
      } else {
        print('Error del servidor: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Si la IP está mal o el firewall bloquea, caerá aquí inmediatamente
      print('Falla de red o conexión rechazada: $e');
      return false;
    }
  }
}
