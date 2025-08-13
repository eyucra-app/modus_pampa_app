// lib/features/settings/services/sync_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modus_pampa_v3/core/providers/connectivity_provider.dart';
import 'package:modus_pampa_v3/core/providers/dio_provider.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/attendance_model.dart';
import 'package:modus_pampa_v3/data/models/contribution_model.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:modus_pampa_v3/data/models/pending_operation_model.dart';
import 'package:modus_pampa_v3/data/models/user_model.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/attendance/providers/attendance_providers.dart';
import 'package:modus_pampa_v3/features/auth/providers/auth_providers.dart';
import 'package:modus_pampa_v3/features/contributions/providers/contribution_providers.dart';
import 'package:modus_pampa_v3/features/fines/providers/fines_providers.dart';
import 'package:modus_pampa_v3/features/settings/providers/cloudinary_provider.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/features/settings/services/websocket_service.dart';
import 'package:modus_pampa_v3/shared/utils/decimal_utils.dart';

class SyncService {
  final Ref _ref;
  bool isPushSyncing = false;
  bool isPullSyncing = false;

  SyncService(this._ref);

  Future<List<String>> pushChanges() async {
    if(isPushSyncing) return ["Ya hay una sincronización push en progreso."];
    isPushSyncing = true;
    print("🔄 Iniciando pushChanges...");

    final pendingOpRepo = _ref.read(pendingOperationRepositoryProvider);
    final cloudinaryService = _ref.read(cloudinaryServiceProvider);
    final operations = await pendingOpRepo.getPendingOperations();
    final List<String> logs = [];

    logs.add("Iniciando subida de ${operations.length} operaciones pendientes...");
    print("📊 Total de operaciones pendientes encontradas: ${operations.length}");

    final connectivityResult = await _ref.read(connectivityStreamProvider.future);
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi) || connectivityResult.contains(ConnectivityResult.ethernet);

    if (!isOnline) {
      isPushSyncing = false;
      logs.add("❌ No hay conexión a internet. Sincronización pospuesta.");
      return logs;
    }

    final dio = _ref.read(dioProvider);
    final backendUrl = _ref.read(settingsServiceProvider).getBackendUrl();

