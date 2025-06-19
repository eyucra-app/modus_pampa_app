import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/attendance_model.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:modus_pampa_v3/data/repositories/attendance_repository.dart';
import 'package:modus_pampa_v3/data/repositories/fine_repository.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/fines/providers/fines_providers.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/main.dart';

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
      final newList = AttendanceList(name: name, createdAt: DateTime.now());
      await _attendanceRepo.createAttendanceList(newList);
      _ref.invalidate(attendanceListProvider);
      state = AttendanceOperationSuccess("Lista de asistencia '$name' creada.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  // Cambia el estado de una lista
  Future<void> updateListStatus(int listId, AttendanceListStatus newStatus) async {
    state = AttendanceOperationLoading();
    try {
      await _attendanceRepo.updateListStatus(listId, newStatus);
      _ref.invalidate(attendanceListProvider);
      _ref.invalidate(attendanceRecordsProvider(listId)); // Invalida los detalles también
      state = AttendanceOperationSuccess("Estado de la lista actualizado.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  // Registra la asistencia de un afiliado
  Future<void> registerAffiliate(int listId, Affiliate affiliate) async {
    state = AttendanceOperationLoading();
    try {
      final isAlreadyRegistered = await _attendanceRepo.isAffiliateRegistered(listId, affiliate.uuid);
      if (isAlreadyRegistered) {
        state = AttendanceOperationError("Este afiliado ya ha sido registrado.");
        return;
      }

      final allLists = await _attendanceRepo.getAllAttendanceLists();
      final currentList = allLists.firstWhere((l) => l.id == listId);
      
      final recordStatus = (currentList.status == AttendanceListStatus.TERMINADA)
          ? AttendanceRecordStatus.RETRASO
          : AttendanceRecordStatus.PRESENTE;
          
      final newRecord = AttendanceRecord(listId: listId, affiliateUuid: affiliate.uuid, registeredAt: DateTime.now(), status: recordStatus);
      await _attendanceRepo.addAttendanceRecord(newRecord);

      if (currentList.status == AttendanceListStatus.PREPARADA) {
        await _attendanceRepo.updateListStatus(listId, AttendanceListStatus.INICIADA);
        // Se invalida el provider para que la pantalla anterior se actualice
        _ref.invalidate(attendanceListProvider);
      }
      
      if (recordStatus == AttendanceRecordStatus.RETRASO) {

        final settings = _ref.read(settingsServiceProvider);
        final fineAmount = settings.getFineAmountLate();

        final fineNotifier = _ref.read(fineOperationProvider.notifier);
        final fine = Fine(
          affiliateUuid: affiliate.uuid,
          amount: fineAmount, 
          description: "Multa por retraso en lista: ${currentList.name}", 
          category: FineCategory.Retraso, 
          date: DateTime.now(), 
          relatedAttendanceId: listId
        );
        await fineNotifier.createFine(fine, affiliate);
      }

      _ref.invalidate(attendanceRecordsProvider(listId));
      state = AttendanceOperationSuccess("${affiliate.fullName} registrado como ${recordStatus.name}.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  // Finaliza una lista y genera multas por falta
  Future<void> finalizeList(AttendanceList list) async {
    state = AttendanceOperationLoading();
    try {
      // 1. Obtener todos los afiliados y los ya registrados
      final allAffiliates = _ref.read(affiliateListNotifierProvider.notifier).state.allAffiliates.asData?.value ?? [];
      final registeredRecords = await _attendanceRepo.getRecordsForList(list.id!);
      final registeredUuids = registeredRecords.map((r) => r.affiliateUuid).toSet();

      // 2. Encontrar a los que faltaron
      final missingAffiliates = allAffiliates.where((aff) => !registeredUuids.contains(aff.uuid)).toList();

      // 3. Crear multa por falta para cada uno
      final settings = _ref.read(settingsServiceProvider);
      final fineAmount = settings.getFineAmountAbsent();

      final fineNotifier = _ref.read(fineOperationProvider.notifier);
      for (final affiliate in missingAffiliates) {
        final fine = Fine(
          affiliateUuid: affiliate.uuid,
          amount: fineAmount, // Monto por falta (debería venir de config)
          description: "Multa por falta en lista: ${list.name}",
          category: FineCategory.Falta,
          date: DateTime.now(),
          relatedAttendanceId: list.id,
        );
        await fineNotifier.createFine(fine, affiliate);
      }

      // 4. Actualizar el estado de la lista a FINALIZADA
      await _attendanceRepo.updateListStatus(list.id!, AttendanceListStatus.FINALIZADA);

      _ref.invalidate(attendanceListProvider);
      _ref.invalidate(attendanceRecordsProvider(list.id!));
      state = AttendanceOperationSuccess("Lista finalizada. Se generaron ${missingAffiliates.length} multas por falta.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  Future<void> deleteAttendanceList(AttendanceList list) async {
    state = AttendanceOperationLoading();
    try {
      final relatedFines = await _fineRepo.getFinesByAttendanceList(list.id!);
      final fineNotifier = _ref.read(fineOperationProvider.notifier);
      final allAffiliates = _ref.read(affiliateListNotifierProvider.notifier).state.allAffiliates.asData?.value ?? [];

      for (var fine in relatedFines) {
        final affiliate = allAffiliates.firstWhere((a) => a.uuid == fine.affiliateUuid, orElse: () => Affiliate(uuid: '', id: '', firstName: '', lastName: '', ci: ''));
        if (affiliate.uuid.isNotEmpty) {
          await fineNotifier.deleteFine(fine, affiliate);
        }
      }
      
      await _attendanceRepo.deleteAttendanceList(list.id!);
      _ref.invalidate(attendanceListProvider);
      state = AttendanceOperationSuccess("Lista '${list.name}' y sus multas asociadas han sido eliminadas.");
    } catch (e) {
      state = AttendanceOperationError(e.toString());
    }
  }

  Future<void> deleteAttendanceRecord(AttendanceRecord record, Affiliate affiliate) async {
    state = AttendanceOperationLoading();
    try {
      await _attendanceRepo.deleteAttendanceRecord(record.id!);
      
      // Si el registro eliminado tenía una multa por retraso, la eliminamos también.
      if (record.status == AttendanceRecordStatus.RETRASO) {
          final fineNotifier = _ref.read(fineOperationProvider.notifier);
          final affiliateFines = await _fineRepo.getFinesForAffiliate(affiliate.uuid);
          final relatedFine = affiliateFines.firstWhere((f) => f.relatedAttendanceId == record.listId, orElse: () => Fine(id: -1, affiliateUuid: '', amount: 0, description: '', category: FineCategory.Varios, date: DateTime.now()));

          if (relatedFine.id != -1) {
              await fineNotifier.deleteFine(relatedFine, affiliate);
          }
      }

      _ref.invalidate(attendanceRecordsProvider(record.listId));
      state = AttendanceOperationSuccess("Registro de ${affiliate.fullName} eliminado.");

    } catch (e) { state = AttendanceOperationError(e.toString()); }
  }
}

// --- Providers ---

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(dbHelper);
});

final attendanceNotifierProvider = StateNotifierProvider<AttendanceNotifier, AttendanceOperationState>(
  (ref) => AttendanceNotifier(
    ref.watch(attendanceRepositoryProvider), ref.watch(fineRepositoryProvider), ref));


// Provider para obtener todas las listas de asistencia
final attendanceListProvider = FutureProvider<List<AttendanceList>>((ref) {
  return ref.watch(attendanceRepositoryProvider).getAllAttendanceLists();
});

// Provider para obtener los registros de una lista específica
final attendanceRecordsProvider = FutureProvider.family<List<AttendanceRecord>, int>((ref, listId) {
  return ref.watch(attendanceRepositoryProvider).getRecordsForList(listId);
});

final allAttendanceByAffiliateProvider = FutureProvider.family<List<AttendanceRecord>, String>((ref, affiliateUuid) {
  return ref.watch(attendanceRepositoryProvider).getAllRecordsForAffiliate(affiliateUuid);
});
