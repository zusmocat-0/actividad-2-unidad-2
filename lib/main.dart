import 'package:flutter/foundation.dart'; // Para detectar kIsWeb
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Web
import 'package:flutter_application_1/services/csv_node_manager.dart';
import 'package:flutter_application_1/screens/historical_alerts_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌐 Si estamos ejecutando la app en Google Chrome / Web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const SmartEnvironmentApp());
}

class SmartEnvironmentApp extends StatelessWidget {
  const SmartEnvironmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart-Environment IoT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeMenuScreen(), // Menú principal
    );
  }
}

// 🏠 Pantalla de menú para elegir entre las dos prácticas
class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart-Environment IoT'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.storage),
              label: const Text('Práctica 1 - CSV Node Manager'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NodeManagerScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.warning_amber),
              label: const Text('Alertas Históricas'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoricalAlertsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ TU CÓDIGO ORIGINAL (sin cambios) ============

class NodeManagerScreen extends StatefulWidget {
  const NodeManagerScreen({super.key});

  @override
  State<NodeManagerScreen> createState() => _NodeManagerScreenState();
}

class _NodeManagerScreenState extends State<NodeManagerScreen> {
  final CsvNodeManager _csvManager = CsvNodeManager();

  final List<List<dynamic>> _sampleNodes = [
    ["node_id", "sensor_type", "location", "status"],
    ["NODE_01", "temperature", "Zone_A", "active"],
    ["NODE_02", "humidity", "Zone_B", "active"],
    ["NODE_03", "pressure", "Zone_A", "inactive"],
  ];

  String _lastExportPath = "";
  String _statusMessage = "Listo para probar la exportación e importación.";
  bool _isSuccess = true;

  Future<void> _exportCsv() async {
    try {
      String path = await _csvManager.exportNodesToCsv(_sampleNodes);
      setState(() {
        _lastExportPath = path;
        _statusMessage = "✅ Archivo CSV generado exitosamente:\n$path";
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "❌ Error al exportar: $e";
        _isSuccess = false;
      });
    }
  }

  Future<void> _importCsv() async {
    if (_lastExportPath.isEmpty) {
      setState(() {
        _statusMessage = "⚠️ Primero debes exportar el archivo CSV.";
        _isSuccess = false;
      });
      return;
    }

    bool isValid = await _csvManager.verifyAndImportCsv(_lastExportPath);
    setState(() {
      if (isValid) {
        _statusMessage = "✅ Integridad Verificada (SHA-256 Coincide).\nLos datos de los nodos son auténticos.";
        _isSuccess = true;
      } else {
        _statusMessage = "🚨 ALERTA DE SEGURIDAD:\nEl archivo ha sido alterado o está corrupto.";
        _isSuccess = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Nodos IoT (CSV)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nodos IoT a Procesar:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: _sampleNodes.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(row.join(" | "),
                          style: const TextStyle(fontFamily: 'monospace')),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Exportar CSV'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _importCsv,
                    icon: const Icon(Icons.download_for_offline),
                    label: const Text('Importar / Validar'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Card(
              color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: _isSuccess ? Colors.green : Colors.red, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isSuccess
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}