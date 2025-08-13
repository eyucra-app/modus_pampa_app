import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/pending_operation_model.dart';
import 'package:modus_pampa_v3/data/repositories/pending_operation_repository.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/shared/utils/decimal_utils.dart';
import 'package:sqflite/sqflite.dart';

class AffiliateRepository {
  final DatabaseHelper _dbHelper;
  final PendingOperationRepository _pendingOpRepo;
  final Dio _dio; 
  final SettingsService _settingsService; 

  AffiliateRepository(this._dbHelper, this._pendingOpRepo, this._dio, this._settingsService);

  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

   // Método auxiliar para enviar al backend
  Future<Response?> _sendToBackend(String endpoint, OperationType type, Map<String, dynamic> data) async {
    final backendUrl = _settingsService.getBackendUrl();
    try {
      switch (type) {
        case OperationType.CREATE:
          return await _dio.post('$backendUrl/api$endpoint', data: data);
        case OperationType.UPDATE:
          return await _dio.put('$backendUrl/api$endpoint/${data['uuid']}', data: data);
        case OperationType.DELETE:
          return await _dio.delete('$backendUrl/api$endpoint/${data['uuid']}');
        default:
          return null;
      }
    } on DioException catch (e) {
      print('Error al enviar a backend: ${e.message}');
      return null; // Retorna null para indicar fallo y que se cree op. pendiente
    } catch (e) {
      print('Error inesperado al enviar a backend: $e');
      return null;
    }
  }

