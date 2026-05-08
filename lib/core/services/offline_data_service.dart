import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class OfflineDataService {
  static final OfflineDataService _instance = OfflineDataService._internal();
  factory OfflineDataService() => _instance;
  OfflineDataService._internal();

  Database? _database;
  static const String _dbName = 'vacapp_offline.db';
  static const int _dbVersion = 1;

  /// Inicializar la base de datos offline
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crear tablas de la base de datos
  Future<void> _createTables(Database db, int version) async {
    // Tabla de animales
    await db.execute('''
      CREATE TABLE animals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        breed TEXT,
        birth_date TEXT,
        weight REAL,
        image_url TEXT,
        notes TEXT,
        stable_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabla de establos
    await db.execute('''
      CREATE TABLE stables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name TEXT NOT NULL,
        location TEXT,
        capacity INTEGER,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabla de vacunas
    await db.execute('''
      CREATE TABLE vaccines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        animal_id INTEGER NOT NULL,
        vaccine_name TEXT NOT NULL,
        application_date TEXT NOT NULL,
        next_dose_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (animal_id) REFERENCES animals (id)
      )
    ''');

    // Tabla de campañas
    await db.execute('''
      CREATE TABLE campaigns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        vaccine_type TEXT,
        target_animals TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabla de staff/personal
    await db.execute('''
      CREATE TABLE staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Tabla de datos de usuario para caché
    await db.execute('''
      CREATE TABLE user_cache (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Manejar actualizaciones de esquema de base de datos
  }

  /// Guardar datos en caché
  Future<void> cacheData(String key, Map<String, dynamic> data, {Duration? expiry}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final expiresAt = expiry != null 
        ? DateTime.now().add(expiry).toIso8601String() 
        : null;

    await db.insert(
      'user_cache',
      {
        'key': key,
        'value': jsonEncode(data),
        'created_at': now,
        'expires_at': expiresAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtener datos del caché
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'user_cache',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;

    final cached = result.first;
    
    // Verificar si ha expirado
    if (cached['expires_at'] != null) {
      final expiresAt = DateTime.parse(cached['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        await db.delete('user_cache', where: 'key = ?', whereArgs: [key]);
        return null;
      }
    }

    return jsonDecode(cached['value']) as Map<String, dynamic>;
  }

  /// Guardar animales offline
  Future<int> saveAnimalOffline(Map<String, dynamic> animal) async {
    debugPrint('DEBUG OfflineDataService: Guardando animal offline: $animal');
    final db = await database;
    animal['created_at'] = DateTime.now().toIso8601String();
    animal['updated_at'] = DateTime.now().toIso8601String();
    animal['is_synced'] = 0;
    
    final result = await db.insert('animals', animal);
    debugPrint('DEBUG OfflineDataService: Animal guardado con ID: $result');
    return result;
  }

  /// Obtener animales offline
  Future<List<Map<String, dynamic>>> getAnimalsOffline() async {
    debugPrint('DEBUG OfflineDataService: Obteniendo animales offline');
    final db = await database;
    final result = await db.query('animals', orderBy: 'created_at DESC');
    debugPrint('DEBUG OfflineDataService: Encontrados ${result.length} animales offline');
    return result;
  }

  /// Guardar vacunas offline
  Future<int> saveVaccineOffline(Map<String, dynamic> vaccine) async {
    final db = await database;
    vaccine['created_at'] = DateTime.now().toIso8601String();
    vaccine['updated_at'] = DateTime.now().toIso8601String();
    vaccine['is_synced'] = 0;
    
    return await db.insert('vaccines', vaccine);
  }

  /// Obtener vacunas offline
  Future<List<Map<String, dynamic>>> getVaccinesOffline({int? animalId}) async {
    final db = await database;
    
    if (animalId != null) {
      return await db.query(
        'vaccines',
        where: 'animal_id = ?',
        whereArgs: [animalId],
        orderBy: 'application_date DESC',
      );
    }
    
    return await db.query('vaccines', orderBy: 'application_date DESC');
  }

  /// Guardar establos offline
  Future<int> saveStableOffline(Map<String, dynamic> stable) async {
    final db = await database;
    stable['created_at'] = DateTime.now().toIso8601String();
    stable['updated_at'] = DateTime.now().toIso8601String();
    stable['is_synced'] = 0;
    
    return await db.insert('stables', stable);
  }

  /// Obtener establos offline
  Future<List<Map<String, dynamic>>> getStablesOffline() async {
    final db = await database;
    return await db.query('stables', orderBy: 'created_at DESC');
  }

  /// Guardar campañas offline
  Future<int> saveCampaignOffline(Map<String, dynamic> campaign) async {
    final db = await database;
    campaign['created_at'] = DateTime.now().toIso8601String();
    campaign['updated_at'] = DateTime.now().toIso8601String();
    campaign['is_synced'] = 0;
    
    return await db.insert('campaigns', campaign);
  }

  /// Obtener campañas offline
  Future<List<Map<String, dynamic>>> getCampaignsOffline() async {
    final db = await database;
    return await db.query('campaigns', orderBy: 'start_date DESC');
  }

  /// Obtener datos no sincronizados
  Future<Map<String, List<Map<String, dynamic>>>> getUnsyncedData() async {
    final db = await database;
    
    return {
      'animals': await db.query('animals', where: 'is_synced = 0'),
      'vaccines': await db.query('vaccines', where: 'is_synced = 0'),
      'stables': await db.query('stables', where: 'is_synced = 0'),
      'campaigns': await db.query('campaigns', where: 'is_synced = 0'),
      'staff': await db.query('staff', where: 'is_synced = 0'),
    };
  }

  /// Marcar datos como sincronizados
  Future<void> markAsSynced(String table, int localId, int serverId) async {
    final db = await database;
    await db.update(
      table,
      {
        'server_id': serverId,
        'is_synced': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Limpiar caché expirado
  Future<void> clearExpiredCache() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.delete(
      'user_cache',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [now],
    );
  }

  /// Limpiar todos los datos offline
  Future<void> clearAllOfflineData() async {
    final db = await database;
    
    await db.delete('animals');
    await db.delete('vaccines');
    await db.delete('stables');
    await db.delete('campaigns');
    await db.delete('staff');
    await db.delete('user_cache');
  }

  /// Obtener estadísticas de datos offline
  Future<Map<String, int>> getOfflineStats() async {
    final db = await database;
    
    final animals = await db.rawQuery('SELECT COUNT(*) as count FROM animals');
    final vaccines = await db.rawQuery('SELECT COUNT(*) as count FROM vaccines');
    final stables = await db.rawQuery('SELECT COUNT(*) as count FROM stables');
    final campaigns = await db.rawQuery('SELECT COUNT(*) as count FROM campaigns');
    final unsynced = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM animals WHERE is_synced = 0) +
        (SELECT COUNT(*) FROM vaccines WHERE is_synced = 0) +
        (SELECT COUNT(*) FROM stables WHERE is_synced = 0) +
        (SELECT COUNT(*) FROM campaigns WHERE is_synced = 0) as count
    ''');
    
    return {
      'animals': animals.first['count'] as int,
      'vaccines': vaccines.first['count'] as int,
      'stables': stables.first['count'] as int,
      'campaigns': campaigns.first['count'] as int,
      'unsynced': unsynced.first['count'] as int,
    };
  }
}
