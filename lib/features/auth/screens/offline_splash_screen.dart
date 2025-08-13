// lib/features/auth/screens/offline_splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modus_pampa_v3/core/config/constants.dart';

// 1. Convertido de vuelta a un StatelessWidget, más simple y eficiente.
class OfflineSplashScreen extends StatelessWidget {
  const OfflineSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 80, color: Colors.grey[600]),
              const SizedBox(height: 24),
              Text(
                'Modo sin Conexión',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Para obtener los datos más recientes, se recomienda tener conexión a internet.\n\nLa aplicación funcionará con los datos guardados localmente.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                // 2. El botón ahora siempre está habilitado.
                // La navegación solo ocurre cuando el usuario lo presiona.
                onPressed: () {
                  context.go(AppRoutes.login);
                },
                child: const Text('Continuar sin conexión'),
              )
            ],
          ),
        ),
      ),
    );
  }
}