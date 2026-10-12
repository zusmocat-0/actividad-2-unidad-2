import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/csv_node_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Práctica 1 - CSV Node Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const NodeManagerScreen(),
    );
  }
}

// ✅ CLASE STATEFULWIDGET CON CREATESTABLE OBLIGATORIO
class NodeManagerScreen extends StatefulWidget {
  const NodeManagerScreen({super.key});

  @override
  State<NodeManagerScreen> createState() => _NodeManagerScreenState();
}

// ✅ CLASE STATE DONDE VIVE EL ESTADO Y EL MÉTODO BUILD()
class _NodeManagerScreenState extends State<NodeManagerScreen> {
  final CsvNodeManager _csvManager = CsvNodeManager();

  // Matriz de datos de prueba: [ID, TipoSensor, Ubicación, Estado]
  final List<List<dynamic>> _sampleNodes = [
    ["node_id", "sensor_type", "location", "status"],
    ["NODE_01", "temperature", "Zone_A", "active"],
    ["NODE_02", "humidity", "Zone_B", "active"],
    ["NODE_03", "pressure", "Zone_A", "inactive"],
  ];

  String _lastExportPath = "";
  String _statusMessage = "Listo para probar la exportación e importación.";
  bool _isSuccess = true;

  // Acción 1: Exportar datos a CSV
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

  // Acción 2: Importar y verificar SHA-256
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
            const Text(
              'Nodos IoT a Procesar:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Visualización de la tabla de datos
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: _sampleNodes.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(row.join(" | "), style: const TextStyle(fontFamily: 'monospace')),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 25),

            // Botones de Acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Exportar CSV'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _importCsv,
                    icon: const Icon(Icons.download_for_offline),
                    label: const Text('Importar / Validar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Panel de Resultados / Estado del Checksum
            Card(
              color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: _isSuccess ? Colors.green : Colors.red,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
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