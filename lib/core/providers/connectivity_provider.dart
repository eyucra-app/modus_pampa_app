import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que expone el stream de cambios de conectividad.
/// 
/// La UI puede escuchar este provider para reaccionar en tiempo real
/// a cuando el dispositivo se conecta o desconecta de internet.
/// Utiliza el plugin `connectivity_plus`.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  if (kIsWeb) {
    // Para web, crear un stream que inicie con WiFi inmediatamente
    print("🌐 Web detectado - Creando stream de conectividad web");
    return Stream.value([ConnectivityResult.wifi]).asBroadcastStream();
  } else {
    // Para plataformas nativas usar el stream normal
    return Connectivity().onConnectivityChanged.handleError((error) {
      print("⚠️ Error en connectivity stream: $error");
      // Fallback en caso de error
      return Connectivity().checkConnectivity();
    });
  }
});
