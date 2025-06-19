import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:modus_pampa_v3/app.dart';
import 'package:modus_pampa_v3/core/database/database_helper.dart';

// Variables globales para acceder a instancias clave.
// Es una forma de Service Locator simple, útil para acceder desde fuera de la UI.
late SharedPreferences sharedPreferences;
late DatabaseHelper dbHelper;

Future<void> main() async {


  // Revisa si la plataforma es de escritorio
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Inicializa el driver FFI de sqflite
    sqfliteFfiInit();
    // Establece la factoría de la base de datos para usar la implementación FFI
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
  
  // Ejecuta la aplicación envolviéndola en un ProviderScope para Riverpod.
  runApp(const ProviderScope(child: ModusPampaApp()));
}
