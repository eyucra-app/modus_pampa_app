import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Claves para SharedPreferences
const String keyFineAmountLate = 'fine_amount_late';
const String keyFineAmountAbsent = 'fine_amount_absent';
const String keyBackendUrl = 'backend_url';

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

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
  String getBackendUrl() {
    return _prefs.getString(keyBackendUrl) ?? 'https://api.example.com';
  }

  Future<void> setBackendUrl(String url) async {
    await _prefs.setString(keyBackendUrl, url);
  }
}

// Provider para acceder al servicio de configuración
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(sharedPreferences);
});

