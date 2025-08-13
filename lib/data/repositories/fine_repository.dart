// fine_repository.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:modus_pampa_v3/data/models/pending_operation_model.dart';
import 'package:modus_pampa_v3/data/repositories/pending_operation_repository.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:sqflite/sqflite.dart';

class FineRepository {
  final DatabaseHelper _dbHelper;
  final PendingOperationRepository _pendingOpRepo;
  final Dio _dio;
  final SettingsService _settingsService;

  FineRepository(this._dbHelper, this._pendingOpRepo, this._dio, this._settingsService);

  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<Response?> _sendToBackend(String endpoint, OperationType type, Map<String, dynamic> data) async {
    final backendUrl = _settingsService.getBackendUrl();
    try {
      switch (type) {
        case OperationType.CREATE:
          return await _dio.post('$backendUrl/api$endpoint', data: data);
        case OperationType.UPDATE:
          return await _dio.put('$backendUrl/api$endpoint/${data['uuid']}', data: data);
        case OperationType.DELETE:
          // Usamos 'uuid' en lugar de 'id' para el borrado
          return await _dio.delete('$backendUrl/api$endpoint/${data['uuid']}'); 
        default:
          return null;
      }
    } on DioException catch (e) {
      print('Error al enviar multa a backend: ${e.message}');
      return null;
    } catch (e) {
      print('Error inesperado al enviar multa a backend: $e');
      return null;
    }
  }

