import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database_helper.dart'; // Ajusta la ruta si es necesario

class HistoricalAlertsScreen extends StatefulWidget {
  const HistoricalAlertsScreen({super.key});

  @override
  State<HistoricalAlertsScreen> createState() => _HistoricalAlertsScreenState();
}

class _HistoricalAlertsScreenState extends State<HistoricalAlertsScreen> {
  late Future<List<SensorReading>> _readingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Consulta la base de datos de manera asíncrona sin congelar la UI
  void _refreshData() {
    setState(() {
      _readingsFuture = DatabaseHelper.instance.getAllReadings();
    });
  }

  // Simulación de recepción de lectura del hardware ESP32
  Future<void> _simulateESP32Reading(double value) async {
    final reading = SensorReading(
      sensorType: 'temperature',
      value: value,
      timestamp: DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '),
      ubicacionNodo: 'NODO_ESP32_ZONA_1',
    );

    await DatabaseHelper.instance.insertReading(reading);
    _refreshData(); // Actualizar la lista en pantalla
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico Smart-Environment IoT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualizar Datos',
          ),
        ],
      ),
      body: FutureBuilder<List<SensorReading>>(
        future: _readingsFuture,
        builder: (context, snapshot) {
          // 🛑 Criterio 1 de Rúbrica: Estado 1 - Carga (ConnectionState.waiting)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Consultando SQLite en hilo secundario...'),
                ],
              ),
            );
          } 
          // 🛑 Criterio 1 de Rúbrica: Estado 2 - Error (hasError)
          else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text('Error al cargar datos locales: ${snapshot.error}'),
                ],
              ),
            );
          } 
          // 🛑 Criterio 1 de Rúbrica: Estado 3 - Pantalla Vacía (!hasData / isEmpty)
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, color: Colors.grey, size: 48),
                  SizedBox(height: 8),
                  Text('No hay registros ni alertas guardadas.'),
                ],
              ),
            );
          }

          // 🟢 Renderizado con ListView.builder
          final readings = snapshot.data!;
          return ListView.builder(
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final item = readings[index];
              // 🔴 Criterio 2 de Rúbrica: Lógica de Alerta IoT (Umbral > 35°C)
              final bool isAlert = item.value > 35.0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  // Clasificación visual mediante iconos y colores diferenciados
                  leading: CircleAvatar(
                    backgroundColor: isAlert ? Colors.red.shade100 : Colors.green.shade100,
                    child: Icon(
                      isAlert ? Icons.warning_amber_rounded : Icons.thermostat,
                      color: isAlert ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    '${item.sensorType.toUpperCase()}: ${item.value.toStringAsFixed(1)} °C',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAlert ? Colors.red.shade900 : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Fecha: ${item.timestamp}\nUbicación: ${item.ubicacionNodo ?? "Sin ubicación"}',
                  ),
                  trailing: isAlert
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ALERTA',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      : const Text(
                          'NORMAL',
                          style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                ),
              );
            },
          );
        },
      ),
      // Botones de simulación para probar recepción de hardware (ESP32)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade100,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _simulateESP32Reading(24.5),
                icon: const Icon(Icons.add, color: Colors.green),
                label: const Text('Lectura Normal (24.5°C)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _simulateESP32Reading(38.2),
                icon: const Icon(Icons.warning, color: Colors.red),
                label: const Text('Alerta ESP32 (38.2°C)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}