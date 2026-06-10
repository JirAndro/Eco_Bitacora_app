import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/registro_model.dart';
import '../services/database_helper.dart';

class RegistroAlimentosScreen extends StatefulWidget {
  const RegistroAlimentosScreen({super.key});

  @override
  State<RegistroAlimentosScreen> createState() =>
      _RegistroAlimentosScreenState();
}

class _RegistroAlimentosScreenState extends State<RegistroAlimentosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Variables de estado
  String _origenAlimento = 'Mercado local / Regional';
  String _tipoProcesamiento = 'Procesado (Conservas/Pan artesanal)';
  double _cantidad = 0.0;
  final _obsController = TextEditingController();

  // Variables de imagen
  XFile? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();

  // Bandera de carga para el botón
  bool _procesandoGuardado = false;

  final List<String> _origenes = [
    'Cosecha propia / Huerto',
    'Mercado local / Regional',
    'Supermercado',
    'Traspatio',
    'Donación / Regalo',
    'Tienda autoservicio (Oxxo, 7-eleven...)',
  ];

  final List<String> _tiposProcesamiento = [
    'Procesado (Conservas/Pan artesanal)',
    'Ultraprocesado (Industrial)',
    'Cereales',
    'Origen animal',
    'Frutas',
    'Verduras',
    'Leguminosas',
  ];

  // --- MENÚ PARA ELEGIR CÁMARA O GALERÍA ---
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
                  'Evidencia de Alimento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text('Tomar foto con la cámara'),
                onTap: () {
                  Navigator.of(context).pop();
                  _procesarImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _procesarImagen(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
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

      if (foto != null) {
        setState(() {
          _imagenSeleccionada = foto;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener la imagen: $e')));
    }
  }

  // --- NUEVA LÓGICA UNIFICADA DE GUARDADO Y GPS ---
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _procesandoGuardado = true); // Bloqueamos el botón

    double? latitudFinal;
    double? longitudFinal;

    // 1. Intentamos obtener el GPS con un límite de tiempo (Timeout)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          // Si no hay buena señal, abortará la búsqueda a los 5 segundos para no frustrar al usuario
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          latitudFinal = position.latitude;
          longitudFinal = position.longitude;
        }
      }
    } catch (e) {
      // Capturamos silenciosamente cualquier error de GPS (timeout, permisos).
      // El flujo continuará y las variables de ubicación quedarán en null.
      debugPrint('Aviso: Guardando registro sin GPS debido a: $e');
    }

    // 2. Construimos el registro y lo guardamos
    final categoriaCombinada = "$_origenAlimento | $_tipoProcesamiento";

    final nuevoRegistro = Registro(
      uuid: _uuid.v4(),
      fecha: DateTime.now().toString().split(' ')[0],
      timestamp: DateTime.now().toIso8601String(),
      eje: 'Alimentos',
      categoria: categoriaCombinada,
      cantidad: _cantidad,
      observaciones: _obsController.text,
      latitud: latitudFinal,
      longitud: longitudFinal,
      sincronizado: 0,
      fotoPath: _imagenSeleccionada?.path,
    );

    await DatabaseHelper().insertarRegistro(nuevoRegistro);

    if (!mounted) return;

    setState(() => _procesandoGuardado = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          latitudFinal != null
              ? 'Registro guardado con ubicación 📍'
              : 'Registro guardado (Sin cobertura GPS) ⚠️',
        ),
        backgroundColor: latitudFinal != null ? Colors.green : Colors.orange,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Consumo de Alimentos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.orange[200],
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
                'Origen del Alimento:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _origenAlimento,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _origenes
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _origenAlimento = val!),
              ),

              const SizedBox(height: 20),

              const Text(
                'Grado de Procesamiento:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoProcesamiento,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _tiposProcesamiento
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _tipoProcesamiento = val!),
              ),

              const SizedBox(height: 25),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Cantidad (Kg / Porciones)',
                  prefixIcon: const Icon(
                    Icons.restaurant,
                    color: Colors.orange,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Ingresa una cantidad';
                  if (double.tryParse(val) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
                onSaved: (val) => _cantidad = double.parse(val!),
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: _obsController,
                decoration: const InputDecoration(
                  labelText: 'Notas tradicionales/Descripcion',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Maíz criollo de la milpa...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              // Visualizador de la foto
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
                  foregroundColor: Colors.orange[800],
                  side: BorderSide(color: Colors.orange[800]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 40),

              // BOTÓN ÚNICO DE GUARDADO
              ElevatedButton(
                onPressed: _procesandoGuardado ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[400],
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
