import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importamos los widgets, pantallas y servicios
import '../widgets/bitacoras_grid.dart';
import '../widgets/semaforo_inteligente.dart';
import 'login_screen.dart';
import 'estadisticas_screen.dart';
import 'informe_screen.dart';
import '../services/sincronizacion.dart';

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  String _nombreUsuario = 'Usuario';

  // Llave maestra para forzar la recarga de los semáforos
  Key _semaforosKey = UniqueKey();

  final List<String> _consejosEcologicos = [
    'Reduce el consumo de plásticos de un solo uso en la cafetería.',
    'No tires residuos sólidos al WC; utiliza el bote de basura.',
    'Apaga las luces de los salones si no se están utilizando.',
    'Reporta fugas de agua en los baños del CIIDIR de inmediato.',
    'Utiliza hojas de papel por ambos lados para tus apuntes.',
    'Prefiere el uso de escaleras en lugar del elevador para ahorrar energía.',
    'Separa tus residuos orgánicos para el área de composta.',
  ];

  late String _consejoDelDia;

  @override
  void initState() {
    super.initState();
    _consejoDelDia =
        _consejosEcologicos[Random().nextInt(_consejosEcologicos.length)];
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreUsuario = prefs.getString('userName') ?? 'Usuario';
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // Limpiamos toda la memoria de sesión para mayor seguridad
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // Método que recarga los datos cuando el usuario desliza hacia abajo o regresa de registrar
  Future<void> _recargarPantalla() async {
    setState(() {
      // Al cambiar la llave, Flutter destruye los semáforos viejos
      // y crea unos nuevos, obligándolos a consultar la base de datos.
      _semaforosKey = UniqueKey();
      _consejoDelDia =
          _consejosEcologicos[Random().nextInt(_consejosEcologicos.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Bienvenido, $_nombreUsuario',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.blueAccent),
            tooltip: 'Sincronizar a la Nube',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronizando datos con el servidor...'),
                ),
              );

              final prefs = await SharedPreferences.getInstance();
              int userId = prefs.getInt('user_id') ?? 1;

              bool exito = await Sincronizacion.sincronizarDatos(userId);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    exito
                        ? '¡Sincronización exitosa!'
                        : 'Error de conexión. Intenta más tarde.',
                  ),
                  backgroundColor: exito ? Colors.green : Colors.red,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _recargarPantalla,
        color: Colors.green,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Eco-Bitácora CIIDIR',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                'Resumen del día',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildInfoCard(
                'CONSEJO DEL DÍA',
                _consejoDelDia,
                Icons.lightbulb_outline,
                Colors.amber.shade100,
              ),
              const SizedBox(height: 25),

              const Text(
                'BITÁCORAS DE REGISTRO',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 15),

              // --- ¡AQUÍ ESTÁ EL CAMBIO CLAVE! ---
              // Le quitamos el "const" y le inyectamos la función _recargarPantalla
              BitacorasGrid(onActualizar: _recargarPantalla),

              const SizedBox(height: 30),

              _buildBotonEstadisticas(context),

              const SizedBox(height: 15),
              _buildBotonInformeQuincenal(context),

              const SizedBox(height: 30),

              const Text(
                'ESTADO AMBIENTAL POR EJE',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              KeyedSubtree(
                key: _semaforosKey,
                child: const Column(
                  children: [
                    SemaforoInteligente(eje: 'Agua'),
                    SemaforoInteligente(eje: 'Alimentos'),
                    SemaforoInteligente(eje: 'Residuos'),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade800),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonEstadisticas(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EstadisticasScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Análisis Gráfico',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ver tendencias y reportes',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonInformeQuincenal(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.deepOrange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InformeQuincenalScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ecoalfabetización',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tu informe quincenal interactivo',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
