import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/models/attendance_model.dart';
import 'package:sqflite/sqflite.dart';

class AttendanceRepository {
  final DatabaseHelper _dbHelper;

  AttendanceRepository(this._dbHelper);

  // --- Listas de Asistencia ---

  // Crea una nueva lista de asistencia.
  Future<int> createAttendanceList(AttendanceList list) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableAttendanceLists,
      list.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtiene todas las listas de asistencia creadas.
  Future<List<AttendanceList>> getAllAttendanceLists() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableAttendanceLists,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => AttendanceList.fromMap(map)).toList();
  }

  // Actualiza el estado de una lista (ej: de PREPARADA a INICIADA).
  Future<void> updateListStatus(int listId, AttendanceListStatus status) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableAttendanceLists,
      {'status': status.toString().split('.').last},
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  Future<void> deleteAttendanceList(int listId) async {
    final db = await _dbHelper.database;
    // ON DELETE CASCADE en la tabla de registros se encargará de los hijos.
    // Las multas relacionadas se deben manejar en la lógica de negocio.
    await db.delete(
      DatabaseHelper.tableAttendanceLists,
      where: 'id = ?',
      whereArgs: [listId],
    );
  }


  // --- Registros de Asistencia ---

  // Añade un registro de asistencia de un afiliado a una lista.
  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableAttendanceRecords,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtiene todos los registros para una lista de asistencia específica.
  Future<List<AttendanceRecord>> getRecordsForList(int listId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableAttendanceRecords,
      where: 'list_id = ?',
      whereArgs: [listId],
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  // Verifica si un afiliado ya ha sido registrado en una lista.
  Future<bool> isAffiliateRegistered(int listId, String affiliateUuid) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableAttendanceRecords,
      where: 'list_id = ? AND affiliate_uuid = ?',
      whereArgs: [listId, affiliateUuid],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<void> deleteAttendanceRecord(int recordId) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableAttendanceRecords,
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<List<AttendanceRecord>> getAllRecordsForAffiliate(String affiliateUuid) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableAttendanceRecords,
      where: 'affiliate_uuid = ?',
      whereArgs: [affiliateUuid],
      orderBy: 'registered_at DESC',
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }
}
