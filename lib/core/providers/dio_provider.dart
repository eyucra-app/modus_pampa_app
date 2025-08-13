import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un Provider de Riverpod que crea y expone una única instancia de Dio.
///
/// Usar un provider nos permite configurar el cliente HTTP (por ejemplo,
/// añadiendo interceptores para logs o tokens de autenticación) en un
/// solo lugar y reutilizarlo en toda la aplicación.
final dioProvider = Provider<Dio>((ref) {
  // Aquí puedes añadir configuraciones base para Dio
  final options = BaseOptions(
    connectTimeout: const Duration(seconds: 30), // 10 segundos
    receiveTimeout: const Duration(seconds: 30), // 10 segundos
  );

  return Dio(options);
});