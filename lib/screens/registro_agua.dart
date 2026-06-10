import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/registro_model.dart';
import '../services/database_helper.dart';

class RegistroAguaScreen extends StatefulWidget {
  const RegistroAguaScreen({super.key});

  @override
  _RegistroAguaScreenState createState() => _RegistroAguaScreenState();
}

class _RegistroAguaScreenState extends State<RegistroAguaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  String _fuenteSeleccionada = 'Red pública';
  String _usoSeleccionado = 'Bebida / Sed';
  double _cantidad = 0.0;
  final _obsController = TextEditingController();

  XFile? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();

  // Bandera de carga para el botón unificado
  bool _procesandoGuardado = false;

  final List<String> _fuentes = [
    'Red pública',
    'Pozo',
    'Manantial',
    'Garrafón',
    'Lluvia',
  ];
  final List<String> _usos = [
    'Bebida / Sed',
    'Higiene',
    'Riego de huerto',
    'Limpieza',
  ];

  void _mostrarOpcionesDeImagen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Evidencia del Uso de Agua',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tomar foto con la cámara'),
                onTap: () {
                  Navigator.of(context).pop();
                  _procesarImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _procesarImagen(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _procesarImagen(ImageSource fuente) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: fuente,
        imageQuality: 70,
      );
      if (foto != null) setState(() => _imagenSeleccionada = foto);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // --- NUEVA LÓGICA UNIFICADA DE GUARDADO Y GPS ---
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _procesandoGuardado = true); // Bloqueamos el botón

    double? latitudFinal;
    double? longitudFinal;

    // 1. Intentamos obtener el GPS con límite de tiempo (Timeout)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          // Límite de 5 segundos para no bloquear la app
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          latitudFinal = position.latitude;
          longitudFinal = position.longitude;
        }
      }
    } catch (e) {
      // Capturamos el error silenciosamente
      debugPrint('Aviso: Guardando registro de agua sin GPS debido a: $e');
    }

    // 2. Construimos el registro
    final nuevoRegistro = Registro(
      uuid: _uuid.v4(),
      fecha: DateTime.now().toString().split(' ')[0],
      timestamp: DateTime.now().toIso8601String(),
      eje: 'Agua',
      categoria: _fuenteSeleccionada,
      subcategoria: _usoSeleccionado,
      cantidad: _cantidad,
      observaciones: _obsController.text,
      latitud: latitudFinal,
      longitud: longitudFinal,
      sincronizado: 0,
      fotoPath: _imagenSeleccionada?.path,
    );

    // 3. Guardamos en SQLite
    try {
      await DatabaseHelper().insertarRegistro(nuevoRegistro);
      if (!mounted) return;

      setState(() => _procesandoGuardado = false);

      // 4. Retroalimentación visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            latitudFinal != null
                ? 'Registro de agua guardado con ubicación 💧📍'
                : 'Registro de agua guardado (Sin cobertura GPS) 💧⚠️',
          ),
          backgroundColor: latitudFinal != null ? Colors.green : Colors.blue,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesandoGuardado = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Consumo de Agua',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.blue[200],
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF9F9F9),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              const Text(
                '¿De dónde viene el agua?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _fuenteSeleccionada,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _fuentes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) => setState(() => _fuenteSeleccionada = val!),
              ),

              const SizedBox(height: 20),

              const Text(
                '¿Para qué la usaste?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _usoSeleccionado,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _usos
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (val) => setState(() => _usoSeleccionado = val!),
              ),

              const SizedBox(height: 25),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Cantidad (Litros)',
                  prefixIcon: const Icon(Icons.water_drop, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Ingresa una cantidad';
                  if (double.tryParse(val) == null || double.parse(val) <= 0) {
                    return 'Ingresa un valor válido';
                  }
                  return null;
                },
                onSaved: (val) => _cantidad = double.parse(val!),
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: _obsController,
                decoration: InputDecoration(
                  hintText: 'Observaciones...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 30),

              if (_imagenSeleccionada != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(
                          _imagenSeleccionada!.path,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_imagenSeleccionada!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 10),
              ],

              OutlinedButton.icon(
                onPressed: _mostrarOpcionesDeImagen,
                icon: Icon(
                  _imagenSeleccionada == null
                      ? Icons.camera_alt
                      : Icons.refresh,
                ),
                label: Text(
                  _imagenSeleccionada == null
                      ? 'AÑADIR FOTO DE EVIDENCIA'
                      : 'CAMBIAR EVIDENCIA',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[800],
                  side: BorderSide(color: Colors.blue[800]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- BOTÓN ÚNICO DE GUARDADO ---
              ElevatedButton(
                onPressed: _procesandoGuardado ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[400],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: _procesandoGuardado
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'OBTENER GPS Y GUARDAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
