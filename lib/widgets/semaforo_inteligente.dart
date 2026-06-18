import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class SemaforoInteligente extends StatefulWidget {
  final String eje;

  const SemaforoInteligente({super.key, required this.eje});

  @override
  State<SemaforoInteligente> createState() => _SemaforoInteligenteState();
}

class _SemaforoInteligenteState extends State<SemaforoInteligente> {
  late Future<double> _sumaFuture;

  @override
  void initState() {
    super.initState();
    _cargarSuma();
  }

  void _cargarSuma() {
    _sumaFuture = DatabaseHelper().obtenerSumaPorEje(widget.eje);
  }

  // Esto obliga al semáforo a recargarse cuando la pantalla principal se lo pide
  @override
  void didUpdateWidget(covariant SemaforoInteligente oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.key != widget.key) {
      setState(() {
        _cargarSuma();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _sumaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        double total = snapshot.data ?? 0.0;
        Color colorActivo;
        String mensaje;
        int nivel;

        double limiteVerde;
        double limiteAmarillo;

        switch (widget.eje.toLowerCase()) {
          case 'agua':
            limiteVerde = 100;
            limiteAmarillo = 300;
            break;
          case 'residuos':
            limiteVerde = 2;
            limiteAmarillo = 5;
            break;
          case 'alimentos':
          default:
            limiteVerde = 5;
            limiteAmarillo = 15;
            break;
        }

        if (total <= limiteVerde) {
          colorActivo = Colors.green;
          mensaje = "${widget.eje}: Excelente impacto";
          nivel = 0;
        } else if (total <= limiteAmarillo) {
          colorActivo = Colors.amber;
          mensaje = "${widget.eje}: Consumo moderado";
          nivel = 1;
        } else {
          colorActivo = Colors.red;
          mensaje = "${widget.eje}: Impacto elevado";
          nivel = 2;
        }

        return Card(
          elevation: 0,
          color: colorActivo.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 10),
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
      width: 25,
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