    for (final op in operations) {
      try {
        final data = op.data;
        logs.add("  -> Procesando operación: ${op.operationType.name} en ${op.tableName} (ID local: ${op.id})...");

        if (op.tableName == 'affiliates' && (op.operationType == OperationType.CREATE || op.operationType == OperationType.UPDATE)) {
          String? profileUrl = data['profile_photo_url'];
          String? credentialUrl = data['credential_photo_url'];

          if (profileUrl != null && profileUrl != 'null' && !profileUrl.startsWith('http')) {
            logs.add("  🔄 Subiendo foto de perfil...");
            data['profile_photo_url'] = await cloudinaryService.uploadImage(XFile(profileUrl));
            logs.add("  ✔️ Foto de perfil subida.");
          }
          if (credentialUrl != null && credentialUrl != 'null' && !credentialUrl.startsWith('http')) {
            logs.add("  🔄 Subiendo foto de credencial...");
            data['credential_photo_url'] = await cloudinaryService.uploadImage(XFile(credentialUrl));
            logs.add("  ✔️ Foto de credencial subida.");
          }
        }

        String endpoint = '$backendUrl/api/${op.tableName}';
        Response? response;
        bool operationHandled = false;

        switch (op.tableName) {
          case 'affiliates':
          case 'users':
          case 'fines':
            if (op.operationType == OperationType.CREATE) {
              response = await dio.post(endpoint, data: data);
            } else if (op.operationType == OperationType.UPDATE) {
              response = await dio.put('$endpoint/${data['uuid']}', data: data);
            } else if (op.operationType == OperationType.DELETE) {
              response = await dio.delete('$endpoint/${data['uuid']}');
            }
            operationHandled = true;
            break;

           case 'custom_contribution_creation':
            // **LÓGICA PARA SUBIR LA CONTRIBUCIÓN COMPLETA**
            // El backend espera este payload en el endpoint POST /api/contributions
            final payload = {
              'uuid': op.data['contribution']['uuid'], 
              'name': op.data['contribution']['name'], 
              'date': op.data['contribution']['date'],
              'default_amount': op.data['contribution']['default_amount'],
              // Mapeamos los links al formato que el DTO del backend espera
              'links': (op.data['links'] as List).map((l) => { 
                'uuid': l['uuid'], 
                'affiliate_uuid': l['affiliate_uuid'], 
                'amount_to_pay': l['amount_to_pay'] 
              }).toList(),
            };
            response = await dio.post('$backendUrl/api/contributions', data: payload);
            operationHandled = true;
            break;

          case 'contributions':
            if (op.operationType == OperationType.DELETE) {
              response = await dio.delete('$backendUrl/api/contributions/${op.data['uuid']}');
              operationHandled = true;
            }
            break;

          case 'contribution_affiliates':
            if (op.operationType == OperationType.UPDATE) {
              final payload = {'amount_to_pay': op.data['amount_to_pay'], 'amount_paid': op.data['amount_paid'], 'is_paid': op.data['is_paid']};
              response = await dio.patch('$backendUrl/api/contributions/link/${op.data['uuid']}', data: payload);
              operationHandled = true;
            }
            break;
          case 'attendance_lists':
             if (op.operationType == OperationType.CREATE) {
              response = await dio.post('$backendUrl/api/attendance', data: op.data);
              operationHandled = true;
            } else if (op.operationType == OperationType.DELETE) {
              response = await dio.delete('$backendUrl/api/attendance/${op.data['uuid']}');
              operationHandled = true;
            }
            break;
          default:
            logs.add("  ⚠️  Tabla '${op.tableName}' no tiene lógica de sincronización definida.");
            continue;
        }

        if (operationHandled) {
          logs.add("  Sent to backend: $endpoint, Status: ${response?.statusCode}");
          await pendingOpRepo.deletePendingOperation(op.id!);
          logs.add("  ✔️ Sincronizado con éxito. Operación #${op.id} eliminada.");
        }

      } on DioException catch (e) {
        logs.add("❌ Error de red en op #${op.id} (${op.tableName}): ${e.message}");
      } catch (e) {
        logs.add("❌ Error inesperado en op #${op.id} (${op.tableName}): ${e.toString()}");
      }
    }

