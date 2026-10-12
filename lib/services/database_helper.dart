import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Modelo de Entidad actualizado con ubicacion_nodo
class SensorReading {
  final int? id;
  final String sensorType; // 'temperature', 'humidity', etc.
  final double value;
  final String timestamp;
  final String? ubicacionNodo; // Nuevo campo agregado en V2

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
      // ⚠️ Carga de Versión 2 para forzar el evento onUpgrade
      version: 2,
      onConfigure: (db) async {
        // Habilitar integridad referencial (Claves Foráneas)
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Creación inicial si la base de datos es totalmente nueva (Instalación limpia)
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

  // 🔄 MIGRACIÓN DE ESQUEMA (V1 a V2)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Alterar la tabla existente para agregar la nueva columna sin perder datos
      await db.execute('''
        ALTER TABLE readings ADD COLUMN ubicacion_nodo TEXT
      ''');
    }
  }

  // ==========================================
  // OPERACIONES CRUD & TRANSACCIONES ACID
  // ==========================================

  // 1. Inserción individual parametrizada (Segura)
  Future<int> insertReading(SensorReading reading) async {
    final db = await instance.database;
    return await db.insert('readings', reading.toMap());
  }

  // 2. ⚡ Inserción Masiva en Lote dentro de una Transacción ACID (Evita bloqueos de UI)
  Future<void> insertBatchReadings(List<SensorReading> readings) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      var batch = txn.batch();
      for (var reading in readings) {
        batch.insert('readings', reading.toMap());
      }
      // Commit en lote sin retornar resultados individuales para máximo rendimiento
      await batch.commit(noResult: true);
    });
  }

  // 3. Consulta parametrizada
  Future<List<SensorReading>> getReadingsByType(String type) async {
    final db = await instance.database;
    final result = await db.query(
      'readings',
      where: 'sensorType = ?',
      whereArgs: [type],
      orderBy: 'id DESC',
    );

    return result.map((json) => SensorReading.fromMap(json)).toList();
  }

  // 4. Obtener todos los registros (para verificar migración)
  Future<List<SensorReading>> getAllReadings() async {
    final db = await instance.database;
    final result = await db.query('readings', orderBy: 'id DESC');
    return result.map((json) => SensorReading.fromMap(json)).toList();
  }
}