  // Crear un nuevo afiliado
  Future<void> createAffiliate(Affiliate affiliate) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableAffiliates,
      affiliate.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );

    if (await _isConnected()) {
      final response = await _sendToBackend('/affiliates', OperationType.CREATE, affiliate.toMap());
      if (response != null && response.statusCode == 200) { // Asume 200 Created para éxito
        print('Afiliado creado en backend y localmente.');
        return; // Éxito, no se necesita operación pendiente
      }
    }
    // Si no hay conexión o falló la subida, se crea la operación pendiente
    final op = PendingOperation(
      operationType: OperationType.CREATE,
      tableName: DatabaseHelper.tableAffiliates,
      data: affiliate.toMap(),
      createdAt: DateTime.now(),
    );
    await _pendingOpRepo.createPendingOperation(op);
    print('Afiliado guardado como operación pendiente.');
  }

  // Obtener todos los afiliados
  Future<List<Affiliate>> getAllAffiliates() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableAffiliates, orderBy: 'last_name ASC');
    return List.generate(maps.length, (i) {
      return Affiliate.fromMap(maps[i]);
    });
  }

  // Actualizar un afiliado
  Future<void> updateAffiliate(Affiliate affiliate) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableAffiliates,
      affiliate.toMap(),
      where: 'uuid = ?',
      whereArgs: [affiliate.uuid],
    );

    if (await _isConnected()) {
      final response = await _sendToBackend('/affiliates', OperationType.UPDATE, affiliate.toMap());
      if (response != null && response.statusCode == 200) { // Asume 200 OK para éxito
        print('Afiliado actualizado en backend y localmente.');
        return;
      }
    }
    final op = PendingOperation(
      operationType: OperationType.UPDATE,
      tableName: DatabaseHelper.tableAffiliates,
      data: affiliate.toMap(),
      createdAt: DateTime.now(),
    );
    await _pendingOpRepo.createPendingOperation(op);
    print('Afiliado actualizado como operación pendiente.');
  }

  // Eliminar un afiliado
  Future<void> deleteAffiliate(String uuid) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableAffiliates,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    if (await _isConnected()) {
      final response = await _sendToBackend('/affiliates', OperationType.DELETE, {'uuid': uuid});
      if (response != null && response.statusCode == 204) { // Asume 204 No Content para éxito
        print('Afiliado eliminado en backend y localmente.');
        return;
      }
    }
    final op = PendingOperation(
      operationType: OperationType.DELETE,
      tableName: DatabaseHelper.tableAffiliates,
      data: {'uuid': uuid},
      createdAt: DateTime.now(),
    );
    await _pendingOpRepo.createPendingOperation(op);
    print('Afiliado eliminado como operación pendiente.');
  }

  // Verificar si un ID ya existe (excluyendo el afiliado actual si se provee su uuid)
  Future<bool> checkIfIdExists(String id, {String? excludeUuid}) async {
    final db = await _dbHelper.database;
    String whereClause = 'id = ?';
    List<dynamic> whereArgs = [id];
    if (excludeUuid != null) {
      whereClause += ' AND uuid != ?';
      whereArgs.add(excludeUuid);
    }
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAffiliates,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.isNotEmpty;
  }

  // Verificar si un CI ya existe (excluyendo el afiliado actual si se provee su uuid)
  Future<bool> checkIfCiExists(String ci, {String? excludeUuid}) async {
    final db = await _dbHelper.database;
    String whereClause = 'ci = ?';
    List<dynamic> whereArgs = [ci];
    if (excludeUuid != null) {
      whereClause += ' AND uuid != ?';
      whereArgs.add(excludeUuid);
    }
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAffiliates,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.isNotEmpty;
  }
  
  Future<Affiliate?> findAffiliateByIdAndCi(String id, String ci) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAffiliates,
      where: 'id = ? AND ci = ?',
      whereArgs: [id, ci],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Affiliate.fromMap(maps.first);
    }
    return null;
  }

  Future<void> upsertAffiliate(Affiliate affiliate) async {
    final db = await _dbHelper.database;
    
    try {
      // Primero, intentamos actualizar el registro.
      final int rowsAffected = await db.update(
        DatabaseHelper.tableAffiliates,
        affiliate.toMap(),
        where: 'uuid = ?', // La clave primaria es el uuid.
        whereArgs: [affiliate.uuid],
      );

      // Si no se actualizó ninguna fila (porque no existía), la insertamos.
      if (rowsAffected == 0) {
        await db.insert(
          DatabaseHelper.tableAffiliates,
          affiliate.toMap(),
        );
      }
      print('Afiliado ${affiliate.uuid} guardado/actualizado localmente.');
    } catch (e) {
      print('❌ Error al guardar afiliado ${affiliate.uuid}: $e');
      rethrow;
    }
  }

  Future<void> bulkUpdateAffiliateDebts(Map<String, double> debtChanges) async {
    // Si no hay nada que cambiar, no hacemos nada.
    if (debtChanges.isEmpty) {
      return;
    }

    final db = await _dbHelper.database;
    final affiliateUuids = debtChanges.keys.toList();

    // 1. Obtener el estado actual SOLO de los afiliados que vamos a modificar.
    // Usamos '?' para prevenir inyecciones SQL.
    final placeholders = List.filled(affiliateUuids.length, '?').join(',');
    final List<Map<String, dynamic>> currentAffiliates = await db.query(
      'affiliates', // Nombre de tu tabla de afiliados
      columns: ['uuid', 'total_debt'],
      where: 'uuid IN ($placeholders)',
      whereArgs: affiliateUuids,
    );

    // 2. Preparar un lote (Batch) para ejecutar todas las actualizaciones a la vez.
    // Esto es mucho más rápido que hacer N escrituras separadas.
    final batch = db.batch();

    for (final affiliateData in currentAffiliates) {
      final uuid = affiliateData['uuid'] as String;
      final currentDebt = (affiliateData['total_debt'] as num?)?.toDouble() ?? 0.0;
      final change = debtChanges[uuid];

      if (change != null) {
        // Calculamos la nueva deuda
        final newTotalDebt = DecimalUtils.round(currentDebt + change);
        final newUpdatedAt = DateTime.now().toIso8601String();

        // Añadimos la operación de actualización al lote
        batch.update(
          'affiliates',
          {
            'total_debt': newTotalDebt,
            'updated_at': newUpdatedAt,
          },
          where: 'uuid = ?',
          whereArgs: [uuid],
        );
      }
    }

    // 3. Ejecutar todas las operaciones del lote en una sola transacción atómica.
    // 'noResult: true' es una pequeña optimización si no necesitas el número de filas afectadas.
    await batch.commit(noResult: true);
  }

  Future<void> applyPaymentToAffiliate({required String affiliateUuid, required double paymentAmount}) async {
    if (paymentAmount == 0) return;

    final db = await _dbHelper.database;
    
    // Usamos una transacción para garantizar que la lectura y escritura sean atómicas
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> maps = await txn.query('affiliates', where: 'uuid = ?', whereArgs: [affiliateUuid]);

      if (maps.isNotEmpty) {
        final current = Affiliate.fromMap(maps.first);

        // Calculamos los nuevos valores
        final newTotalPaid = DecimalUtils.round(current.totalPaid + paymentAmount);
        final newTotalDebt = DecimalUtils.round(current.totalDebt - paymentAmount);

        // Creamos el afiliado actualizado para sincronizarlo
        final updatedAffiliate = current.copyWith(
          totalPaid: newTotalPaid,
          totalDebt: newTotalDebt,
          updatedAt: DateTime.now(),
        );

        // Actualizamos la base de datos local
        await txn.update(
          DatabaseHelper.tableAffiliates,
          {
            'total_paid': newTotalPaid,
            'total_debt': newTotalDebt,
            'updated_at': updatedAffiliate.updatedAt?.toIso8601String(),
          },
          where: 'uuid = ?',
          whereArgs: [affiliateUuid],
        );
        
        // Intentamos sincronizar el afiliado completo con el backend
        if (await _isConnected()) {
          final response = await _sendToBackend('/affiliates', OperationType.UPDATE, updatedAffiliate.toMap());
          if (response != null && response.statusCode == 200) {
            print('Pago de afiliado aplicado y sincronizado con el backend.');
            return;
          }
        }

        // Si falla la sincronización, creamos una operación pendiente
        await _pendingOpRepo.createPendingOperation(PendingOperation(
          operationType: OperationType.UPDATE,
          tableName: DatabaseHelper.tableAffiliates,
          data: updatedAffiliate.toMap(),
          createdAt: DateTime.now(),
        ));
      }
    });
  }
  Future<void> updateAffiliateTotals({
    required String affiliateUuid,
    required double totalDebt,
    required double totalPaid,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableAffiliates,
      {
        'total_debt': totalDebt,
        'total_paid': totalPaid,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'uuid = ?',
      whereArgs: [affiliateUuid],
    );
  }
  
  Future<void> deleteLocally(String uuid) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableAffiliates,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    print('Afiliado con uuid: $uuid eliminado localmente.');
  }

}
