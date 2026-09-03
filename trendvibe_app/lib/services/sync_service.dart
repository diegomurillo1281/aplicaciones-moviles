import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'database_service.dart';
import 'secure_storage_service.dart';

class SyncService {
  static const int maxRetries = 5;

  Future<void> processSyncQueue() async {
    // 1. Obtener todas las tareas pendientes usando el método seguro de DatabaseService
    final List<Map<String, dynamic>> queue = await DatabaseService.instance.getQueueItems();

    if (queue.isEmpty) return; // Si no hay nada pendiente, no hace nada

    final token = await SecureStorageService().getToken();

    for (var item in queue) {
      String clientUuid = item['client_uuid'];
      String endpoint = item['endpoint'];
      String payload = item['payload'];
      int retryCount = item['retry_count'] ?? 0;

      // Si superó los 5 intentos, lo descartamos
      if (retryCount >= maxRetries) {
        await DatabaseService.instance.deleteQueueItem(clientUuid);
        continue;
      }

      // Intentar enviar al backend Flask
      bool ok = await _enviarAlServidor(endpoint, payload, token);

      if (ok) {
        // ÉXITO: Lo borramos de la lista de pendientes
        await DatabaseService.instance.deleteQueueItem(clientUuid);
      } else {
        // FALLO: Aumentamos el contador de reintentos
        int nuevoReintento = retryCount + 1;
        await DatabaseService.instance.updateQueueRetryCount(clientUuid, nuevoReintento);

        // Espera creciente exponencial: 2^1 = 2s, 2^2 = 4s, 2^3 = 8s...
        int esperaSegundos = pow(2, nuevoReintento).toInt();
        await Future.delayed(Duration(seconds: esperaSegundos));
      }
    }
  }

  Future<bool> _enviarAlServidor(String endpoint, String payload, String? token) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: payload,
      );
      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      return false; // Significa que sigue sin conexión
    }
  }
}