    _ref.invalidate(pendingOperationsProvider);
    logs.add("Sincronización de subida completada.");
    print("✅ Push completado exitosamente.");
    isPushSyncing = false;
    return logs;
  }

  /// Descarga los cambios del servidor y los aplica localmente.
  Future<List<String>> pullChanges() async {
    if (isPullSyncing) return ["Ya hay una sincronización pull en progreso."];
    isPullSyncing = true;
    print("📥 Iniciando pullChanges...");

    final settingsService = _ref.read(settingsServiceProvider);
    final dio = _ref.read(dioProvider);
    final backendUrl = settingsService.getBackendUrl();
    final lastSync = settingsService.getLastSyncTimestamp();
    final List<String> logs = [];

    logs.add("Iniciando descarga de cambios desde el servidor...");
    logs.add("Última sincronización: ${lastSync?.toIso8601String() ?? 'Nunca'}");

    final connectivityResult = await _ref.read(connectivityStreamProvider.future);
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);

    if (!isOnline) {
      isPullSyncing = false;
      logs.add("❌ No hay conexión a internet. Descarga pospuesta.");
      return logs;
    }

    // Repositorios para acceder a la base de datos local
    final affiliateRepo = _ref.read(affiliateRepositoryProvider);
    final userRepo = _ref.read(authRepositoryProvider);
    final fineRepo = _ref.read(fineRepositoryProvider);
    final contributionRepo = _ref.read(contributionRepositoryProvider);
    final attendanceRepo = _ref.read(attendanceRepositoryProvider);
    
    // **PASO 1: Recolectar todos los afiliados afectados por CUALQUIER cambio.**
    final Set<String> affectedAffiliateUuids = {};

    try {
      logs.add("🌐 Haciendo petición GET a: $backendUrl/api/sync/pull");
      final response = await dio.get(
        '$backendUrl/api/sync/pull',
        queryParameters: {
          if (lastSync != null) 'lastSync': lastSync.toIso8601String(),
        },
      );

      logs.add("📡 Respuesta del servidor recibida. Status: ${response.statusCode}");
      final data = response.data;
      logs.add("📊 Datos recibidos: ${data.toString()}");
      int totalChanges = 0;
      int totalDeletions = 0;

      // --- PROCESAR CAMBIOS (UPSERTS) ---
      if (data['affiliates']?['updated'] != null) {
        final items = List<Map<String, dynamic>>.from(data['affiliates']['updated']);
        totalChanges += items.length;
        for (final item in items) {
          try {
            await affiliateRepo.upsertAffiliate(Affiliate.fromMap(item));
            affectedAffiliateUuids.add(item['uuid']);
          } catch (e) {
            logs.add("❌ Error guardando afiliado ${item['uuid']}: $e");
          }
        }
      }
      if (data['users']?['updated'] != null) {
        final items = List<Map<String, dynamic>>.from(data['users']['updated']);
        totalChanges += items.length;
        for (final item in items) {
          await userRepo.upsertUser(User.fromMap(item));
        }
      }
      if (data['fines']?['updated'] != null) {
        final items = List<Map<String, dynamic>>.from(data['fines']['updated']);
        totalChanges += items.length;
        for (final item in items) {
          await fineRepo.upsertFine(Fine.fromMap(item));
          affectedAffiliateUuids.add(item['affiliate_uuid']);
        }
      }
      if (data['contributions']?['updated'] != null) {
        final items = List<Map<String, dynamic>>.from(data['contributions']['updated']);
        totalChanges += items.length;
        for (final item in items) {
          final contribution = Contribution.fromMap(item);
          final links = (item['links'] as List).map((l) => ContributionAffiliateLink.fromMap(l)).toList();
          await contributionRepo.upsertContributionWithLinks(contribution, links);
          _ref.invalidate(contributionDetailProvider(contribution.uuid));
          for (final link in links) {
            affectedAffiliateUuids.add(link.affiliateUuid);
          }
        }
      }
      if (data['attendance']?['updated'] != null) {
        final items = List<Map<String, dynamic>>.from(data['attendance']['updated']);
        totalChanges += items.length;
        for (final item in items) {
          final records = (item['records'] as List).map((r) => AttendanceRecord.fromMap(r)).toList();
          await attendanceRepo.upsertAttendanceListWithRecords(AttendanceList.fromMap(item), records);
        }
      }

      // --- PROCESAR ELIMINACIONES ---
      if (data['affiliates']?['deleted'] != null) {
        final uuids = List<String>.from(data['affiliates']['deleted']);
        totalDeletions += uuids.length;
        for (final uuid in uuids) {
          await affiliateRepo.deleteLocally(uuid);
        }
      }
      if (data['users']?['deleted'] != null) {
        final uuids = List<String>.from(data['users']['deleted']);
        totalDeletions += uuids.length;
        for (final uuid in uuids) {
          await userRepo.deleteLocally(uuid);
        }
      }
      if (data['fines']?['deleted'] != null) {
        final finesToDelete = await fineRepo.getFinesByUuids(List<String>.from(data['fines']['deleted']));
        for(final fine in finesToDelete) {
          affectedAffiliateUuids.add(fine.affiliateUuid);
        }
        await fineRepo.deleteLocallyByUuids(finesToDelete.map((f) => f.uuid).toList());
        totalDeletions += finesToDelete.length;
      }
      if (data['contributions']?['deleted'] != null) {
        final uuids = List<String>.from(data['contributions']['deleted']);
        totalDeletions += uuids.length;
        for (final uuid in uuids) {
          final linksToDelete = await contributionRepo.getLinksForContribution(uuid);
          for (final link in linksToDelete) {
            affectedAffiliateUuids.add(link.affiliateUuid);
          }
          await contributionRepo.deleteLocally(uuid);
        }
        _ref.invalidate(affiliateListNotifierProvider);
      }
      if (data['attendance']?['deleted'] != null) {
        final uuids = List<String>.from(data['attendance']['deleted']);
        totalDeletions += uuids.length;
        for (final uuid in uuids) {
          await attendanceRepo.deleteLocally(uuid);
        }
      }
      
      // **PASO 2: Recalcular los totales para TODOS los afiliados afectados.**
      if (affectedAffiliateUuids.isNotEmpty) {
        logs.add("🔄 Recalculando totales para ${affectedAffiliateUuids.length} afiliados afectados...");
        await _recalculateTotalsForAffiliates(affectedAffiliateUuids);
        logs.add("✅ Recalculación completada.");
      }

      if (totalChanges > 0 || totalDeletions > 0 || affectedAffiliateUuids.isNotEmpty) {
        await settingsService.setLastSyncTimestamp(DateTime.now());
        logs.add("✔️ Base de datos local actualizada.");
      } else {
        logs.add("✔️ No se encontraron nuevos cambios en el servidor.");
      }
    } on DioException catch (e) {
      logs.add("❌ Error de red al descargar cambios: ${e.message}");
    } catch (e) {
      logs.add("❌ Error inesperado al procesar cambios: ${e.toString()}");
    } finally {
      isPullSyncing = false;
    }

    // **PASO 3: Invalidar providers para que la UI se refresque con los datos correctos.**
    _ref.invalidate(affiliateListNotifierProvider);
    _ref.invalidate(allUsersProvider);
    _ref.invalidate(affiliatesWithFinesProvider);
    _ref.invalidate(contributionListProvider);
    _ref.invalidate(attendanceListProvider);

    return logs;
  }

  /// **NUEVO MÉTODO DE RECALCULACIÓN**
  /// Este método es la clave para la consistencia.
  Future<void> _recalculateTotalsForAffiliates(Set<String> affiliateUuids) async {
    final affiliateRepo = _ref.read(affiliateRepositoryProvider);
    final fineRepo = _ref.read(fineRepositoryProvider);
    final contributionRepo = _ref.read(contributionRepositoryProvider);

    for (final uuid in affiliateUuids) {
      // Obtenemos todos los datos que componen la deuda y los pagos
      final fines = await fineRepo.getAllFinesForAffiliate(uuid);
      final contributions = await contributionRepo.getAllContributionsForAffiliate(uuid);

      // Calculamos desde cero
      double totalDebt = 0;
      double totalPaid = 0;

      for (final fine in fines) {
        totalDebt += (fine.amount - fine.amountPaid);
        totalPaid += fine.amountPaid;
      }
      for (final contribution in contributions) {
        totalDebt += (contribution.amountToPay - contribution.amountPaid);
        totalPaid += contribution.amountPaid;
      }

      // Actualizamos el afiliado con los nuevos totales calculados
      await affiliateRepo.updateAffiliateTotals(
        affiliateUuid: uuid,
        totalDebt: DecimalUtils.round(totalDebt),
        totalPaid: DecimalUtils.round(totalPaid),
      );
    }
  }

  Future<void> clearAllPendingOperations() async {
    final pendingOpRepo = _ref.read(pendingOperationRepositoryProvider);
    await pendingOpRepo.deleteAllPendingOperations();
    _ref.invalidate(pendingOperationsProvider);
  }

  Future<void> clearPendingOperation(int id) async {
    final pendingOpRepo = _ref.read(pendingOperationRepositoryProvider);
    await pendingOpRepo.deletePendingOperation(id);
    _ref.invalidate(pendingOperationsProvider);
  }
}

// --- PROVIDERS ---
final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));
final pendingOperationsProvider = FutureProvider<List<PendingOperation>>((ref) => ref.watch(pendingOperationRepositoryProvider).getPendingOperations());

final syncTriggerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityStreamProvider, (previous, next) {
    final bool wasOffline = previous?.asData?.value.contains(ConnectivityResult.none) ?? true;
    final bool isOnline = next.asData?.value.any((result) => result != ConnectivityResult.none) ?? false;
    
    final webSocketService = ref.read(webSocketServiceProvider);

    if (isOnline) {
      print("Conexión detectada. Conectando WebSocket y sincronizando...");
      webSocketService.connect();
      
      if (wasOffline) {
        ref.read(syncServiceProvider).pushChanges();
      }
    } else {
      print("Sin conexión. Desconectando WebSocket.");
      webSocketService.disconnect();
    }
  });
});