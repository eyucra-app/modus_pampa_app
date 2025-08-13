

class AppSettings {
  final double montoMultaRetraso;
  final double montoMultaFalta;
  final String backendUrl;

  AppSettings({
    required this.montoMultaRetraso,
    required this.montoMultaFalta,
    required this.backendUrl,
  });

  // Valores por defecto si no hay nada en la BD local ni en el backend
  factory AppSettings.defaults() => AppSettings(
        montoMultaRetraso: double.parse('5.0'),
        montoMultaFalta: double.parse('20.0'),
        backendUrl: 'https://modus-pampa-backend-oficial.onrender.com',
      );

  // De JSON (API) a AppSettings
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      montoMultaRetraso: double.parse(json['monto_multa_retraso'].toString()),
      montoMultaFalta: double.parse(json['monto_multa_falta'].toString()),
      backendUrl: json['backend_url'] as String,
    );
  }

  // De AppSettings a JSON (para enviar a la API)
  Map<String, dynamic> toJson() {
    return {
      'monto_multa_retraso': montoMultaRetraso.toString(),
      'monto_multa_falta': montoMultaFalta.toString(),
      'backend_url': backendUrl,
    };
  }

  // De Map (Base de datos local) a AppSettings
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      montoMultaRetraso: double.parse(map['monto_multa_retraso']),
      montoMultaFalta: double.parse(map['monto_multa_falta']),
      backendUrl: map['backend_url'],
    );
  }

  // De AppSettings a Map (para guardar en la base de datos local)
  Map<String, dynamic> toMap() {
    return {
      // Usaremos un ID fijo (1) porque solo habrá una fila de configuración
      'id': 1, 
      'monto_multa_retraso': montoMultaRetraso.toString(),
      'monto_multa_falta': montoMultaFalta.toString(),
      'backend_url': backendUrl,
    };
  }
}