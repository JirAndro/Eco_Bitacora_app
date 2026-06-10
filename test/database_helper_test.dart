import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:eco_bitacora/models/registro_model.dart';
import 'package:eco_bitacora/services/database_helper.dart';

void main() {
  // 1. CONFIGURACIÓN DEL ENTORNO DE PRUEBAS
  // sqflite_common_ffi nos permite simular SQLite en Windows/Mac sin celular
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // 2. LIMPIEZA ANTES DE CADA PRUEBA
  // Aseguramos que la base de datos esté vacía para que una prueba no afecte a otra
  setUp(() async {
    final db = await DatabaseHelper().database;
    await db!.execute('DELETE FROM registros');
  });

  group('Pruebas Unitarias del Incremento II - Cálculos Matemáticos', () {
    test(
      '1. obtenerSumaPorEje debe sumar correctamente las cantidades',
      () async {
        // PREPARACIÓN (Arrange): Insertamos dos registros de Agua
        final dbHelper = DatabaseHelper();
        await dbHelper.insertarRegistro(
          Registro(
            uuid: 'test-1',
            fecha: '2026-04-10',
            timestamp: DateTime.now().toIso8601String(),
            eje: 'Agua',
            categoria: 'Red pública',
            cantidad: 15.0, // 15 litros
            observaciones: 'Prueba 1',
          ),
        );

        await dbHelper.insertarRegistro(
          Registro(
            uuid: 'test-2',
            fecha: '2026-04-10',
            timestamp: DateTime.now().toIso8601String(),
            eje: 'Agua',
            categoria: 'Garrafón',
            cantidad: 5.5, // 5.5 litros
            observaciones: 'Prueba 2',
          ),
        );

        // ACCIÓN (Act): Ejecutamos la función que alimenta al Semáforo
        final sumaTotal = await dbHelper.obtenerSumaPorEje('Agua');

        // VERIFICACIÓN (Assert): 15.0 + 5.5 DEBE ser 20.5
        expect(sumaTotal, 20.5);
      },
    );

    test(
      '2. obtenerTotalesPorCategoria debe agrupar bien para la gráfica de pastel',
      () async {
        final dbHelper = DatabaseHelper();

        // PREPARACIÓN: Insertamos 2 Orgánicos y 1 Inorgánico
        await dbHelper.insertarRegistro(
          Registro(
            uuid: 'test-3',
            fecha: '2026-04-10',
            timestamp: '1',
            eje: 'Residuos',
            categoria: 'Orgánico',
            cantidad: 2.0,
            observaciones: '',
          ),
        );
        await dbHelper.insertarRegistro(
          Registro(
            uuid: 'test-4',
            fecha: '2026-04-10',
            timestamp: '2',
            eje: 'Residuos',
            categoria: 'Orgánico',
            cantidad: 3.0,
            observaciones: '',
          ),
        );
        await dbHelper.insertarRegistro(
          Registro(
            uuid: 'test-5',
            fecha: '2026-04-10',
            timestamp: '3',
            eje: 'Residuos',
            categoria: 'Inorgánico',
            cantidad: 1.5,
            observaciones: '',
          ),
        );

        // ACCIÓN: Ejecutamos la función que alimenta la Gráfica de Pastel
        final mapaTotales = await dbHelper.obtenerTotalesPorCategoria(
          'Residuos',
        );

        // VERIFICACIÓN: Orgánico debe ser 5.0 (2+3) e Inorgánico 1.5
        expect(mapaTotales['Orgánico'], 5.0);
        expect(mapaTotales['Inorgánico'], 1.5);
      },
    );

    test(
      '3. obtenerSumaPorEje debe devolver 0.0 si el eje no tiene registros',
      () async {
        final dbHelper = DatabaseHelper();

        // ACCIÓN: Consultamos "Alimentos" en una base de datos vacía
        final sumaVacia = await dbHelper.obtenerSumaPorEje('Alimentos');

        // VERIFICACIÓN: El sistema no debe crashear, debe devolver 0.0
        expect(sumaVacia, 0.0);
      },
    );
  });
}
