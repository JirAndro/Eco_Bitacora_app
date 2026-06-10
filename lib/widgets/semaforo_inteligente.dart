import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class SemaforoInteligente extends StatelessWidget {
  final String eje; // Recibimos el eje como parámetro

  const SemaforoInteligente({super.key, required this.eje});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      // Pasamos el eje dinámico a la consulta
      future: DatabaseHelper().obtenerSumaPorEje(eje),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        double total = snapshot.data ?? 0.0;

        Color colorActivo;
        String mensaje;
        int nivel; // 0: Verde, 1: Ambar, 2: Rojo

        // LÍMITES DINÁMICOS SEGÚN EL EJE (Configurables para tu residencia)
        double limiteVerde;
        double limiteAmarillo;

        switch (eje.toLowerCase()) {
          case 'agua':
            limiteVerde = 100; // Ej: Menos de 100 Litros es Verde
            limiteAmarillo = 300;
            break;
          case 'residuos':
            limiteVerde = 2; // Ej: Menos de 2 Kg es Verde
            limiteAmarillo = 5;
            break;
          case 'alimentos':
          default:
            limiteVerde = 5; // Ej: Menos de 5 Kg/Porciones es Verde
            limiteAmarillo = 15;
            break;
        }

        // EVALUACIÓN
        if (total <= limiteVerde) {
          colorActivo = Colors.green;
          mensaje = "$eje: Excelente impacto";
          nivel = 0;
        } else if (total <= limiteAmarillo) {
          colorActivo = Colors.amber;
          mensaje = "$eje: Consumo moderado";
          nivel = 1;
        } else {
          colorActivo = Colors.red;
          mensaje = "$eje: Impacto elevado";
          nivel = 2;
        }

        return Card(
          elevation: 0,
          color: colorActivo.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(
            bottom: 10,
          ), // Margen para poder apilarlos
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _luz(Colors.green, nivel == 0),
                _luz(Colors.amber, nivel == 1),
                _luz(Colors.red, nivel == 2),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mensaje,
                        style: TextStyle(
                          color: colorActivo,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Total registrado: $total',
                        style: TextStyle(
                          color: colorActivo.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _luz(Color color, bool encendida) {
    return Container(
      width: 25, // Un poco más pequeños para que se vean elegantes
      height: 25,
      decoration: BoxDecoration(
        color: encendida ? color : color.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: encendida
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)]
            : [],
        border: Border.all(color: Colors.black12, width: 2),
      ),
    );
  }
}
