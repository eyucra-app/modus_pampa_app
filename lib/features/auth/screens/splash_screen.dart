// lib/features/auth/screens/splash_screen.dart

import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:modus_pampa_v3/core/config/constants.dart';
import 'package:modus_pampa_v3/features/auth/providers/backend_health_provider.dart';
import 'package:modus_pampa_v3/main.dart'; // Importa main para acceder al appInitializerProvider

// 1. Convertimos a un widget con estado para manejar la lógica de inicialización
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Definimos las dos tareas que deben completarse:
    // Tarea 1: La lógica de inicialización que ya teníamos.
    final initialization = ref.read(appInitializerProvider.future);
    // Tarea 2: Una demora mínima para que el logo sea visible.
    final minDisplayTime = Future.delayed(const Duration(seconds: 3));

    // Esperamos a que AMBAS tareas terminen.
    await Future.wait([initialization, minDisplayTime]);
    
    // Una vez completadas, leemos el resultado del estado y navegamos.
    if (mounted) { // Verificamos que el widget siga en pantalla
      final status = ref.read(initialStatusProvider);
      if (status == InitialStatus.offline) {
        context.go(AppRoutes.offlineSplashScreen);
      } else {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // La UI no cambia, sigue mostrando la animación y el estado de la conexión
    final healthCheckState = ref.watch(backendHealthProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DotLottieLoader.fromAsset(
              'assets/animations/loading_animation.lottie',
              frameBuilder: (BuildContext context, DotLottie? dotlottie) {
                if (dotlottie != null) {
                  return Lottie.memory(dotlottie.animations.values.first, width: 250, height: 250);
                } else {
                  return const SizedBox(width: 250, height: 250);
                }
              },
            ),
            const SizedBox(height: 20),
            healthCheckState.when(
              loading: () => const Text("Conectando con el servidor..."),
              error: (err, stack) => const Text("Verificando conexión..."),
              data: (_) => const Text("¡Conexión exitosa! Redirigiendo..."),
            ),
          ],
        ),
      ),
    );
  }
}