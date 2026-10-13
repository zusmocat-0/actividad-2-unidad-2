import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'package:universal_html/html.dart' as html;

class SyncService {
  static final SyncService instance = SyncService._init();
  StreamSubscription? _onlineSubscription;
  bool _isSyncing = false;

  SyncService._init();

  // Escuchar cuando el navegador recupera la conexión a Internet
  void startAutoSync(Function onSyncComplete) {
    if (kIsWeb) {
      _onlineSubscription = html.window.onOnline.listen((_) async {
        print("🌐 Conexión detectada en Chrome. Iniciando sincronización...");
        await syncPendingData();
        onSyncComplete();
      });
    }
  }

  // Proceso de Sincronización Automática
  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Obtener registros pendientes (is_synced = 0)
      final unsynced = await DatabaseHelper.instance.getUnsyncedReadings();
      
      if (unsynced.isEmpty) {
        print("No hay registros pendientes de sincronizar.");
        return;
      }

      print("Sincronizando ${unsynced.length} registros con la Nube...");

      // 2. Simular el envío a la Nube (API REST / Firestore)
      for (var reading in unsynced) {
        await Future.delayed(const Duration(milliseconds: 300)); // Latencia de red
        
        // 3. Confirmación: Marcar como sincronizado (is_synced = 1) sin duplicar
        if (reading.id != null) {
          await DatabaseHelper.instance.markAsSynced(reading.id!);
        }
      }
      print("✅ Sincronización completada exitosamente.");
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _onlineSubscription?.cancel();
  }
}