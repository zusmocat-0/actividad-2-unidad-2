import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Modelo de Entidad
class SensorReading {
  final int? id;
  final String sensorType;
  final double value;
  final String timestamp;
  final String? ubicacionNodo;

  SensorReading({
    this.id,
    required this.sensorType,
    required this.value,
    required this.timestamp,
    this.ubicacionNodo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sensorType': sensorType,
      'value': value,
      'timestamp': timestamp,
      'ubicacion_nodo': ubicacionNodo,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int?,
      sensorType: map['sensorType'] as String,
      value: map['value'] as double,
      timestamp: map['timestamp'] as String,
      ubicacionNodo: map['ubicacion_nodo'] as String?,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Lista simulada en memoria exclusivamente para ejecuciones en Chrome/Web
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
      version: 2,
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
        ubicacion_nodo TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE readings ADD COLUMN ubicacion_nodo TEXT');
    }
  }

  // ==========================================
  // OPERACIONES ADAPTADAS PARA SNOOPING Y WEB
  // ==========================================

  Future<int> insertReading(SensorReading reading) async {
    if (kIsWeb) {
      // Si corre en Chrome, guarda directamente en la lista local simulada
      _webMemoryStorage.insert(0, reading);
      return _webMemoryStorage.length;
    }

    final db = await instance.database;
    return await db.insert('readings', reading.toMap());
  }

  Future<void> insertBatchReadings(List<SensorReading> readings) async {
    if (kIsWeb) {
      _webMemoryStorage.insertAll(0, readings);
      return;
    }

    final db = await instance.database;
    await db.transaction((txn) async {
      var batch = txn.batch();
      for (var reading in readings) {
        batch.insert('readings', reading.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<SensorReading>> getAllReadings() async {
    if (kIsWeb) {
      // Simula pequeña latencia asíncrona para ver el indicador de carga del FutureBuilder
      await Future.delayed(const Duration(milliseconds: 300));
      return List.from(_webMemoryStorage);
    }

    final db = await instance.database;
    final result = await db.query('readings', orderBy: 'id DESC');
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }
}