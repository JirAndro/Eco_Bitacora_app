import 'package:flutter/material.dart';
import '../models/registro_model.dart';
import '../services/database_helper.dart';

class HistorialRegistrosScreen extends StatefulWidget {
  const HistorialRegistrosScreen({super.key});

  @override
  State<HistorialRegistrosScreen> createState() =>
      _HistorialRegistrosScreenState();
}

class _HistorialRegistrosScreenState extends State<HistorialRegistrosScreen> {
  // Función auxiliar para asignar Iconos y Colores por Eje
  Widget _getIconForEje(String eje) {
    switch (eje) {
      case 'Agua':
        return const Icon(Icons.water_drop, color: Colors.blue, size: 30);
      case 'Alimentos':
        return const Icon(Icons.restaurant, color: Colors.orange, size: 30);
      case 'Residuos':
        return const Icon(Icons.recycling, color: Colors.brown, size: 30);
      default:
        return const Icon(Icons.eco, color: Colors.green, size: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Bitácoras'),
        backgroundColor: Colors.green[200],
        actions: [
          // Botón para refrescar la lista manualmente
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<List<Registro>>(
        // RF-07: Módulo de Consulta Local
        future: DatabaseHelper().obtenerRegistros(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay registros guardados aún.'));
          }

          final registros = snapshot.data!;

          return ListView.builder(
            itemCount: registros.length,
            itemBuilder: (context, index) {
              final item = registros[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: _getIconForEje(item.eje),
                  title: Text(
                    '${item.eje}: ${item.categoria}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔢 Cantidad: ${item.cantidad}'),
                        Text('📅 Fecha: ${item.fecha}'),
                        if (item.observaciones.isNotEmpty)
                          Text(
                            '📝 Obs: ${item.observaciones}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        const SizedBox(height: 5),
                        Text(
                          '🆔 UUID: ${item.uuid.substring(0, 8)}...',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icono de estatus de sincronización (RF-09)
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.sincronizado == 1
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: item.sincronizado == 1
                            ? Colors.green
                            : Colors.orange,
                      ),
                      Text(
                        item.sincronizado == 1 ? 'Nube' : 'Local',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
