import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/registro_model.dart';
import '../services/database_helper.dart';

class RegistroResiduosScreen extends StatefulWidget {
  const RegistroResiduosScreen({super.key});

  @override
  State<RegistroResiduosScreen> createState() => _RegistroResiduosScreenState();
}

class _RegistroResiduosScreenState extends State<RegistroResiduosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  String _clasificacion = 'Orgánico';
  String _tipoResiduo = 'Restos de comida';
  double _peso = 0.0;
  final _obsController = TextEditingController();

  // --- VARIABLES DE IMAGEN ---
  XFile? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();

  // Bandera de carga para el botón unificado
  bool _procesandoGuardado = false;

  final List<String> _tiposOrganicos = [
    'Restos de comida',
    'Poda/Jardín',
    'Hojarasca',
    'Estiércol',
  ];
  final List<String> _tiposInorganicos = [
    'Plástico/PET',
    'Papel/Cartón',
    'Vidrio',
    'Metal',
    'Sanitarios',
  ];

  // --- MENÚ INFERIOR PARA ELEGIR CÁMARA O GALERÍA ---
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
                  'Selecciona una opción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.brown),
                title: const Text('Tomar foto con la cámara'),
                onTap: () {
                  Navigator.of(context).pop();
                  _procesarImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.brown),
                title: const Text('Elegir de la galería / archivos'),
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
          // Si no hay señal en 5 segundos, aborta y continúa el guardado
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          latitudFinal = position.latitude;
          longitudFinal = position.longitude;
        }
      }
    } catch (e) {
      // Capturamos el error silenciosamente (timeout o permisos denegados)
      debugPrint('Aviso: Guardando registro de residuos sin GPS debido a: $e');
    }

    // 2. Construimos el registro
    final nuevoRegistro = Registro(
      uuid: _uuid.v4(),
      fecha: DateTime.now().toString().split(' ')[0],
      timestamp: DateTime.now().toIso8601String(),
      eje: 'Residuos',
      categoria: _clasificacion,
      subcategoria: _tipoResiduo,
      cantidad: _peso,
      observaciones: _obsController.text,
      latitud: latitudFinal,
      longitud: longitudFinal,
      sincronizado: 0,
      fotoPath: _imagenSeleccionada?.path,
    );

    // 3. Guardamos en SQLite
    await DatabaseHelper().insertarRegistro(nuevoRegistro);

    if (!mounted) return;

    setState(() => _procesandoGuardado = false); // Liberamos el botón

    // 4. Retroalimentación visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          latitudFinal != null
              ? 'Residuos registrados con ubicación 📍'
              : 'Residuos registrados (Sin cobertura GPS) ⚠️',
        ),
        backgroundColor: latitudFinal != null ? Colors.green : Colors.brown,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Residuos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.brown[200],
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
                'Clasificación del Residuo:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Colors.brown[400],
                    selectedForegroundColor: Colors.white,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'Orgánico',
                      label: Text('Orgánico'),
                      icon: Icon(Icons.eco),
                    ),
                    ButtonSegment(
                      value: 'Inorgánico',
                      label: Text('Inorgánico'),
                      icon: Icon(Icons.delete_outline),
                    ),
                  ],
                  selected: {_clasificacion},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _clasificacion = newSelection.first;
                      _tipoResiduo = _clasificacion == 'Orgánico'
                          ? _tiposOrganicos[0]
                          : _tiposInorganicos[0];
                    });
                  },
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Tipo específico:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoResiduo,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    (_clasificacion == 'Orgánico'
                            ? _tiposOrganicos
                            : _tiposInorganicos)
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _tipoResiduo = val!),
              ),

              const SizedBox(height: 25),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Peso estimado (Kilogramos)',
                  prefixIcon: const Icon(Icons.scale, color: Colors.brown),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Ingresa el peso';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return 'El peso debe ser mayor a 0';
                  return null;
                },
                onSaved: (val) => _peso = double.parse(val!),
              ),

              const SizedBox(height: 25),

              const Text(
                'Observaciones (Destino final):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _obsController,
                decoration: InputDecoration(
                  hintText: 'Ej: Se llevó a la composta...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 30),

              // --- VISUALIZADOR DE LA FOTO ---
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
                  foregroundColor: Colors.brown,
                  side: const BorderSide(color: Colors.brown),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 40),

              // --- BOTÓN ÚNICO DE GUARDADO ---
              ElevatedButton(
                onPressed: _procesandoGuardado ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[400],
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
