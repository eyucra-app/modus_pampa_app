import 'dart:io';
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
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion, 
      onCreate: _onCreate,
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
        role TEXT NOT NULL
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
        total_debt REAL DEFAULT 0.0
      )
    ''');

    // Tabla de Aportes
    await db.execute('''
      CREATE TABLE $tableContributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        is_general BOOLEAN NOT NULL DEFAULT 1
      )
    ''');
    
    // Tabla de enlace entre Aportes y Afiliados (muchos a muchos)
    await db.execute('''
      CREATE TABLE $tableContributionAffiliates (
          contribution_id INTEGER NOT NULL,
          affiliate_uuid TEXT NOT NULL,
          amount_to_pay REAL NOT NULL,
          amount_paid REAL DEFAULT 0.0,
          is_paid BOOLEAN DEFAULT 0,
          FOREIGN KEY (contribution_id) REFERENCES $tableContributions (id) ON DELETE CASCADE,
          FOREIGN KEY (affiliate_uuid) REFERENCES $tableAffiliates (uuid) ON DELETE CASCADE,
          PRIMARY KEY (contribution_id, affiliate_uuid)
      )
    ''');

    // Tabla de Multas
    await db.execute('''
      CREATE TABLE $tableFines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        affiliate_uuid TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL, -- 'Varios', 'Retraso', 'Falta'
        date TEXT NOT NULL,
        amount_paid REAL DEFAULT 0.0,
        is_paid BOOLEAN DEFAULT 0,
        related_attendance_id INTEGER, -- Opcional, para vincular a una lista de asistencia
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
        related_contribution_id INTEGER,
        affiliate_uuid_for_contribution TEXT,
        FOREIGN KEY (related_fine_id) REFERENCES $tableFines (id) ON DELETE SET NULL,
        FOREIGN KEY (related_contribution_id) REFERENCES $tableContributions (id) ON DELETE SET NULL,
        FOREIGN KEY (affiliate_uuid_for_contribution) REFERENCES $tableAffiliates (uuid) ON DELETE SET NULL
      )
    ''');

    // Tabla de Listas de Asistencia
    await db.execute('''
      CREATE TABLE $tableAttendanceLists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL -- 'PREPARADA', 'INICIADA', 'TERMINADA', 'FINALIZADA'
      )
    ''');

    // Tabla de Registros de Asistencia
    await db.execute('''
      CREATE TABLE $tableAttendanceRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id INTEGER NOT NULL,
        affiliate_uuid TEXT NOT NULL,
        registered_at TEXT NOT NULL,
        status TEXT NOT NULL, -- 'PRESENTE', 'RETRASO', 'FALTA'
        FOREIGN KEY (list_id) REFERENCES $tableAttendanceLists (id) ON DELETE CASCADE,
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
        created_at TEXT NOT NULL
      )
    ''');
  }
}
