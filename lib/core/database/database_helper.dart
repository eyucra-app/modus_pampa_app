import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:modus_pampa_v3/data/models/configuration_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  // Nombre y versión de la base de datos.
  static const _databaseName = "ModusPampaV3.db";
  static const _databaseVersion = 1;

  // --- Nombres de Tablas ---
  static const tableUsers = 'users';
  static const tableAffiliates = 'affiliates';
  static const tableContributions = 'contributions';
  static const tableFines = 'fines';
  static const tablePayments = 'payments';
  static const tableAttendanceLists = 'attendance_lists';
  static const tableAttendanceRecords = 'attendance_records';
  static const tablePendingOperations = 'pending_operations';
  static const tableContributionAffiliates = 'contribution_affiliates';

  // --- Singleton ---
  // Hacemos esta clase un singleton.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Referencia a la base de datos.
  static Database? _database;

  // Getter para la base de datos. La inicializa si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Abre la base de datos (y la crea si no existe).
  _initDatabase() async {
    String path;
    if (kIsWeb) {
      // Para web, usar un nombre simple
      path = _databaseName;
    } else {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, _databaseName);
    }
    return await openDatabase(
      path,
      version: _databaseVersion, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Script SQL para crear la base de datos y sus tablas.
  Future _onCreate(Database db, int version) async {
    // Tabla de Usuarios
    await db.execute('''
      CREATE TABLE $tableUsers (
        uuid TEXT PRIMARY KEY,
        user_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')), 
        updated_at TEXT 
      )
    ''');

    // Tabla de Afiliados
    await db.execute('''
      CREATE TABLE $tableAffiliates (
        uuid TEXT PRIMARY KEY,
        id TEXT UNIQUE NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        ci TEXT UNIQUE NOT NULL,
        phone TEXT,
        original_affiliate_name TEXT DEFAULT '-',
        current_affiliate_name TEXT DEFAULT '-',
        profile_photo_url TEXT,
        credential_photo_url TEXT,
        tags TEXT,
        total_paid REAL DEFAULT 0.0,
        total_debt REAL DEFAULT 0.0,
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
        updated_at TEXT
      )
    ''');

    // Tabla de Aportes
    await db.execute('''
      CREATE TABLE $tableContributions (
        uuid TEXT UNIQUE PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        default_amount REAL NOT NULL,
        is_general BOOLEAN NOT NULL DEFAULT 1, 
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
        updated_at TEXT 
      )
    ''');
    
    // Tabla de enlace entre Aportes y Afiliados (muchos a muchos)
    await db.execute('''
      CREATE TABLE $tableContributionAffiliates (
          uuid TEXT UNIQUE PRIMARY KEY NOT NULL,
          contribution_uuid TEXT NOT NULL,
          affiliate_uuid TEXT NOT NULL,
          amount_to_pay REAL NOT NULL,
          amount_paid REAL DEFAULT 0.0,
          is_paid BOOLEAN DEFAULT 0,
          created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
          updated_at TEXT,
          FOREIGN KEY (contribution_uuid) REFERENCES $tableContributions (uuid) ON DELETE CASCADE,
          FOREIGN KEY (affiliate_uuid) REFERENCES $tableAffiliates (uuid) ON DELETE CASCADE,
          UNIQUE (contribution_uuid, affiliate_uuid)
      )
    ''');

    // Tabla de Multas
    await db.execute('''
      CREATE TABLE $tableFines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL, 
        affiliate_uuid TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL, -- 'Varios', 'Retraso', 'Falta'
        date TEXT NOT NULL,
        amount_paid REAL DEFAULT 0.0,
        is_paid BOOLEAN DEFAULT 0,
        related_attendance_uuid TEXT,
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
        updated_at TEXT,
        FOREIGN KEY (affiliate_uuid) REFERENCES $tableAffiliates (uuid) ON DELETE CASCADE
      )
    ''');

    // Tabla de Pagos (para registrar pagos parciales)
    await db.execute('''
      CREATE TABLE $tablePayments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payment_date TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT,
        related_fine_id INTEGER,
        related_contribution_uuid INTEGER,
        affiliate_uuid_for_contribution TEXT,
        FOREIGN KEY (related_fine_id) REFERENCES $tableFines (id) ON DELETE SET NULL,
        FOREIGN KEY (related_contribution_uuid) REFERENCES $tableContributions (uuid) ON DELETE SET NULL,
        FOREIGN KEY (affiliate_uuid_for_contribution) REFERENCES $tableAffiliates (uuid) ON DELETE SET NULL
      )
    ''');

    // Tabla de Listas de Asistencia
    await db.execute('''
      CREATE TABLE $tableAttendanceLists (
        uuid TEXT PRIMARY KEY, 
        name TEXT NOT NULL,
        status TEXT NOT NULL, -- 'PREPARADA', 'INICIADA', 'TERMINADA', 'FINALIZADA'
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
        updated_at TEXT
      )
    ''');

    // Tabla de Registros de Asistencia
    await db.execute('''
      CREATE TABLE $tableAttendanceRecords (
        uuid TEXT PRIMARY KEY,
        list_uuid TEXT NOT NULL, 
        affiliate_uuid TEXT NOT NULL,
        registered_at TEXT NOT NULL,
        status TEXT NOT NULL, -- 'PRESENTE', 'RETRASO', 'FALTA'
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
        updated_at TEXT,
        FOREIGN KEY (list_uuid) REFERENCES $tableAttendanceLists (uuid) ON DELETE CASCADE,
        FOREIGN KEY (affiliate_uuid) REFERENCES $tableAffiliates (uuid) ON DELETE CASCADE
      )
    ''');
    
    // Tabla para Operaciones Pendientes de Sincronización
    await db.execute('''
      CREATE TABLE $tablePendingOperations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE'
        table_name TEXT NOT NULL,
        data TEXT NOT NULL, -- Payload JSON de la operación
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
      )
    ''');

    // Tabla de configuraciones globales
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY,
        monto_multa_retraso TEXT NOT NULL,
        monto_multa_falta TEXT NOT NULL,
        backend_url TEXT NOT NULL
      )
    ''');
  }


  // Método para manejar las actualizaciones de la base de datos (migraciones)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
   
        
  }

  // Metodos para configuraciones globales
  Future<void> saveSettings(AppSettings settings) async {
    final db = await database;
    await db.insert(
      'app_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Reemplaza si el ID 1 ya existe
    );
  }

  // Obtener la configuración
  Future<AppSettings?> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: [1], // Buscamos la fila con ID 1
    );

    if (maps.isNotEmpty) {
      return AppSettings.fromMap(maps.first);
    }
    return null; // Devuelve null si no hay configuración guardada
  }

  // Puedes añadir un método para cerrar la base de datos si es necesario
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
