// lib/features/auth/providers/backend_health_provider.dart
import 'package:connectivity_plus/connectivity_plus.dart'; // ¡AÑADE ESTE IMPORT!
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ¡AÑADE ESTE IMPORT!
import 'package:modus_pampa_v3/core/providers/dio_provider.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';

// Este provider intentará conectarse al backend hasta que tenga éxito.
final backendHealthProvider = FutureProvider<bool>((ref) async {
  // Primero, revisamos el estado de la conexión de forma síncrona.
  final connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult.contains(ConnectivityResult.none)) {
    // Si no hay conexión, lanzamos una excepción controlada INMEDIATAMENTE.
    // Esto evita la llamada de red y el error "Failed host lookup".
    throw Exception('Modo sin conexión detectado.');
  }
  
  final dio = ref.watch(dioProvider);
  final settings = ref.watch(settingsServiceProvider);
  final backendUrl = settings.getBackendUrl();
  final healthCheckEndpoint = '$backendUrl/api/affiliates';

  int attempt = 0;
  while (true) {
    attempt++;
    print("🚀 Backend Health Check - Intento #$attempt a: $healthCheckEndpoint");
    try {
      await dio.get(healthCheckEndpoint);
      print("✔️ Backend está activo.");
      return true;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionTimeout) {
        print("⏳ Backend todavía no responde, reintentando en 3 segundos...");
        await Future.delayed(const Duration(seconds: 3));
      } else {
        print("❌ Error de Health Check: ${e.message}");
        throw Exception("No se pudo conectar al servidor: ${e.message}");
      }
    } catch (e) {
       print("❌ Error inesperado en Health Check: ${e.toString()}");
       throw Exception("Error desconocido al conectar con el servidor.");
    }
  }
});

enum InitialStatus {
  checking,
  online,
  offline,
}

final initialStatusProvider = StateProvider<InitialStatus>((ref) => InitialStatus.checking);