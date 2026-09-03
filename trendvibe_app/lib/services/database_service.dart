import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // Lista en memoria de respaldo para Flutter Web si SQFlite no está configurado para Web
  final List<Map<String, dynamic>> _memoriaWebProductos = [];
  final List<Map<String, dynamic>> _memoriaWebQueue = [];

  DatabaseService._init();

  Future<Database?> get database async {
    if (kIsWeb) return null; // En Flutter Web usamos el almacenamiento en memoria/Web
    if (_database != null) return _database!;
    _database = await _initDB('trendvibe_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        last_updated_server TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        client_uuid TEXT PRIMARY KEY,
        endpoint TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Insertar un producto individual
  Future<void> insertarProductoLocal(Map<String, dynamic> producto) async {
    final Map<String, dynamic> nuevo = {
      'id': producto['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'nombre': producto['nombre'],
      'precio': producto['precio'],
      'last_updated_server': producto['last_updated_server'] ?? DateTime.now().toIso8601String(),
    };

    if (kIsWeb) {
      _memoriaWebProductos.add(nuevo);
      return;
    }

    try {
      final db = await database;
      if (db != null) {
        await db.insert('productos', nuevo, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      // Si falla SQLite en Web, guarda en la lista en memoria
      _memoriaWebProductos.add(nuevo);
    }
  }

  // Obtener productos
  Future<List<Map<String, dynamic>>> getProductosLocales() async {
    if (kIsWeb) {
      return List.from(_memoriaWebProductos.reversed);
    }

    try {
      final db = await database;
      if (db == null) return List.from(_memoriaWebProductos.reversed);
      final list = await db.query('productos', orderBy: 'id DESC');
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return List.from(_memoriaWebProductos.reversed);
    }
  }

  // Guardar en cola de sincronización
  Future<void> addToQueue(String uuid, String endpoint, String jsonPayload) async {
    final Map<String, dynamic> item = {
      'client_uuid': uuid,
      'endpoint': endpoint,
      'payload': jsonPayload,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (kIsWeb) {
      _memoriaWebQueue.add(item);
      return;
    }

    try {
      final db = await database;
      if (db != null) {
        await db.insert('sync_queue', item, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      _memoriaWebQueue.add(item);
    }
  }

  // Obtener elementos de la cola de forma segura para Web y Móvil
  Future<List<Map<String, dynamic>>> getQueueItems() async {
    if (kIsWeb) {
      return List.from(_memoriaWebQueue);
    }

    try {
      final db = await database;
      if (db == null) return List.from(_memoriaWebQueue);
      final list = await db.query('sync_queue', orderBy: 'created_at ASC');
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return List.from(_memoriaWebQueue);
    }
  }

  // Eliminar un elemento procesado de la cola
  Future<void> deleteQueueItem(String clientUuid) async {
    if (kIsWeb) {
      _memoriaWebQueue.removeWhere((item) => item['client_uuid'] == clientUuid);
      return;
    }

    try {
      final db = await database;
      if (db != null) {
        await db.delete(
          'sync_queue',
          where: 'client_uuid = ?',
          whereArgs: [clientUuid],
        );
      } else {
        _memoriaWebQueue.removeWhere((item) => item['client_uuid'] == clientUuid);
      }
    } catch (e) {
      _memoriaWebQueue.removeWhere((item) => item['client_uuid'] == clientUuid);
    }
  }

  // Actualizar reintentos de un elemento en cola
  Future<void> updateQueueRetryCount(String clientUuid, int newRetryCount) async {
    if (kIsWeb) {
      final index = _memoriaWebQueue.indexWhere((item) => item['client_uuid'] == clientUuid);
      if (index != -1) {
        _memoriaWebQueue[index]['retry_count'] = newRetryCount;
      }
      return;
    }

    try {
      final db = await database;
      if (db != null) {
        await db.update(
          'sync_queue',
          {'retry_count': newRetryCount},
          where: 'client_uuid = ?',
          whereArgs: [clientUuid],
        );
      } else {
        final index = _memoriaWebQueue.indexWhere((item) => item['client_uuid'] == clientUuid);
        if (index != -1) {
          _memoriaWebQueue[index]['retry_count'] = newRetryCount;
        }
      }
    } catch (e) {
      final index = _memoriaWebQueue.indexWhere((item) => item['client_uuid'] == clientUuid);
      if (index != -1) {
        _memoriaWebQueue[index]['retry_count'] = newRetryCount;
      }
    }
  }

  // Vaciar datos
  Future<void> clearAllData() async {
    _memoriaWebProductos.clear();
    _memoriaWebQueue.clear();

    if (!kIsWeb) {
      try {
        final db = await database;
        if (db != null) {
          await db.delete('productos');
          await db.delete('sync_queue');
        }
      } catch (_) {}
    }
  }
}