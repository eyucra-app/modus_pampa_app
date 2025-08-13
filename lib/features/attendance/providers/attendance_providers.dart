import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/core/providers/dio_provider.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/attendance_model.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:modus_pampa_v3/data/repositories/attendance_repository.dart';
import 'package:modus_pampa_v3/data/repositories/fine_repository.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/fines/providers/fines_providers.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/main.dart';
import 'package:uuid/uuid.dart'; // Importar Uuid

// Estados para las operaciones
abstract class AttendanceOperationState {}
class AttendanceOperationInitial extends AttendanceOperationState {}
class AttendanceOperationLoading extends AttendanceOperationState {}
class AttendanceOperationSuccess extends AttendanceOperationState { final String message; AttendanceOperationSuccess(this.message); }
class AttendanceOperationError extends AttendanceOperationState { final String message; AttendanceOperationError(this.message); }

// Notifier para manejar las operaciones del módulo de asistencia
class AttendanceNotifier extends StateNotifier<AttendanceOperationState> {
  final AttendanceRepository _attendanceRepo;
  final FineRepository _fineRepo;
  final Ref _ref;

  AttendanceNotifier(this._attendanceRepo, this._fineRepo, this._ref) : super(AttendanceOperationInitial());

  // Crea una nueva lista de asistencia
  Future<void> createAttendanceList(String name) async {
    state = AttendanceOperationLoading();
    try {
      final now = DateTime.now();
      final newList = AttendanceList(
        uuid: const Uuid().v4(), // Generar UUID para la nueva lista
        name: name,
        createdAt: now,
        updatedAt: now, // Inicializar updatedAt
      );
      await _attendanceRepo.createAttendanceList(newList);
      _ref.invalidate(attendanceListProvider);
      state = AttendanceOperationSuccess("Lista de asistencia '$name' creada.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  // Cambia el estado de una lista
  Future<void> updateListStatus(String listUuid, AttendanceListStatus newStatus) async {
    state = AttendanceOperationLoading();
    try {
      // Obtener la lista actual para mantener los datos existentes y actualizar solo el estado y updatedAt
      final allLists = await _attendanceRepo.getAllAttendanceLists();
      final currentList = allLists.firstWhere((l) => l.uuid == listUuid);
      
      final updatedList = currentList.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(), // Actualizar updatedAt
      );

      // Se usa un método de actualización en el repositorio que acepte el objeto completo
      await _attendanceRepo.updateAttendanceList(updatedList); 
      _ref.invalidate(attendanceListProvider);
      _ref.invalidate(attendanceRecordsProvider(listUuid)); // Invalida los detalles también
      state = AttendanceOperationSuccess("Estado de la lista actualizado.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  // Registra la asistencia de un afiliado
  Future<void> registerAffiliate(String listUuid, Affiliate affiliate) async {
    state = AttendanceOperationLoading();
    try {
      final isAlreadyRegistered = await _attendanceRepo.isAffiliateRegistered(listUuid, affiliate.uuid);
      if (isAlreadyRegistered) {
        state = AttendanceOperationError("Este afiliado ya ha sido registrado.");
        return;
      }

      final allLists = await _attendanceRepo.getAllAttendanceLists();
      final currentList = allLists.firstWhere((l) => l.uuid == listUuid);
      
      final recordStatus = (currentList.status == AttendanceListStatus.TERMINADA)
          ? AttendanceRecordStatus.RETRASO
          : AttendanceRecordStatus.PRESENTE;
          
      final now = DateTime.now();
      final newRecord = AttendanceRecord(
        uuid: const Uuid().v4(), // Generar UUID para el registro
        listUuid: currentList.uuid, // Usar el UUID de la lista
        affiliateUuid: affiliate.uuid,
        registeredAt: now,
        status: recordStatus,
        createdAt: now, // Establecer createdAt
        updatedAt: now, // Inicializar updatedAt
      );
      await _attendanceRepo.addAttendanceRecord(newRecord);

      if (currentList.status == AttendanceListStatus.PREPARADA) {
        // Actualizar el estado de la lista a INICIADA, también su updatedAt
        final updatedList = currentList.copyWith(
          status: AttendanceListStatus.INICIADA,
          updatedAt: DateTime.now(),
        );
        await _attendanceRepo.updateAttendanceList(updatedList); // Usar updateAttendanceList
        _ref.invalidate(attendanceListProvider);
      }
      
      if (recordStatus == AttendanceRecordStatus.RETRASO) {

        final fineAmount = _ref.read(lateFineAmountProvider);

        final fineNotifier = _ref.read(fineOperationProvider.notifier);

        final nowFine = DateTime.now();
        final fine = Fine(
          uuid: const Uuid().v4(), // Generar UUID para la multa
          affiliateUuid: affiliate.uuid,
          amount: fineAmount, 
          description: "Multa por retraso en lista: ${currentList.name}", 
          category: FineCategory.Retraso, 
          date: nowFine, 
          relatedAttendanceUuid: currentList.uuid, // Usar el UUID de la lista
          createdAt: nowFine, // Establecer createdAt
          updatedAt: nowFine, // Inicializar updatedAt
        );
        await fineNotifier.createFine(fine, affiliate);
      }

      _ref.invalidate(attendanceRecordsProvider(listUuid));
      state = AttendanceOperationSuccess("${affiliate.fullName} registrado como ${recordStatus.name}.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  // Finaliza una lista y genera multas por falta
  Future<void> finalizeList(AttendanceList list) async {
    state = AttendanceOperationLoading();
    try {
      // 1. Lógica de negocio (generar multas por falta)
      // (Esta parte se mantiene igual)
      final allAffiliates = _ref.read(affiliateListNotifierProvider.notifier).state.allAffiliates.asData?.value ?? [];
      final registeredRecords = await _attendanceRepo.getRecordsForList(list.uuid);
      final registeredUuids = registeredRecords.map((r) => r.affiliateUuid).toSet();
      final missingAffiliates = allAffiliates.where((aff) => !registeredUuids.contains(aff.uuid)).toList();
      final fineNotifier = _ref.read(fineOperationProvider.notifier);
      final fineAmount = _ref.read(absentFineAmountProvider);
      for (final affiliate in missingAffiliates) {
        final nowFine = DateTime.now();
        final fine = Fine(
            uuid: const Uuid().v4(), affiliateUuid: affiliate.uuid, amount: fineAmount,
            description: "Multa por falta en lista: ${list.name}", category: FineCategory.Falta,
            date: nowFine, relatedAttendanceUuid: list.uuid,
            createdAt: nowFine, updatedAt: nowFine);
        await fineNotifier.createFine(fine, affiliate);
      }

      // 2. Actualizar el estado de la lista a FINALIZADA localmente
      final finalizedList = list.copyWith(status: AttendanceListStatus.FINALIZADA, updatedAt: DateTime.now());
      await _attendanceRepo.updateAttendanceList(finalizedList);
      _ref.invalidate(attendanceListProvider);
      _ref.invalidate(attendanceRecordsProvider(list.uuid));

      // 3. ¡NUEVO! Sincronizar la lista completa con el backend
      final fullRecords = await _attendanceRepo.getRecordsForList(list.uuid);
      await _attendanceRepo.syncFinalizedList(finalizedList, fullRecords);

      state = AttendanceOperationSuccess("Lista finalizada. Se generaron ${missingAffiliates.length} multas y se envió a sincronización.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  Future<void> deleteAttendanceList(AttendanceList list) async {
    state = AttendanceOperationLoading();
    try {
      // 1. Lógica de negocio (eliminar multas relacionadas)
      final relatedFines = await _fineRepo.getFinesByAttendanceList(list.uuid);
      final fineNotifier = _ref.read(fineOperationProvider.notifier);
      final allAffiliates = _ref.read(affiliateListNotifierProvider.notifier).state.allAffiliates.asData?.value ?? [];

      for (var fine in relatedFines) {
        final affiliate = allAffiliates.firstWhere(
            (a) => a.uuid == fine.affiliateUuid, 
            orElse: () => Affiliate(uuid: '', id: '', firstName: '', lastName: '', ci: '', createdAt: DateTime.now())
        );
        if (affiliate.uuid.isNotEmpty) {
          await fineNotifier.deleteFine(fine, affiliate);
        }
      }
      
      // 2. Llamada al repositorio para eliminar la lista
      await _attendanceRepo.deleteAttendanceList(list);

      // 3. Invalidar providers para refrescar la UI
      _ref.invalidate(attendanceListProvider);
      state = AttendanceOperationSuccess("Lista '${list.name}' y sus multas asociadas han sido eliminadas.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  Future<void> deleteAttendanceRecord(AttendanceRecord record, Affiliate affiliate) async {
    state = AttendanceOperationLoading();
    try {
      await _attendanceRepo.deleteAttendanceRecord(record.uuid); // Este método aún no está modificado para usar UUID en el repositorio
      
      // Si el registro eliminado tenía una multa por retraso, la eliminamos también.
      if (record.status == AttendanceRecordStatus.RETRASO) {
          final fineNotifier = _ref.read(fineOperationProvider.notifier);
          final affiliateFines = await _fineRepo.getFinesForAffiliate(affiliate.uuid);
          // Asegurarse de que el constructor de Fine tenga uuid y createdAt
          final relatedFine = affiliateFines.firstWhere((f) => f.relatedAttendanceUuid == record.listUuid, orElse: () => Fine(uuid: '', affiliateUuid: '', amount: 0, description: '', category: FineCategory.Varios, date: DateTime.now(), createdAt: DateTime.now())); // Proporcionar uuid y createdAt

          if (relatedFine.id != -1) {
              await fineNotifier.deleteFine(relatedFine, affiliate);
          }
      }

      _ref.invalidate(attendanceRecordsProvider(record.listUuid));
      state = AttendanceOperationSuccess("Registro de ${affiliate.fullName} eliminado.");

    } catch (e) { state = AttendanceOperationError(e.toString()); }
  }
}

// --- Providers ---

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(
    dbHelper,
    ref.watch(pendingOperationRepositoryProvider),
    ref.watch(dioProvider), // Inyectar Dio
    ref.watch(settingsServiceProvider), // Inyectar SettingsService
  );
});

final attendanceNotifierProvider = StateNotifierProvider<AttendanceNotifier, AttendanceOperationState>(
  (ref) => AttendanceNotifier(
    ref.watch(attendanceRepositoryProvider), ref.watch(fineRepositoryProvider), ref));


// Provider para obtener todas las listas de asistencia
final attendanceListProvider = FutureProvider<List<AttendanceList>>((ref) {
  return ref.watch(attendanceRepositoryProvider).getAllAttendanceLists();
});

// Provider para obtener los registros de una lista específica
final attendanceRecordsProvider = FutureProvider.family<List<AttendanceRecord>, String>((ref, listUuid) {
  return ref.watch(attendanceRepositoryProvider).getRecordsForList(listUuid);
});

final allAttendanceByAffiliateProvider = FutureProvider.family<List<AttendanceRecord>, String>((ref, affiliateUuid) {
  return ref.watch(attendanceRepositoryProvider).getAllRecordsForAffiliate(affiliateUuid);
});