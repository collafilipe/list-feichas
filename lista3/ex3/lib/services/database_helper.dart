import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'contacts.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts(
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        telefone TEXT NOT NULL,
        email TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  Future<int> insertContact(Contact contact) async {
    final db = await database;
    try {
      return await db.insert(
        'contacts',
        contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Erro ao inserir contato: $e');
    }
  }

  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'contacts',
        orderBy: 'nome ASC',
      );

      return List.generate(maps.length, (i) {
        return Contact.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Erro ao buscar contatos: $e');
    }
  }

  Future<Contact?> getContactById(String id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'contacts',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Contact.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar contato por ID: $e');
    }
  }

  Future<int> updateContact(Contact contact) async {
    final db = await database;
    try {
      return await db.update(
        'contacts',
        contact.toMap(),
        where: 'id = ?',
        whereArgs: [contact.id],
      );
    } catch (e) {
      throw Exception('Erro ao atualizar contato: $e');
    }
  }

  Future<int> deleteContact(String id) async {
    final db = await database;
    try {
      return await db.delete(
        'contacts',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Erro ao deletar contato: $e');
    }
  }

  Future<void> clearAllContacts() async {
    final db = await database;
    try {
      await db.delete('contacts');
    } catch (e) {
      throw Exception('Erro ao limpar contatos: $e');
    }
  }

  Future<void> insertMultipleContacts(List<Contact> contacts) async {
    final db = await database;
    final batch = db.batch();
    
    try {
      for (Contact contact in contacts) {
        batch.insert(
          'contacts',
          contact.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao inserir múltiplos contatos: $e');
    }
  }

  Future<int> getContactsCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery('SELECT COUNT(*) FROM contacts');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Erro ao contar contatos: $e');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}