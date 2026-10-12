import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_application_1/services/database_helper.dart'; // Ajusta según la ubicación de tu archivo

void main() {
  // Inicializar el soporte de SQLite para entornos de prueba en computadora
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('Inserción masiva en lote y migración V2', () async {
    final dbHelper = DatabaseHelper.instance;

    List<SensorReading> batchList = List.generate(100, (i) {
      return SensorReading(
        sensorType: i % 2 == 0 ? 'temperature' : 'humidity',
        value: 20.0 + (i * 0.1),
        timestamp: DateTime.now().toIso8601String(),
        ubicacionNodo: 'NODO_ESP32_ZONA_${i % 3}',
      );
    });

    await dbHelper.insertBatchReadings(batchList);

    List<SensorReading> readings = await dbHelper.getAllReadings();
    expect(readings.length >= 100, true);
    expect(readings.first.ubicacionNodo != null, true);
  });
}