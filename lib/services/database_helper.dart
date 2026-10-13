import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SensorReading {
  final int? id;
  final String sensorType;
  final double value;
  final String timestamp;
  final String? ubicacionNodo;
  final int isSynced; // 0: Pendiente de sincronizar, 1: Sincronizado

  SensorReading({
    this.id,
    required this.sensorType,
    required this.value,
    required this.timestamp,
    this.ubicacionNodo,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensorType': sensorType,
      'value': value,
      'timestamp': timestamp,
      'ubicacion_nodo': ubicacionNodo,
      'is_synced': isSynced,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int?,
      sensorType: map['sensorType'] as String,
      value: map['value'] as double,
      timestamp: map['timestamp'] as String,
      ubicacionNodo: map['ubicacion_nodo'] as String?,
      isSynced: map['is_synced'] as int? ?? 0,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final List<SensorReading> _webMemoryStorage = [];

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iot_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Incrementamos versión a 3
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensorType TEXT NOT NULL,
        value REAL NOT NULL,
        timestamp TEXT NOT NULL,
        ubicacion_nodo TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE readings ADD COLUMN ubicacion_nodo TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE readings ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
    }
  }

  // Insertar registro localmente
  Future<int> insertReading(SensorReading reading) async {
    if (kIsWeb) {
      _webMemoryStorage.insert(0, reading);
      return _webMemoryStorage.length;
    }

    final db = await instance.database;
    return await db.insert('readings', reading.toMap());
  }

  // Obtener solo registros pendientes de sincronizar (is_synced = 0)
  Future<List<SensorReading>> getUnsyncedReadings() async {
    if (kIsWeb) {
      return _webMemoryStorage.where((r) => r.isSynced == 0).toList();
    }

    final db = await instance.database;
    final result = await db.query(
      'readings',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }

  // Marcar registro como sincronizado en la base de datos local
  Future<void> markAsSynced(int id) async {
    if (kIsWeb) {
      final index = _webMemoryStorage.indexWhere((r) => r.id == id);
      if (index != -1) {
        final old = _webMemoryStorage[index];
        _webMemoryStorage[index] = SensorReading(
          id: old.id,
          sensorType: old.sensorType,
          value: old.value,
          timestamp: old.timestamp,
          ubicacionNodo: old.ubicacionNodo,
          isSynced: 1,
        );
      }
      return;
    }

    final db = await instance.database;
    await db.update(
      'readings',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SensorReading>> getAllReadings() async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 200));
      return List.from(_webMemoryStorage);
    }

    final db = await instance.database;
    final result = await db.query('readings', orderBy: 'id DESC');
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }
}