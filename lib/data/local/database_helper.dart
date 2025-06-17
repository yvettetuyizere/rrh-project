import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'rrh_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        phone TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create incidents table
    await db.execute('''
      CREATE TABLE incidents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        location TEXT,
        status TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  // CRUD Operations for Users
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await database;
    return await db.query('users');
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }

  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Operations for Incidents
  Future<int> insertIncident(Map<String, dynamic> incident) async {
    Database db = await database;
    return await db.insert('incidents', incident);
  }

  Future<List<Map<String, dynamic>>> getIncidents() async {
    Database db = await database;
    return await db.query('incidents');
  }

  Future<Map<String, dynamic>?> getIncident(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'incidents',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateIncident(Map<String, dynamic> incident) async {
    Database db = await database;
    return await db.update(
      'incidents',
      incident,
      where: 'id = ?',
      whereArgs: [incident['id']],
    );
  }

  Future<int> deleteIncident(int id) async {
    Database db = await database;
    return await db.delete(
      'incidents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
