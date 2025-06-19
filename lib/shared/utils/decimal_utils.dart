import 'dart:math';

/// Proporciona funciones de utilidad para manejar cálculos decimales de forma segura.
class DecimalUtils {
  /// Redondea un valor [double] a un número específico de decimales.
  ///
  /// Por defecto, redondea a 2 decimales, ideal para cálculos de moneda.
  /// Ejemplo: round(1.987) devuelve 1.99
  /// Ejemplo: round(0.0900000001) devuelve 0.09
  static double round(double value, {int places = 2}) {
    final num mod = pow(10.0, places);
    return ((value * mod).round().toDouble() / mod);
  }
}
