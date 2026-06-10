import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_helper.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  String _ejeSeleccionado = 'Residuos';
  final List<String> _ejes = ['Agua', 'Alimentos', 'Residuos'];

  final List<Color> _coloresGrafica = [
    Colors.green.shade400,
    Colors.blue.shade400,
    Colors.orange.shade400,
    Colors.red.shade400,
    Colors.purple.shade400,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Análisis Gráfico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade900,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el Eje a analizar:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // --- SELECTOR DE EJE ---
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: _ejes
                    .map(
                      (eje) => ButtonSegment(
                        value: eje,
                        label: Text(eje, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                selected: {_ejeSeleccionado},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _ejeSeleccionado = newSelection.first;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // --- CONTENEDOR CON SCROLL PARA LAS GRÁFICAS ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _construirTarjetaPastel(),
                    const SizedBox(height: 20),
                    _construirTarjetaBarras(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // GRÁFICA 1: PASTEL (Distribución de categorías)
  // ==========================================
  Widget _construirTarjetaPastel() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<Map<String, double>>(
          future: DatabaseHelper().obtenerTotalesPorCategoria(_ejeSeleccionado),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Sin datos para gráfica de pastel')),
              );
            }

            final datos = snapshot.data!;
            return Column(
              children: [
                Text(
                  'Distribución Histórica ($_ejeSeleccionado)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _generarSeccionesPastel(datos),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _construirLeyendas(datos),
              ],
            );
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _generarSeccionesPastel(Map<String, double> datos) {
    List<PieChartSectionData> secciones = [];
    int index = 0;
    datos.forEach((categoria, total) {
      secciones.add(
        PieChartSectionData(
          color: _coloresGrafica[index % _coloresGrafica.length],
          value: total,
          title: total.toStringAsFixed(1),
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });
    return secciones;
  }

  Widget _construirLeyendas(Map<String, double> datos) {
    List<Widget> leyendas = [];
    int index = 0;
    datos.forEach((categoria, total) {
      leyendas.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _coloresGrafica[index % _coloresGrafica.length],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(categoria, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      );
      index++;
    });
    return Column(children: leyendas);
  }

  // ==========================================
  // GRÁFICA 2: BARRAS (Progreso de los últimos 7 días)
  // ==========================================
  Widget _construirTarjetaBarras() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<Map<String, double>>(
          future: DatabaseHelper().obtenerHistorialSemanal(_ejeSeleccionado),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final datosSemana = snapshot.data ?? {};

            final sumTotal = datosSemana.values.fold(
              0.0,
              (prev, val) => prev + val,
            );
            if (sumTotal == 0) {
              return const SizedBox(
                height: 250,
                child: Center(
                  child: Text('Sin registros en los últimos 7 días'),
                ),
              );
            }

            return Column(
              children: [
                Text(
                  'Progreso Semanal ($_ejeSeleccionado)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _obtenerMaximo(datosSemana) * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final fechas = datosSemana.keys.toList();
                              if (value.toInt() >= 0 &&
                                  value.toInt() < fechas.length) {
                                String dia = fechas[value.toInt()].substring(
                                  8,
                                  10,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    dia,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: _generarBarras(datosSemana),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Días del mes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _obtenerMaximo(Map<String, double> datos) {
    double max = 0;
    for (var val in datos.values) {
      if (val > max) max = val;
    }
    return max == 0 ? 10 : max;
  }

  List<BarChartGroupData> _generarBarras(Map<String, double> datos) {
    List<BarChartGroupData> barras = [];
    int x = 0;

    Color colorBarra = Colors.green;
    if (_ejeSeleccionado == 'Agua') colorBarra = Colors.blue;
    if (_ejeSeleccionado == 'Alimentos') colorBarra = Colors.orange;
    if (_ejeSeleccionado == 'Residuos') colorBarra = Colors.brown;

    datos.forEach((fecha, total) {
      barras.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: total,
              color: colorBarra,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      x++;
    });
    return barras;
  }
}
