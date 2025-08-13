// lib/data/repositories/configuration_repository.dart

import 'package:dio/dio.dart';
import 'package:modus_pampa_v3/data/models/configuration_model.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';

class ConfigurationRepository {
  final Dio _dio;
  final SettingsService _settingsService;

  ConfigurationRepository(this._dio, this._settingsService);

  // Obtiene la configuración desde el backend
  Future<AppSettings?> getConfiguration() async {
    try {
      final backendUrl = _settingsService.getBackendUrl();
      final response = await _dio.get('$backendUrl/api/configuration');

      if (response.statusCode == 200 && response.data != null) {
        return AppSettings.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error al obtener la configuración del backend: $e');
      return null;
    }
  }

  // Actualiza la configuración en el backend
  Future<bool> updateConfiguration(AppSettings settings) async {
    try {
      final backendUrl = _settingsService.getBackendUrl();
      final response = await _dio.patch(
        '$backendUrl/api/configuration',
        data: settings.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error al actualizar la configuración en el backend: $e');
      return false;
    }
  }
}