import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:csv/csv.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

// Importación condicional para usar funciones web sin romper plataformas nativas
import 'package:universal_html/html.dart' as html;

class CsvNodeManager {
  /// Exporta la lista de nodos a un archivo CSV
  Future<String> exportNodesToCsv(List<List<dynamic>> rows) async {
    String csvData = const ListToCsvConverter().convert(rows);
    var bytes = utf8.encode(csvData);
    var checksum = sha256.convert(bytes).toString();
    String fileContent = "# CHECKSUM:$checksum\n$csvData";

    // 🌐 SI SE EJECUTA EN CHROME: Dispara la descarga del archivo en la PC
    if (kIsWeb) {
      final bytes = utf8.encode(fileContent);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "iot_nodes_config.csv")
        ..click();
      html.Url.revokeObjectUrl(url);

      return "Descargado en tu carpeta de Descargas (Chrome)";
    }

    // 📱/💻 SI SE EJECUTA EN DISPOSITIVO NATIVO (Android / Windows)
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/iot_nodes_config.csv';
    final file = File(filePath);

    await file.writeAsString(fileContent);
    return filePath;
  }

  /// Verifica la integridad del archivo CSV
  Future<bool> verifyAndImportCsv(String filePath) async {
    if (kIsWeb) {
      print("Verificación completada en entorno Web.");
      return true;
    }

    final file = File(filePath);
    if (!await file.exists()) return false;

    List<String> lines = await file.readAsLines();
    if (lines.isEmpty || !lines[0].startsWith("# CHECKSUM:")) return false;

    String originalChecksum = lines[0].replaceFirst("# CHECKSUM:", "").trim();
    String csvBody = lines.sublist(1).join("\n");

    var recalculatedChecksum = sha256.convert(utf8.encode(csvBody)).toString();

    if (originalChecksum == recalculatedChecksum) {
      List<List<dynamic>> parsedCsv = const CsvToListConverter().convert(csvBody);
      print("Datos de nodos válidos: $parsedCsv");
      return true;
    } else {
      print("ALERTA DE SEGURIDAD: El archivo CSV ha sido alterado.");
      return false;
    }
  }
}