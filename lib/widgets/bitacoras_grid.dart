import 'package:flutter/material.dart';
import '../screens/registro_agua.dart';
import '../screens/registro_alimentos.dart';
import '../screens/registro_residuo.dart';
import '../screens/historial_registro.dart';

class BitacorasGrid extends StatelessWidget {
  // 1. Agregamos la variable para recibir el aviso desde el Home
  final VoidCallback? onActualizar;

  // 2. Modificamos el constructor para aceptar esa variable
  const BitacorasGrid({super.key, this.onActualizar});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildRegistryCard(
          context,
          'AGUA',
          Icons.water_drop,
          Colors.blue.shade600,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistroAguaScreen(),
              ),
            ).then((seGuardo) {
              // 3. Atrapar el aviso: Si guardó algo, le avisamos al Home
              if (seGuardo == true && onActualizar != null) {
                onActualizar!();
              }
            });
          },
        ),
        _buildRegistryCard(
          context,
          'ALIMENTOS',
          Icons.restaurant,
          Colors.orange.shade700,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistroAlimentosScreen(),
              ),
            ).then((seGuardo) {
              if (seGuardo == true && onActualizar != null) {
                onActualizar!();
              }
            });
          },
        ),
        _buildRegistryCard(
          context,
          'RESIDUOS',
          Icons.recycling,
          Colors.brown.shade700,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistroResiduosScreen(),
              ),
            ).then((seGuardo) {
              if (seGuardo == true && onActualizar != null) {
                onActualizar!();
              }
            });
          },
        ),
        _buildRegistryCard(
          context,
          'HISTORIAL',
          Icons.history,
          Colors.blueGrey.shade700,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HistorialRegistrosScreen(),
            ),
          ), // Nota: El historial no necesita .then() porque ahí no se guarda nada nuevo
        ),
      ],
    );
  }

  Widget _buildRegistryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return AspectRatio(
      aspectRatio: 1 / 1,
      child: Card(
        elevation: 2,
        color: const Color(0xFFF8F9F8), // Un blanco grisáceo muy suave
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
