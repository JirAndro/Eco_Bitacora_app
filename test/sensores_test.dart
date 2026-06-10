import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:eco_bitacora/models/registro_model.dart';
import 'package:eco_bitacora/services/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await DatabaseHelper().database;
    await db!.execute('DELETE FROM registros');
  });

  group('Pruebas de Integración - Módulo Multimedia y Geolocalización', () {
    test(
      '1. Persistencia completa: Inserción de coordenadas espaciales y ruta de almacenamiento local',
      () async {
        final dbHelper = DatabaseHelper();
        final registroConEvidencia = Registro(
          uuid: 'evidencia-001',
          fecha: '2026-05-22',
          timestamp: DateTime.now().toIso8601String(),
          eje: 'Agua',
          categoria: 'Pozo',
          cantidad: 50.0,
          observaciones: 'Muestra tomada cerca del río',
          latitud: 17.065423,
          longitud: -96.724356,
          fotoPath:
              '/data/user/0/com.example.eco_bitacora/cache/cap_evidencia.jpg',
        );

        await dbHelper.insertarRegistro(registroConEvidencia);

        final listado = await dbHelper.obtenerRegistros();
        final registroRecuperado = listado.firstWhere(
          (r) => r.uuid == 'evidencia-001',
        );

        expect(registroRecuperado.latitud, 17.065423);
        expect(registroRecuperado.longitud, -96.724356);
        expect(
          registroRecuperado.fotoPath,
          '/data/user/0/com.example.eco_bitacora/cache/cap_evidencia.jpg',
        );
      },
    );

    test(
      '2. Tolerancia a fallos: Persistencia de datos nulos por restricción de permisos o falta de cobertura GPS',
      () async {
        final dbHelper = DatabaseHelper();
        final registroSoloTexto = Registro(
          uuid: 'evidencia-002',
          fecha: '2026-05-22',
          timestamp: DateTime.now().toIso8601String(),
          eje: 'Residuos',
          categoria: 'Orgánico',
          cantidad: 4.5,
          observaciones: 'Permisos de hardware denegados en el dispositivo',
          latitud: null,
          longitud: null,
          fotoPath: null,
        );

        expect(
          () async => await dbHelper.insertarRegistro(registroSoloTexto),
          returnsNormally,
        );

        final listado = await dbHelper.obtenerRegistros();
        final registroRecuperado = listado.firstWhere(
          (r) => r.uuid == 'evidencia-002',
        );

        expect(registroRecuperado.categoria, 'Orgánico');
        expect(registroRecuperado.latitud, null);
        expect(registroRecuperado.fotoPath, null);
      },
    );
  });
}
