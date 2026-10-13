import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:flutter_application_1/services/sync_service.dart';

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
    // Iniciar listener de sincronización automática al recuperar red
    SyncService.instance.startAutoSync(() {
      _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Datos sincronizados automáticamente con la Nube.'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    });
  }

  void _refreshData() {
    setState(() {
      _readingsFuture = DatabaseHelper.instance.getAllReadings();
    });
  }

  Future<void> _addReading(double value) async {
    final reading = SensorReading(
      sensorType: 'temperature',
      value: value,
      timestamp: DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '),
      ubicacionNodo: 'ESP32_LAB',
      isSynced: 0, // Inicia como pendiente
    );

    await DatabaseHelper.instance.insertReading(reading);
    _refreshData();
  }

  @override
  void dispose() {
    SyncService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demostración Offline-First'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await SyncService.instance.syncPendingData();
              _refreshData();
            },
            tooltip: 'Sincronizar Manual',
          ),
        ],
      ),
      body: FutureBuilder<List<SensorReading>>(
        future: _readingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay lecturas en SQLite.'));
          }

          final readings = snapshot.data!;
          return ListView.builder(
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final item = readings[index];
              final isAlert = item.value > 35.0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAlert ? Colors.red.shade100 : Colors.green.shade100,
                    child: Icon(
                      isAlert ? Icons.warning : Icons.thermostat,
                      color: isAlert ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text('${item.sensorType.toUpperCase()}: ${item.value} °C'),
                  subtitle: Text('Fecha: ${item.timestamp}\nUbicación: ${item.ubicacionNodo}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.isSynced == 1 ? Icons.cloud_done : Icons.cloud_off,
                        color: item.isSynced == 1 ? Colors.green : Colors.orange,
                      ),
                      Text(
                        item.isSynced == 1 ? 'Nube' : 'Offline',
                        style: TextStyle(
                          fontSize: 10,
                          color: item.isSynced == 1 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _addReading(25.0),
                icon: const Icon(Icons.add),
                label: const Text('Generar Lectura (25°C)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _addReading(39.0),
                icon: const Icon(Icons.warning, color: Colors.red),
                label: const Text('Generar Alerta (39°C)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}