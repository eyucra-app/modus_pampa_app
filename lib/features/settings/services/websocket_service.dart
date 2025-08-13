import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/features/settings/services/sync_service.dart';


class WebSocketService {
  final Ref _ref;
  IO.Socket? _socket;

  WebSocketService(this._ref);

  void connect() {
    if (_socket?.connected ?? false) {
      print("[WebSocket] Conexión ya establecida.");
      return;
    }

    final backendUrl = _ref.read(settingsServiceProvider).getBackendUrl();
    print('[WebSocket] Intentando conectar a $backendUrl con socket.io...');

    try {
      _socket = IO.io(backendUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true,
      });

      _socket!.onConnect((_) {
        print('✅ [WebSocket] Conectado exitosamente al servidor.');
      });

      _socket!.onConnectError((data) {
        print('❌ [WebSocket] Error de conexión: $data');
      });

      _socket!.onDisconnect((_) {
        print('🔌 [WebSocket] Desconectado del servidor.');
      });

      // --- MANEJO DE EVENTOS CENTRALIZADO Y ROBUSTO ---
      // Todos los eventos de cambio ahora llaman al mismo manejador.
      _socket!.on('affiliatesChanged', (data) => _handleDataChange(data));
      _socket!.on('finesChanged', (data) => _handleDataChange(data));
      _socket!.on('contributionsChanged', (data) => _handleDataChange(data));
      _socket!.on('attendanceChanged', (data) => _handleDataChange(data));
      _socket!.on('configurationChanged', (data) => _handleDataChange(data));
      
    } catch (e) {
      print('❌ [WebSocket] Fallo catastrófico al inicializar: $e');
    }
  }

  /// **MÉTODO ÚNICO Y SIMPLIFICADO**
  /// Para cualquier cambio detectado en el servidor, la acción más segura
  /// es realizar un "pull" para sincronizar el estado local con el del servidor.
  /// Esto asegura la consistencia de los datos en todos los dispositivos.
  void _handleDataChange(dynamic eventData) {
    print('🔄 [WebSocket] Cambio detectado en el servidor: $eventData. Iniciando sincronización completa (pull).');
    // La solución más robusta es siempre traer los últimos cambios del servidor,
    // que es la única fuente de verdad.
    _ref.read(syncServiceProvider).pullChanges();
  }

  void emit(String event, dynamic data) {
    if (_socket?.connected ?? false) {
      _socket!.emit(event, data);
      print('🚀 [WebSocket] Evento emitido: "$event"');
    } else {
      print('⚠️ [WebSocket] No se puede emitir. Socket no conectado.');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    print('[WebSocket] Conexión cerrada y recursos liberados.');
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref);
});