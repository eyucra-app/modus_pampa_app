import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/core/config/theme.dart';
import 'package:modus_pampa_v3/core/navigation/app_router.dart';
import 'package:modus_pampa_v3/core/providers/theme_provider.dart';

class ModusPampaApp extends ConsumerWidget {
  const ModusPampaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha el proveedor del tema para re-renderizar la app cuando cambie.
    final themeMode = ref.watch(themeNotifierProvider);
    // Obtiene la configuración del router.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Modus Pampa V3',
      debugShowCheckedModeBanner: false,
      
      // Configuración de los temas de la aplicación.
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Configuración del router para la navegación.
      routerConfig: router,
    );
  }
}
