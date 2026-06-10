import 'package:flutter/material.dart';
import 'package:eco_bitacora/services/database_helper.dart';
import 'package:eco_bitacora/services/motor_ecoalfabetizacion.dart';

class InformeQuincenalScreen extends StatelessWidget {
  const InformeQuincenalScreen({Key? key}) : super(key: key);

  // Función asíncrona que une la base de datos con el motor lógico
  Future<Map<String, dynamic>> _generarReporte() async {
    final dbHelper = DatabaseHelper();
    final registros = await dbHelper.obtenerRegistrosQuincenales();
    return MotorEcoalfabetizacion.procesarInformeQuincenal(registros);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informe Quincenal'),
        backgroundColor: Colors.green[700],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _generarReporte(),
        builder: (context, snapshot) {
          // 1. Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Manejo de errores
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al generar el informe: ${snapshot.error}'),
            );
          }

          final datos = snapshot.data!;

          // 3. Estado sin datos (No ha registrado nada en 15 días)
          if (datos['hayDatos'] == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      datos['mensaje'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      datos['tip'],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Estado con datos (Renderizado del Reporte)
          final totales = datos['totales'] as Map<String, double>;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Tarjeta principal: El Tip de Ecoalfabetización
              Card(
                elevation: 4,
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Colors.orange[700],
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Consejo Técnico',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1.5),
                      Text(
                        datos['tip'],
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Título de la sección de estadísticas
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 10.0),
                child: Text(
                  'Resumen de Impacto (Últimos 15 días)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Lista de totales generada dinámicamente
              ...totales.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey[100],
                      child: Text(
                        entry.key[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ), // Primera letra del eje
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      entry.value.toStringAsFixed(2), // Redondeo a 2 decimales
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
