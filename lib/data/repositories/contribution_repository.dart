// contribution_repository.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/models/contribution_model.dart';
import 'package:modus_pampa_v3/data/models/pending_operation_model.dart';
import 'package:modus_pampa_v3/data/repositories/pending_operation_repository.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:sqflite/sqflite.dart';

class ContributionRepository {
  final DatabaseHelper _dbHelper;
  final PendingOperationRepository _pendingOpRepo;
  final Dio _dio;
  final SettingsService _settingsService;

  ContributionRepository(
    this._dbHelper,
    this._pendingOpRepo,
    this._dio,
    this._settingsService,
  );

  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// **NUEVO MÉTODO CENTRALIZADO Y ATÓMICO**
  /// Crea una contribución, sus enlaces y actualiza la deuda de los afiliados
  /// dentro de una única transacción en la base de datos local.
  /// Luego, intenta sincronizar con el backend. Si falla, crea una única operación pendiente.
  Future<void> createContributionInTransaction(Contribution contribution, List<ContributionAffiliateLink> links) async {
    final db = await _dbHelper.database;

    // 1. Ejecutar todas las operaciones de la base de datos local en una transacción
    await db.transaction((txn) async {
      // Insertar la contribución principal
      await txn.insert(
        DatabaseHelper.tableContributions,
        contribution.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insertar todos los enlaces de la contribución
      final batch = txn.batch();
      for (final link in links) {
        batch.insert(
          DatabaseHelper.tableContributionAffiliates,
          link.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
    
    print("✅ Contribución y enlaces guardados en la BD local dentro de una transacción.");

    // 2. Intentar la sincronización con el backend
    if (await _isConnected()) {
      try {
        final backendUrl = _settingsService.getBackendUrl();
        // El DTO que espera el backend
        final payload = {
          'uuid': contribution.uuid,
          'name': contribution.name,
          'date': contribution.date.toIso8601String(),
          'default_amount': contribution.defaultAmount,
          'links': links.map((l) => {
            'uuid': l.uuid,
            'affiliate_uuid': l.affiliateUuid,
            'amount_to_pay': l.amountToPay,
          }).toList(),
        };
        final response = await _dio.post('$backendUrl/api/contributions', data: payload);

        // Si el backend responde con éxito (201 Created), la operación está completa.
        if (response.statusCode == 201) {
          print('✅ Contribución creada exitosamente en backend y localmente.');
          return; // Éxito, no se necesita operación pendiente.
        }
      } catch (e) {
        print('⚠️ Error al enviar contribución al backend, se creará una operación pendiente. Error: $e');
      }
    }

    // 3. Fallback: Si no hay conexión o la llamada al backend falló, crear UNA ÚNICA operación pendiente.
    final op = PendingOperation(
      operationType: OperationType.CREATE,
      // Usamos un nombre de tabla personalizado para identificar esta operación compleja en el servicio de sync.
      tableName: 'custom_contribution_creation',
      data: {
        'contribution': contribution.toMap(),
        'links': links.map((l) => l.toMap()).toList()
      },
      createdAt: DateTime.now(),
    );
    await _pendingOpRepo.createPendingOperation(op);
    print('ℹ️ Contribución guardada localmente, operación de sincronización pendiente creada.');
  }


  Future<void> payContribution(ContributionAffiliateLink link, double newAmountPaid) async {
    final db = await _dbHelper.database;
    
    // 1. Calcular explícitamente el nuevo estado de 'is_paid'.
    // Se usa una pequeña tolerancia para evitar problemas con números de punto flotante.
    final bool isNowPaid = (newAmountPaid + 0.001) >= link.amountToPay;

    // 2. Crear el objeto de enlace actualizado con el estado 'is_paid' correcto.
    final updatedLink = link.copyWith(
      amountPaid: newAmountPaid, 
      isPaid: isNowPaid, 
      updatedAt: DateTime.now()
    );

    // 3. Actualizar la base de datos local de forma inmediata.
    await db.update(
      DatabaseHelper.tableContributionAffiliates, 
      updatedLink.toMap(), // Asegúrate que tu método .toMap() incluye el campo 'is_paid'.
      where: 'uuid = ?', 
      whereArgs: [link.uuid]
    );

    // 4. Sincronizar con el backend, enviando el estado 'is_paid' correcto.
    if (await _isConnected()) {
      try {
        final backendUrl = _settingsService.getBackendUrl();
        final payload = {
          'amount_paid': updatedLink.amountPaid, 
          'is_paid': updatedLink.isPaid // Enviar el estado correcto al backend es crucial.
        };
        final response = await _dio.patch('$backendUrl/api/contributions/link/${link.uuid}', data: payload);
        if (response.statusCode == 200) {
          print('Pago de aporte registrado y sincronizado.');
          return;
        }
      } catch (e) {
        print('Error al sincronizar pago. Creando op. pendiente. Error: $e');
      }
    }

    // 5. Si la sincronización falla, crear una operación pendiente con los datos completos y correctos.
    await _pendingOpRepo.createPendingOperation(PendingOperation(
      operationType: OperationType.UPDATE,
      tableName: DatabaseHelper.tableContributionAffiliates,
      data: updatedLink.toMap(),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> deleteContribution(String contributionUuid) async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableContributions, where: 'uuid = ?', whereArgs: [contributionUuid]);
    
    if (await _isConnected()) {
      try {
        final backendUrl = _settingsService.getBackendUrl();
        final response = await _dio.delete('$backendUrl/api/contributions/$contributionUuid');
        if (response.statusCode == 200 || response.statusCode == 204) {
          print('Contribución eliminada en backend y localmente.');
          return;
        }
      } catch (e) {
        print('Error al eliminar contribución en backend, se creará op. pendiente. Error: $e');
      }
    }

    final op = PendingOperation(
      operationType: OperationType.DELETE,
      tableName: DatabaseHelper.tableContributions,
      data: {'uuid': contributionUuid},
      createdAt: DateTime.now(),
    );
    await _pendingOpRepo.createPendingOperation(op);
    print('Contribución eliminada localmente, operación de sincronización pendiente.');
  }
  
  Future<void> updateContributionLink(ContributionAffiliateLink link) async {
    final db = await _dbHelper.database;
    await db.update(DatabaseHelper.tableContributionAffiliates, link.toMap(), where: 'uuid = ?', whereArgs: [link.uuid]);

    if (await _isConnected()) {
      try {
        final backendUrl = _settingsService.getBackendUrl();
        final payload = {'amount_to_pay': link.amountToPay, 'amount_paid': link.amountPaid, 'is_paid': link.isPaid};
        final response = await _dio.patch('$backendUrl/api/contributions/link/${link.uuid}', data: payload);
        if (response.statusCode == 200) {
          print('Enlace de aporte actualizado en backend y localmente.');
          return;
        }
      } catch (e) {
        print('Error al actualizar enlace en backend, se creará op. pendiente. Error: $e');
      }
    }

    await _pendingOpRepo.createPendingOperation(PendingOperation(
      operationType: OperationType.UPDATE,
      tableName: DatabaseHelper.tableContributionAffiliates,
      data: link.toMap(),
      createdAt: DateTime.now(),
    ));
  }
  
  Future<void> upsertContributionWithLinks(Contribution contribution, List<ContributionAffiliateLink> links) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      await txn.insert(
        DatabaseHelper.tableContributions,
        contribution.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final link in links) {
        await txn.insert(
          DatabaseHelper.tableContributionAffiliates,
          link.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteLocally(String contributionUuid) async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableContributions, where: 'uuid = ?', whereArgs: [contributionUuid]);
    print('Contribución con uuid: $contributionUuid eliminada localmente.');
  }

  // --- MÉTODOS DE LECTURA (SIN CAMBIOS) ---
  Future<List<Contribution>> getAllContributions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableContributions,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Contribution.fromMap(maps[i]));
  }

  Future<List<ContributionAffiliateLink>> getLinksForContribution(String contributionUuid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableContributionAffiliates,
      where: 'contribution_uuid = ?',
      whereArgs: [contributionUuid],
    );
    return List.generate(maps.length, (i) => ContributionAffiliateLink.fromMap(maps[i]));
  }

  Future<List<ContributionAffiliateLink>> getAllContributionsForAffiliate(String affiliateUuid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableContributionAffiliates,
      where: 'affiliate_uuid = ?',
      whereArgs: [affiliateUuid],
    );
    return List.generate(maps.length, (i) => ContributionAffiliateLink.fromMap(maps[i]));
  }

  Future<List<ContributionAffiliateLink>> getPendingContributionsForAffiliate(String affiliateUuid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableContributionAffiliates,
      where: 'affiliate_uuid = ? AND is_paid = 0',
      whereArgs: [affiliateUuid],
    );
    return List.generate(maps.length, (i) => ContributionAffiliateLink.fromMap(maps[i]));
  }
}