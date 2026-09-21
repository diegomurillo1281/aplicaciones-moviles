import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/prenda_model.dart';

class DBService {
  static final DBService db = DBService._privateConstructor();
  static Database? _database;

  DBService._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'trendvibe_inventory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE prendas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            stock INTEGER NOT NULL,
            imagen_url TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertarPrenda(PrendaModel prenda) async {
    final db = await database;
    return await db.insert('prendas', prenda.toMap());
  }

  Future<List<PrendaModel>> obtenerPrendas() async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query('prendas', orderBy: 'id DESC');
    return res.isNotEmpty ? res.map((c) => PrendaModel.fromMap(c)).toList() : [];
  }

  Future<int> eliminarPrenda(int id) async {
    final db = await database;
    return await db.delete('prendas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> actualizarPrenda(PrendaModel prenda) async {
    final db = await database;
    return await db.update(
      'prendas',
      prenda.toMap(),
      where: 'id = ?',
      whereArgs: [prenda.id],
    );
  }
}