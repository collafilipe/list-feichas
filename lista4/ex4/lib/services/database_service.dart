import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/article.dart';

class DatabaseService {
  static Database? _database;
  static const String tableName = 'favoritos';

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'noticias.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName(
        id INTEGER PRIMARY KEY,
        titulo TEXT NOT NULL,
        conteudo TEXT NOT NULL,
        autor TEXT NOT NULL
      )
    ''');
  }

  Future<void> addFavorito(Article article) async {
    final db = await database;
    
    await db.insert(
      tableName,
      article.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorito(int articleId) async {
    final db = await database;
    
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }

  Future<List<Article>> getFavoritos() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    
    return List.generate(maps.length, (i) {
      return Article.fromMap(maps[i]);
    });
  }

  Future<bool> isFavorito(int articleId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [articleId],
    );
    
    return maps.isNotEmpty;
  }

  Future<void> clearFavoritos() async {
    final db = await database;
    
    await db.delete(tableName);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}