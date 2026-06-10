import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/registro_model.dart';
import '../services/database_helper.dart';

class RegistroHuertoScreen extends StatefulWidget {
  const RegistroHuertoScreen({super.key});

  @override
  State<RegistroHuertoScreen> createState() => _RegistroHuertoScreenState();
}

class _RegistroHuertoScreenState extends State<RegistroHuertoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Variables de estado específicas para huertos
  String _tipoCultivo = 'Hortalizas (Tomate, Lechuga...)';
  String _tecnica = 'Tradicional (Suelo)';
  String _estadoActual = 'Siembra';
  double _areaM2 = 0.0;
  final _obsController = TextEditingController();

  final List<String> _tiposCultivo = [
    'Hortalizas (Tomate, Lechuga...)',
    'Frutales',
    'Plantas Medicinales',
    'Aromáticas / Condimentos',
    'Milpa (Maíz, Frijol, Calabaza)',
  ];

  final List<String> _tecnicas = [
    'Tradicional (Suelo)',
    'Camas Biointensivas',
    'Hidroponía',
    'Macetas / Huerto Urbano',
    'Agroforestería',
  ];

  final List<String> _estados = [
    'Preparación de suelo',
    'Siembra',
    'Crecimiento / Mantenimiento',
    'Cosecha',
    'Descanso',
  ];

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // NOTA PARA EL FUTURO:
      // Si implementas esto, asegúrate de que tu semáforo y gráficas
      // estén preparados para leer el eje 'Huertos'.
      final categoriaCombinada = "$_tipoCultivo | $_tecnica";

      final nuevoRegistro = Registro(
        uuid: _uuid.v4(),
        fecha: DateTime.now().toString().split(' ')[0],
        timestamp: DateTime.now().toIso8601String(),
        eje: 'Huertos', // Nuevo Eje
        categoria: categoriaCombinada,
        subcategoria: _estadoActual,
        cantidad: _areaM2, // Aquí la cantidad representará los Metros Cuadrados
        observaciones: _obsController.text,
        sincronizado: 0,
      );

      try {
        await DatabaseHelper().insertarRegistro(nuevoRegistro);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registro de huerto guardado 🌱'),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Huertos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.green[400],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF9F9F9), // Fondo unificado
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // --- SECCIÓN: TIPO DE CULTIVO ---
              Text(
                'Tipo de Cultivo Principal:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoCultivo,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _tiposCultivo
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _tipoCultivo = val!),
              ),

              const SizedBox(height: 20),

              // --- SECCIÓN: TÉCNICA ---
              Text(
                'Técnica Agrícola:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tecnica,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _tecnicas
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _tecnica = val!),
              ),

              const SizedBox(height: 20),

              // --- SECCIÓN: ESTADO ACTUAL ---
              Text(
                'Estado Actual del Cultivo:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _estadoActual,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _estados
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _estadoActual = val!),
              ),

              const SizedBox(height: 25),

              // --- ÁREA ---
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Área estimada (Metros cuadrados)',
                  prefixIcon: Icon(Icons.square_foot, color: Colors.green[700]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Ingresa el área';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) {
                    return 'Ingresa un valor mayor a cero';
                  }
                  return null;
                },
                onSaved: (val) => _areaM2 = double.parse(val!),
              ),

              const SizedBox(height: 25),

              // --- OBSERVACIONES ---
              const Text(
                'Observaciones / Notas de campo:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _obsController,
                decoration: InputDecoration(
                  hintText: 'Ej: Se aplicó composta casera, presencia de plaga...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              // --- BOTÓN CÁMARA (Estilizado para Huertos) ---
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Módulo de cámara: Incremento 3'),
                      backgroundColor: Colors.green[700],
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('TOMAR FOTO DEL CULTIVO'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[800],
                  side: BorderSide(color: Colors.green[800]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 20),

              // --- BOTÓN GUARDAR ---
              ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'REGISTRAR PARCELA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}