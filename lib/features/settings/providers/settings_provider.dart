import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/core/providers/dio_provider.dart';
import 'package:modus_pampa_v3/data/models/configuration_model.dart';
import 'package:modus_pampa_v3/data/repositories/configuration_repository.dart';
import 'package:modus_pampa_v3/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. AÑADE LOS NUEVOS STATEPROVIDERS ---
// Estos providers mantendrán el estado reactivo de cada ajuste.
// Se inicializan con los valores guardados en SharedPreferences.

final lateFineAmountProvider = StateProvider<double>((ref) {
  return sharedPreferences.getDouble(keyFineAmountLate) ?? 5.0;
});

final absentFineAmountProvider = StateProvider<double>((ref) {
  return sharedPreferences.getDouble(keyFineAmountAbsent) ?? 20.0;
});

final backendUrlProvider = StateProvider<String>((ref) {
  return sharedPreferences.getString(keyBackendUrl) ?? 'https://modus-pampa-backend-oficial.onrender.com';
});

// Claves para SharedPreferences
const String keyFineAmountLate = 'fine_amount_late';
const String keyFineAmountAbsent = 'fine_amount_absent';
const String keyBackendUrl = 'backend_url';
const String keyLastSyncTimestamp = 'last_sync_timestamp';

class SettingsService {
  final SharedPreferences _prefs;
  final ProviderContainer _container;
  final DatabaseHelper _dbHelper; 

  SettingsService(this._prefs, this._container, this._dbHelper);

  Future<void> fetchAndCacheSettings() async {
    final configRepo = _container.read(configurationRepositoryProvider);
    final remoteSettings = await configRepo.getConfiguration();

    if (remoteSettings != null) {
      print("Configuración obtenida del backend. Guardando localmente...");
      // Guarda en SharedPreferences
      _container.read(lateFineAmountProvider.notifier).state = remoteSettings.montoMultaRetraso;
      _container.read(absentFineAmountProvider.notifier).state = remoteSettings.montoMultaFalta;
      _container.read(backendUrlProvider.notifier).state = remoteSettings.backendUrl;

      await _saveToPrefs(remoteSettings);
      try {
        await _dbHelper.saveSettings(remoteSettings);
        print("✅ Configuración guardada exitosamente en la base de datos local.");
      } catch (e) {
        print("❌ Error al guardar configuración en la base de datos local: $e");
      }
    } else {
      print("No se pudo obtener la configuración del backend. Se usarán los valores locales/por defecto.");
    }
  }

  /// Guarda la configuración localmente y en el backend.
  Future<bool> saveSettings(AppSettings settings) async {
    final configRepo = _container.read(configurationRepositoryProvider);

    // Actualiza el backend primero
    final success = await configRepo.updateConfiguration(settings);

    if (success) {
      // Si el backend se actualizó, guarda los valores localmente
      _container.read(lateFineAmountProvider.notifier).state = settings.montoMultaRetraso;
      _container.read(absentFineAmountProvider.notifier).state = settings.montoMultaFalta;
      _container.read(backendUrlProvider.notifier).state = settings.backendUrl;

      // *** NUEVO: Guarda también en la base de datos local ***
      await _saveToPrefs(settings);
      try {
        await _dbHelper.saveSettings(settings);
        print("✅ Configuración guardada en backend y localmente.");
      } catch (e) {
        print("❌ Error al guardar configuración en la base de datos local: $e");
        print("Configuración guardada en backend pero falló el guardado local.");
      }
    } else {
      print("Error al guardar la configuración en el backend. Los cambios no se han guardado.");
    }
    return success;
  }

  Future<void> _saveToPrefs(AppSettings settings) async {
    await _prefs.setDouble(keyFineAmountLate, settings.montoMultaRetraso);
    await _prefs.setDouble(keyFineAmountAbsent, settings.montoMultaFalta);
    await _prefs.setString(keyBackendUrl, settings.backendUrl);
  }

  DateTime? getLastSyncTimestamp() {
    final timestampString = _prefs.getString(keyLastSyncTimestamp);
    if (timestampString != null) {
      return DateTime.tryParse(timestampString);
    }
    return null;
  }

  Future<void> setLastSyncTimestamp(DateTime timestamp) async {
    await _prefs.setString(keyLastSyncTimestamp, timestamp.toIso8601String());
  }

  // -- Monto de Multa por Retraso --
  double getFineAmountLate() {
    return _prefs.getDouble(keyFineAmountLate) ?? 5.0; // Valor por defecto: 5.0
  }

  Future<void> setFineAmountLate(double value) async {
    await _prefs.setDouble(keyFineAmountLate, value);
  }

  // -- Monto de Multa por Falta --
  double getFineAmountAbsent() {
    return _prefs.getDouble(keyFineAmountAbsent) ?? 20.0; // Valor por defecto: 20.0
  }

  Future<void> setFineAmountAbsent(double value) async {
    await _prefs.setDouble(keyFineAmountAbsent, value);
  }
  
  // -- URL del Backend --
  //! PARA NUEVAS INSTALACIONES Y SI HAY NUEVA URL DEL BACKEND SE DEBE CAMBIAR AQUI 
  String getBackendUrl() {
    final storedUrl = _prefs.getString(keyBackendUrl);
    final defaultUrl = 'https://modus-pampa-backend-oficial.onrender.com';
    final finalUrl = storedUrl ?? defaultUrl;
    
    print("🔧 Backend URL - Stored: $storedUrl, Default: $defaultUrl, Using: $finalUrl");
    
    // Si hay una URL vieja guardada, actualizarla al nuevo backend
    if (storedUrl != null && storedUrl.contains('modus-pampa-backend.onrender.com')) {
      print("🔄 Detectada URL antigua, actualizando a la nueva...");
      setBackendUrl(defaultUrl);
      return defaultUrl;
    }
    
    return finalUrl;
  }

  Future<void> setBackendUrl(String url) async {
    await _prefs.setString(keyBackendUrl, url);
  }
}

// Provider para acceder al servicio de configuración
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(sharedPreferences, ref.container, dbHelper);
});
final configurationRepositoryProvider = Provider<ConfigurationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  // Leemos el backendUrl desde el nuevo provider reactivo
  final backendUrl = ref.watch(backendUrlProvider);
  // Aquí devolvemos una implementación anónima o una clase que utilice el backendUrl
  return ConfigurationRepository(dio, ref.watch(settingsServiceProvider));
});

