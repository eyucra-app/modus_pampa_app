import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/models/attendance_model.dart';
import 'package:modus_pampa_v3/data/models/pending_operation_model.dart';
import 'package:modus_pampa_v3/data/repositories/pending_operation_repository.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:sqflite/sqflite.dart';

class AttendanceRepository {
  final DatabaseHelper _dbHelper;
  final PendingOperationRepository _pendingOpRepo;
  final Dio _dio; // Agregado
  final SettingsService _settingsService; // Agregado

  AttendanceRepository(this._dbHelper, this._pendingOpRepo,this._dio, this._settingsService);

  // Método auxiliar para enviar al backend (similar al de AffiliateRepository)
  Future<Response?> _sendToBackend(String endpoint, OperationType type, Map<String, dynamic> data) async {
    final backendUrl = _settingsService.getBackendUrl();
    try {
      switch (type) {
        case OperationType.CREATE:
          return await _dio.post('$backendUrl/api$endpoint', data: data);
        case OperationType.UPDATE:
          // Asumiendo que las actualizaciones usan un ID en la URL.
          // Para AttendanceList se usa 'uuid', para AttendanceRecord también 'uuid'.
          final idKey = endpoint.contains('attendance_lists') ? 'uuid' : 'uuid'; // Cambiado a 'uuid'
          return await _dio.put('$backendUrl/api$endpoint/${data[idKey]}', data: data);
        case OperationType.DELETE:
          // Para eliminación, data debe contener el UUID.
          final idKey = endpoint.contains('attendance_lists') ? 'uuid' : 'uuid'; // Cambiado a 'uuid'
          return await _dio.delete('$backendUrl/api$endpoint/${data[idKey]}');
        default:
          return null;
      }
    } on DioException catch (e) {
      print('Error al enviar asistencia a backend: ${e.message}');
      return null;
    } catch (e) {
      print('Error inesperado al enviar asistencia a backend: $e');
      return null;
    }
  }

  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.ethernet);
  }

  // --- Listas de Asistencia ---

  // Crea una nueva lista de asistencia.
  Future<int> createAttendanceList(AttendanceList list) async {
    final db = await _dbHelper.database;
    // Solo guardado local
    return await db.insert(
      DatabaseHelper.tableAttendanceLists,
      list.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<void> updateAttendanceList(AttendanceList list) async {
    final db = await _dbHelper.database;
    // Solo actualización local
    await db.update(
      DatabaseHelper.tableAttendanceLists,
      list.toMap(),
      where: 'uuid = ?',
      whereArgs: [list.uuid],
    );
  }

  Future<void> deleteAttendanceList(AttendanceList list) async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableAttendanceLists, where: 'uuid = ?', whereArgs: [list.uuid]);
    
    if (await _isConnected()) {
      try {
        final backendUrl = _settingsService.getBackendUrl();
        await _dio.delete('$backendUrl/api/attendance/${list.uuid}');
        print('Lista de asistencia #${list.uuid} eliminada en backend y localmente.');
        return;
      } catch (e) {
        print('Error al eliminar lista en backend, se creará op. pendiente. Error: $e');
      }
    }

    await _pendingOpRepo.createPendingOperation(PendingOperation(
      operationType: OperationType.DELETE, tableName: DatabaseHelper.tableAttendanceLists,
      data: {'uuid': list.uuid}, createdAt: DateTime.now(),
    ));
    print('Eliminación de lista #${list.uuid} guardada como operación pendiente.');
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
  // Este método ahora podría simplificarse o ser redundante si `updateAttendanceList` es más general.
  // Lo ajusto para usar UUID si es posible, asumiendo que el modelo lo tiene.
  Future<void> updateListStatus(String listUuid, AttendanceListStatus status) async {
    // Primero, recupera la lista para obtener su UUID
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAttendanceLists,
      where: 'uuid = ?',
      whereArgs: [listUuid],
    );
    if (maps.isEmpty) return; // Lista no encontrada

    final currentList = AttendanceList.fromMap(maps.first);
    final updatedList = currentList.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    
    // Usa el método updateAttendanceList que ya maneja la sincronización
    await updateAttendanceList(updatedList);
  }


  // --- Registros de Asistencia ---

  // Añade un registro de asistencia de un afiliado a una lista.
  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    final db = await _dbHelper.database;
    // Solo guardado local
    await db.insert(
      DatabaseHelper.tableAttendanceRecords,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAttendanceRecord(String recordUuid) async {
    final db = await _dbHelper.database;
    // Solo eliminación local
    await db.delete(
      DatabaseHelper.tableAttendanceRecords,
      where: 'uuid = ?',
      whereArgs: [recordUuid],
    );
  }

  // Obtiene todos los registros para una lista de asistencia específica.
  Future<List<AttendanceRecord>> getRecordsForList(String listUuid) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableAttendanceRecords,
      where: 'list_uuid = ?',
      whereArgs: [listUuid],
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  // Verifica si un afiliado ya ha sido registrado en una lista.
  Future<bool> isAffiliateRegistered(String listUuid, String affiliateUuid) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableAttendanceRecords,
      where: 'list_uuid = ? AND affiliate_uuid = ?',
      whereArgs: [listUuid, affiliateUuid],
      limit: 1,
    );
    return maps.isNotEmpty;
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

  Future<void> syncFinalizedList(AttendanceList list, List<AttendanceRecord> records) async {
    final payload = {
      ...list.toMap(),
      'records': records.map((r) => {
        'uuid': r.uuid, 'affiliate_uuid': r.affiliateUuid,
        'status': r.status.name, 'registered_at': r.registeredAt.toIso8601String(),
      }).toList(),
    };

    if (!(await _isConnected())) {
      await _pendingOpRepo.createPendingOperation(PendingOperation(
        operationType: OperationType.CREATE, tableName: DatabaseHelper.tableAttendanceLists,
        data: payload, createdAt: DateTime.now(),
      ));
      print('Lista de asistencia #${list.uuid} guardada para sincronización posterior.');
      return;
    }
    
    try {
      final backendUrl = _settingsService.getBackendUrl();
      await _dio.post('$backendUrl/api/attendance', data: payload);
      print('Lista de asistencia #${list.uuid} sincronizada con éxito.');
    } catch (e) {
      print('Error al sincronizar lista de asistencia, guardando como pendiente. Error: $e');
      await _pendingOpRepo.createPendingOperation(PendingOperation(
        operationType: OperationType.CREATE, tableName: DatabaseHelper.tableAttendanceLists,
        data: payload, createdAt: DateTime.now(),
      ));
    }
  }


  Future<void> upsertAttendanceListWithRecords(AttendanceList list, List<AttendanceRecord> records) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Guarda o reemplaza la lista principal
      await txn.insert(DatabaseHelper.tableAttendanceLists, list.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      // 2. Borra todos los registros locales existentes para esa lista (por su UUID)
      await txn.delete(DatabaseHelper.tableAttendanceRecords, where: 'list_uuid = ?', whereArgs: [list.uuid]);
      
      // 3. Inserta los nuevos registros que vienen del servidor
      final batch = txn.batch();
      for (final record in records) {
        batch.insert(DatabaseHelper.tableAttendanceRecords, record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

    Future<void> deleteLocally(String listUuid) async {
    final db = await _dbHelper.database;
    // ON DELETE CASCADE se encargará de borrar los registros de asistencia asociados
    await db.delete(DatabaseHelper.tableAttendanceLists, where: 'uuid = ?', whereArgs: [listUuid]);
    print('Lista de asistencia con uuid: $listUuid eliminada localmente.');
  }
}