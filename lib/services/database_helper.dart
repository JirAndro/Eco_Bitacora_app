import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/registro_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Lista temporal para simular persistencia en Web (RAM)
  final List<Registro> _webMockStorage = [];

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'eco_bitacora.db');
    return await openDatabase(
      path,
      version: 4, // Incrementamos a 4 por la integración de fotoPath
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE registros(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT,
            fecha TEXT,
            timestamp TEXT,
            eje TEXT,
            categoria TEXT,
            subcategoria TEXT,
            cantidad REAL,
            observaciones TEXT,
            latitud REAL,
            longitud REAL,
            sincronizado INTEGER,
            fotoPath TEXT
          )''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE registros ADD COLUMN subcategoria TEXT',
          );
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE registros ADD COLUMN fotoPath TEXT');
          } catch (e) {}
        }
      },
    );
  }

  // --- MÉTODOS DE PERSISTENCIA ---

  Future<int> insertarRegistro(Registro registro) async {
    if (kIsWeb) {
      _webMockStorage.add(registro);
      return 1;
    }
    Database? db = await database;
    return await db!.insert('registros', registro.toMap());
  }

  Future<List<Registro>> obtenerRegistros() async {
    if (kIsWeb) {
      return List.from(_webMockStorage.reversed);
    }
    Database? db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'registros',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Registro.fromMap(maps[i]));
  }

  /// Obtiene la suma total de 'cantidad' para un eje específico
  Future<double> obtenerSumaPorEje(String eje) async {
    if (kIsWeb) {
      double total = 0.0;
      for (var r in _webMockStorage) {
        if (r.eje.toLowerCase() == eje.toLowerCase()) {
          total += r.cantidad;
        }
      }
      return total;
    }

    Database? db = await database;
    final result = await db!.rawQuery(
      'SELECT SUM(cantidad) as total FROM registros WHERE eje = ?',
      [eje],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Obtiene el conteo de registros por categoría para gráficas de pastel
  Future<Map<String, double>> obtenerTotalesPorCategoria(String eje) async {
    if (kIsWeb) {
      Map<String, double> data = {};
      for (var r in _webMockStorage) {
        if (r.eje.toLowerCase() == eje.toLowerCase()) {
          data[r.categoria] = (data[r.categoria] ?? 0.0) + r.cantidad;
        }
      }
      return data;
    }

    Database? db = await database;
    final List<Map<String, dynamic>> res = await db!.rawQuery(
      'SELECT categoria, SUM(cantidad) as total FROM registros WHERE eje = ? GROUP BY categoria',
      [eje],
    );

    return {
      for (var item in res)
        item['categoria'] as String: (item['total'] as num).toDouble(),
    };
  }

  // --- MÉTODOS DE EDICIÓN Y BORRADO ---

  Future<int> actualizarRegistro(Registro registro) async {
    if (kIsWeb) return 1;
    Database? db = await database;
    return await db!.update(
      'registros',
      registro.toMap(),
      where: 'id = ?',
      whereArgs: [registro.id],
    );
  }

  Future<int> eliminarRegistro(int id) async {
    if (kIsWeb) {
      _webMockStorage.removeWhere((r) => r.id == id);
      return 1;
    }
    Database? db = await database;
    return await db!.delete('registros', where: 'id = ?', whereArgs: [id]);
  }

  /// Obtiene el consumo de los últimos 7 días para gráficas de barras
  Future<Map<String, double>> obtenerHistorialSemanal(String eje) async {
    final todosLosRegistros = await obtenerRegistros();

    Map<String, double> historial = {};
    final hoy = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final dia = hoy.subtract(Duration(days: i));
      final fechaStr = dia.toString().split(' ')[0];
      historial[fechaStr] = 0.0;
    }

    for (var r in todosLosRegistros) {
      if (r.eje.toLowerCase() == eje.toLowerCase()) {
        if (historial.containsKey(r.fecha)) {
          historial[r.fecha] = historial[r.fecha]! + r.cantidad;
        }
      }
    }

    return historial;
  }

  // --- NUEVOS MÉTODOS CORREGIDOS (Con soporte Web) ---

  // Obtener los registros de los últimos 15 días para el informe
  Future<List<Registro>> obtenerRegistrosQuincenales() async {
    final fechaLimite = DateTime.now().subtract(const Duration(days: 15));

    if (kIsWeb) {
      // Filtrado en memoria RAM para la Web
      return _webMockStorage.where((r) {
        try {
          final fechaRegistro = DateTime.parse(r.timestamp);
          return fechaRegistro.isAfter(fechaLimite) ||
              fechaRegistro.isAtSameMomentAs(fechaLimite);
        } catch (e) {
          return false; // Ignorar si hay error de casteo
        }
      }).toList();
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'registros',
      where: 'timestamp >= ?',
      whereArgs: [fechaLimite.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => Registro.fromMap(maps[i]));
  }

  // 1. Obtener los registros pendientes de subir a la nube
  Future<List<Registro>> obtenerRegistrosPendientes() async {
    if (kIsWeb) {
      return _webMockStorage.where((r) => r.sincronizado == 0).toList();
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'registros',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Registro.fromMap(maps[i]));
  }

  // 2. Actualizar la bandera lógica a 1 tras una sincronización exitosa
  Future<void> marcarComoSincronizados(List<String> uuids) async {
    if (kIsWeb) {
      // Modificamos los objetos directamente en la lista temporal de la Web
      for (int i = 0; i < _webMockStorage.length; i++) {
        if (uuids.contains(_webMockStorage[i].uuid)) {
          var map = _webMockStorage[i].toMap();
          map['sincronizado'] = 1;
          _webMockStorage[i] = Registro.fromMap(map);
        }
      }
      return;
    }

    final db = await database;
    for (var uuid in uuids) {
      await db!.update(
        'registros',
        {'sincronizado': 1},
        where: 'uuid = ?',
        whereArgs: [uuid],
      );
    }
  }
}
