import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    String path = join(dbPath, 'notes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner TEXT,
        description TEXT,
        external_id INTEGER NULL,
        created TEXT,
        modified TEXT NULL
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    final db = await database;
    return await db.query('notes');
  }

  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.insert('notes', note);
  }

  Future<int> updateNoteDescription(int id, String newDescription) async {
    final db = await database;
    return await db.update(
      'notes',
      {'description': newDescription, 'modified': 'X'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateNoteExternalId(int id, int externalId) async {
    final db = await database;
    return await db.update(
      'notes',
      {'external_id': externalId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateNoteModifiedNull(int id) async {
    final db = await database;
    return await db.update(
      'notes',
      {'modified': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAzureNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'external_id = ?', whereArgs: [id]);
  }
}