  Future<void> payFine(int fineId, double paymentAmount) async {
    final db = await _dbHelper.database;
    Map<String, dynamic>? opData;

    // --- PASO 1: Transacción corta solo para la BD local ---
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> maps = await txn.query(DatabaseHelper.tableFines, where: 'id = ?', whereArgs: [fineId]);
      if (maps.isNotEmpty) {
        final fine = Fine.fromMap(maps.first);
        final newAmountPaid = fine.amountPaid + paymentAmount;
        final isPaid = newAmountPaid >= fine.amount;
        final updatedData = {'amount_paid': newAmountPaid, 'is_paid': isPaid ? 1 : 0};
        
        await txn.update(DatabaseHelper.tableFines, updatedData, where: 'id = ?', whereArgs: [fineId]);
        
        opData = fine.toMap()..addAll(updatedData);
      }
    });

    if (opData == null) {
      print('Multa con ID $fineId no encontrada para pagar.');
      return;
    }

    // --- PASO 2: Después de la transacción, llamar a la red ---
    if (await _isConnected()) {
        final response = await _sendToBackend('/fines', OperationType.UPDATE, opData!);
        if (response != null && response.statusCode == 200) {
          print('Pago de multa registrado en backend y localmente.');
          return; // Éxito
        }
    }

    // --- PASO 3: Si falla, crear operación pendiente ---
    final op = PendingOperation(operationType: OperationType.UPDATE, tableName: DatabaseHelper.tableFines, data: opData!, createdAt: DateTime.now());
    await _pendingOpRepo.createPendingOperation(op);
    print('Pago de multa guardado como operación pendiente.');
  }

  
  Future<void> createFine(Fine fine) async {
    final db = await _dbHelper.database;

    final fineMap = fine.toMap();

    final id = await db.insert(
      DatabaseHelper.tableFines, 
      fineMap, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );

    final fineWithId = fineMap..['id'] = id;

    if (await _isConnected()) {
      final response = await _sendToBackend('/fines', OperationType.CREATE, fineWithId);
      // La comprobación del status code 200 ya es correcta.
      if (response != null && response.statusCode == 200) {
        print('Multa creada en backend y localmente.');
        return;
      }
    }
    
    final op = PendingOperation(
      operationType: OperationType.CREATE, 
      tableName: DatabaseHelper.tableFines, 
      data: fineWithId, 
      createdAt: DateTime.now()
    );
    await _pendingOpRepo.createPendingOperation(op);
    print('Multa guardada como operación pendiente.');
  }

  Future<List<Fine>> getFinesByAttendanceList(String listUuid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableFines,
      where: 'related_attendance_uuid = ?',
      whereArgs: [listUuid],
    );
    return maps.map((map) => Fine.fromMap(map)).toList();
  }

  Future<List<Fine>> getFinesForAffiliate(String affiliateUuid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableFines,
      where: 'affiliate_uuid = ?',
      whereArgs: [affiliateUuid],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Fine.fromMap(maps[i]));
  }

  Future<List<String>> getAffiliateUuidsWithFines() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT affiliate_uuid FROM ${DatabaseHelper.tableFines} WHERE is_paid = 0'
    );
    return List.generate(maps.length, (i) => maps[i]['affiliate_uuid'] as String);
  }

  Future<void> deleteFine(Fine fine) async {
    final db = await _dbHelper.database;
    // Usamos el id local para borrar en la base de datos de SQLite
    await db.delete(DatabaseHelper.tableFines, where: 'id = ?', whereArgs: [fine.id]);

    // PERO para la operación pendiente, usamos el UUID que espera el backend
    final data = {'uuid': fine.uuid};

    if (await _isConnected()) {
      // El método _sendToBackend debe ser ajustado para usar 'uuid'
      final response = await _sendToBackend('/fines', OperationType.DELETE, data);
      if (response != null && response.statusCode == 204) {
        print('Multa eliminada en backend y localmente.');
        return;
      }
    }

    final op = PendingOperation(operationType: OperationType.DELETE, tableName: DatabaseHelper.tableFines, data: data, createdAt: DateTime.now());
    await _pendingOpRepo.createPendingOperation(op);
    print('Multa eliminada como operación pendiente.');
  }

  Future<void> upsertFine(Fine fine) async {
    final db = await _dbHelper.database;
    
    try {
      final fineMap = fine.toMap();

      // Creamos una copia del mapa de datos y le quitamos el 'id'
      // para la operación de ACTUALIZACIÓN. Nunca debemos actualizar la clave primaria.
      final Map<String, dynamic> updateData = Map.from(fineMap);
      updateData.remove('id');

      // 1. Intentamos actualizar el registro usando el mapa SIN el 'id'.
      final int rowsAffected = await db.update(
        DatabaseHelper.tableFines,
        updateData,
        where: 'uuid = ?',
        whereArgs: [fine.uuid],
      );

      // 2. Si no se actualizó nada, significa que no existía.
      //    Entonces, lo insertamos usando el mapa original.
      //    (sqflite maneja correctamente un 'id' nulo para claves autoincrementales).
      if (rowsAffected == 0) {
        await db.insert(
          DatabaseHelper.tableFines,
          fine.toMap(),
        );
      }
      print('Multa ${fine.uuid} guardada/actualizada localmente.');
    } catch (e) {
      print('❌ Error al guardar multa ${fine.uuid}: $e');
      rethrow;
    }
  }


  Future<void> deleteLocallyById(int id) async {
      final db = await _dbHelper.database;
      await db.delete(DatabaseHelper.tableFines, where: 'id = ?', whereArgs: [id]);
      print('Multa con id: $id eliminada localmente.');
  }

  Future<void> deleteLocallyByUuid(String uuid) async {
      final db = await _dbHelper.database;
      await db.delete(DatabaseHelper.tableFines, where: 'uuid = ?', whereArgs: [uuid]);
      print('Multa con uuid: $uuid eliminada localmente.');
  }

  Future<List<Fine>> getAllFinesForAffiliate(String affiliateUuid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableFines,
      where: 'affiliate_uuid = ?',
      whereArgs: [affiliateUuid],
    );
    return List.generate(maps.length, (i) => Fine.fromMap(maps[i]));
  }

  // Para obtener los datos antes de borrar
  Future<List<Fine>> getFinesByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return [];
    final db = await _dbHelper.database;
    final placeholders = List.filled(uuids.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableFines,
      where: 'uuid IN ($placeholders)',
      whereArgs: uuids,
    );
    return List.generate(maps.length, (i) => Fine.fromMap(maps[i]));
  }
  
  // Para borrar en lote
  Future<void> deleteLocallyByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return;
    final db = await _dbHelper.database;
    final placeholders = List.filled(uuids.length, '?').join(',');
    await db.delete(
      DatabaseHelper.tableFines,
      where: 'uuid IN ($placeholders)',
      whereArgs: uuids,
    );
  }

}