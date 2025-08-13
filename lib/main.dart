import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:modus_pampa_v3/features/auth/providers/backend_health_provider.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/features/settings/services/sync_service.dart';
import 'package:modus_pampa_v3/core/providers/dio_provider.dart';
import 'package:modus_pampa_v3/data/models/user_model.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/auth/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:modus_pampa_v3/app.dart';
import 'package:modus_pampa_v3/core/database/database_helper.dart';

// Variables globales para acceder a instancias clave.
// Es una forma de Service Locator simple, útil para acceder desde fuera de la UI.
late SharedPreferences sharedPreferences;
late DatabaseHelper dbHelper;

// Declarar el ProviderContainer a nivel global o como una variable tardía
// para poder acceder a él antes de runApp.
late ProviderContainer globalContainer; // Se declara aquí para ser accesible

final appInitializerProvider = FutureProvider<void>((ref) async {
  
  // Lógica de inicialización (sin demoras artificiales).
  final connectivityResult = await (Connectivity().checkConnectivity());
  final isOffline = connectivityResult.contains(ConnectivityResult.none);

  if (!isOffline) {
    try {
      final isBackendReady = await ref.read(backendHealthProvider.future);
      if (isBackendReady) {
        print("✔️ Backend activo. Sincronizando configuraciones y datos...");
        await ref.read(settingsServiceProvider).fetchAndCacheSettings();
        // Ejecutar sincronización inicial simple para web
        print("🔄 Iniciando sincronización web simplificada...");
        
        // Para web, vamos a hacer una sincronización más directa
        if (kIsWeb) {
          print("🌐 Modo web detectado, iniciando descarga directa de datos...");
          _initializeWebData(ref);
        } else {
          // Para plataformas nativas usar el método normal
          ref.read(syncServiceProvider).pullChanges().then((logs) {
            print("📥 Pull completado. Logs:");
            for (final log in logs) {
              print("  $log");
            }
          }).catchError((error) {
            print("❌ Error durante pull: $error");
          });
          
          // Push en segundo plano
          ref.read(syncServiceProvider).pushChanges().then((pushLogs) {
            print("📤 Push completado. Logs:");
            for (final log in pushLogs) {
              print("  $log");
            }
          });
        }
        // --- 1. ACTUALIZA EL ESTADO A 'ONLINE' ---
        ref.read(initialStatusProvider.notifier).state = InitialStatus.online;
      } else {
        print("❌ Backend no disponible. Entrando en modo offline.");
        ref.read(initialStatusProvider.notifier).state = InitialStatus.offline;
      }
    } catch (e) {
      print("❌ Error al conectar con backend: $e");
      print("📱 Entrando en modo offline por error de conexión.");
      ref.read(initialStatusProvider.notifier).state = InitialStatus.offline;
    }
  } else {
    // --- 2. logica offline ---
      // En lugar de navegar, simplemente actualizamos el estado del provider.
    print("📱 Modo Offline. Notificando a la UI para redirigir.");
    ref.read(initialStatusProvider.notifier).state = InitialStatus.offline;
  }
});

// Función específica para inicializar datos en web
void _initializeWebData(Ref ref) async {
  try {
    print("📦 Descargando datos de usuarios para web...");
    
    // Test diferentes contraseñas posibles
    final commonPasswords = ["Test.123", "test123", "Test123", "TEST123", "123", "password", "admin"];
    final storedHash = "faba5db20745c961eb5faf80024f09d28dbec03b92b37996ec27173f13431f9e";
    print("🧪 Hash almacenado en backend: $storedHash");
    
    for (final testPass in commonPasswords) {
      final testHash = sha256.convert(utf8.encode(testPass)).toString();
      final matches = testHash == storedHash;
      print("🧪 TEST: '$testPass' = $testHash ${matches ? '✅ MATCH!' : ''}");
    }
    
    final dio = ref.read(dioProvider);
    final settingsService = ref.read(settingsServiceProvider);
    final backendUrl = settingsService.getBackendUrl();
    
    // Descargar usuarios directamente
    final usersResponse = await dio.get('$backendUrl/api/users');
    if (usersResponse.statusCode == 200 && usersResponse.data != null) {
      final userRepo = ref.read(authRepositoryProvider);
      print("📋 Datos brutos de usuarios recibidos: ${usersResponse.data}");
      
      final users = (usersResponse.data as List).map((userData) => User.fromMap(userData)).toList();
      
      for (final user in users) {
        print("👤 Guardando usuario: email=${user.email}, role=${user.role}");
        await userRepo.upsertUser(user);
      }
      print("✅ ${users.length} usuarios descargados y guardados en web");
      
      // Verificar que se guardaron correctamente
      final savedUsers = await userRepo.getAllUsers();
      print("🔍 Usuarios verificados en DB local: ${savedUsers.length}");
      for (final savedUser in savedUsers) {
        print("  - ${savedUser.email} (${savedUser.role})");
      }
    }
    
    // Descargar afiliados
    final affiliatesResponse = await dio.get('$backendUrl/api/affiliates');
    if (affiliatesResponse.statusCode == 200 && affiliatesResponse.data != null) {
      final affiliateRepo = ref.read(affiliateRepositoryProvider);
      final affiliates = (affiliatesResponse.data as List).map((data) => Affiliate.fromMap(data)).toList();
      
      for (final affiliate in affiliates) {
        await affiliateRepo.upsertAffiliate(affiliate);
      }
      print("✅ ${affiliates.length} afiliados descargados y guardados en web");
    }
    
    print("🎉 Inicialización de datos web completada");
  } catch (e) {
    print("❌ Error en inicialización web: $e");
  }
}

Future<void> main() async {
  if (kIsWeb) {
    // Configura sqflite para web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Inicializa el driver FFI de sqflite para escritorio
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Asegura que los bindings de Flutter estén inicializados antes de usar plugins.
  WidgetsFlutterBinding.ensureInitialized();


  await initializeDateFormatting('es_ES', null);

  // Inicializa SharedPreferences para almacenamiento clave-valor.
  sharedPreferences = await SharedPreferences.getInstance();

  // Inicializa nuestra base de datos SQFlite.
  dbHelper = DatabaseHelper.instance;
  await dbHelper.database; // Llama al getter para asegurar la creación de la DB.

  // Inicializa el ProviderContainer de forma global.
  globalContainer = ProviderContainer();

  // "Leemos" el syncTriggerProvider para activarlo.
  // Esto hará que el StreamProvider de conectividad comience a escuchar
  // y, en consecuencia, el SyncService se active cuando la conexión esté disponible.
  globalContainer.read(syncTriggerProvider); //

  // Ejecuta la aplicación envolviéndola en un ProviderScope para Riverpod.
  runApp(
    UncontrolledProviderScope( // Usar UncontrolledProviderScope con el container global
      container: globalContainer,
      child: const ModusPampaApp(),
    ),
  );
}
