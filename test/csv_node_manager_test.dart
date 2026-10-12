import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/csv_node_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Debe exportar y verificar correctamente la integridad del CSV', () async {
    final csvManager = CsvNodeManager();

    List<List<dynamic>> sampleNodes = [
      ["node_id", "sensor_type", "location", "status"],
      ["NODE_01", "temperature", "Zone_A", "active"],
      ["NODE_02", "humidity", "Zone_B", "active"],
    ];

    // 1. Exportar
    String path = await csvManager.exportNodesToCsv(sampleNodes);
    expect(path.isNotEmpty, true);

    // 2. Validar e Importar
    bool isValid = await csvManager.verifyAndImportCsv(path);
    expect(isValid, true);
  });
}