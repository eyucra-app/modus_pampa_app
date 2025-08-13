import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/core/providers/dio_provider.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:modus_pampa_v3/data/repositories/affiliate_repository.dart';
import 'package:modus_pampa_v3/data/repositories/fine_repository.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/main.dart';
import 'package:modus_pampa_v3/shared/utils/decimal_utils.dart';

// --- Estados para operaciones ---
abstract class FineOperationState {}
class FineOperationInitial extends FineOperationState {}
class FineOperationLoading extends FineOperationState {}
class FineOperationSuccess extends FineOperationState { final String message; FineOperationSuccess(this.message); }
class FineOperationError extends FineOperationState { final String message; FineOperationError(this.message); }

// --- Notifier para operaciones ---
class FineOperationNotifier extends StateNotifier<FineOperationState> {
  final FineRepository _fineRepo;
  final AffiliateRepository _affiliateRepo;
  final Ref _ref;

  FineOperationNotifier(this._fineRepo, this._affiliateRepo, this._ref) : super(FineOperationInitial());

  Future<void> createFine(Fine fine, Affiliate affiliate) async {
    state = FineOperationLoading();
    try {
      // 1. Crear la multa
      await _fineRepo.createFine(fine);

      // 2. Actualizar la deuda del afiliado
      final updatedAffiliate = affiliate.copyWith(totalDebt: DecimalUtils.round(affiliate.totalDebt + fine.amount)); 
      await _affiliateRepo.updateAffiliate(updatedAffiliate);

      // 3. Invalidar providers
      _ref.invalidate(finesByAffiliateProvider(affiliate.uuid));
      _ref.invalidate(affiliatesWithFinesProvider);
      _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates();
      
      state = FineOperationSuccess('Multa creada con éxito.');
    } catch (e) {
      state = FineOperationError('Error al crear multa: ${e.toString()}');
    }
  }

  Future<void> payFine(Fine fine, double paymentAmount, Affiliate affiliate) async {
    state = FineOperationLoading();
    try {
      // 1. Pagar la multa
      await _fineRepo.payFine(fine.id!, paymentAmount);

      double newDebt = affiliate.totalDebt - paymentAmount;
      if (newDebt.abs() < 0.001) {
        newDebt = 0.0;
      }

      // 2. Actualizar totales del afiliado
      final updatedAffiliate = affiliate.copyWith(
        totalPaid: DecimalUtils.round(affiliate.totalPaid + paymentAmount),
        totalDebt: DecimalUtils.round(affiliate.totalDebt - paymentAmount),
      ); 
      
      await _affiliateRepo.updateAffiliate(updatedAffiliate);

      // 3. Invalidar providers
      _ref.invalidate(finesByAffiliateProvider(affiliate.uuid));
      _ref.invalidate(affiliatesWithFinesProvider);
      _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates();
      
      state = FineOperationSuccess('Pago de multa registrado.');
    } catch (e) {
      state = FineOperationError('Error al registrar pago: ${e.toString()}');
    }
  }

  Future<void> deleteFine(Fine fine, Affiliate affiliate) async {
    state = FineOperationLoading();
    try {
      // Pasamos el objeto 'fine' completo al repositorio
      await _fineRepo.deleteFine(fine);

      // 2. Actualizar los totales del afiliado (esto se queda igual)
      final updatedAffiliate = affiliate.copyWith(
        totalDebt: DecimalUtils.round(affiliate.totalDebt - (fine.amount - fine.amountPaid)),
        totalPaid: DecimalUtils.round(affiliate.totalPaid - fine.amountPaid),
      );
      await _affiliateRepo.updateAffiliate(updatedAffiliate);

      // 3. Invalidar los providers para refrescar la UI (esto se queda igual)
      _ref.invalidate(finesByAffiliateProvider(affiliate.uuid));
      _ref.invalidate(affiliatesWithFinesProvider);
      _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates();
      
      state = FineOperationSuccess('Multa eliminada.');
    } catch (e) {
      state = FineOperationError('Error al eliminar multa: ${e.toString()}');
    }
  }
}

// --- PROVIDERS ---

// 1. Provider para el Repositorio de Multas
final fineRepositoryProvider = Provider<FineRepository>((ref) {
  return FineRepository(
    dbHelper,
    ref.watch(pendingOperationRepositoryProvider), // Inyectar dependencia
    ref.watch(dioProvider), // Inyectar Dio
    ref.watch(settingsServiceProvider), // Inyectar SettingsService
  );
});

// 2. Provider para obtener afiliados que tienen multas pendientes
final affiliatesWithFinesProvider = FutureProvider<List<Affiliate>>((ref) async {
  final fineRepo = ref.watch(fineRepositoryProvider);
  final affiliateRepo = ref.watch(affiliateRepositoryProvider);

  final uuids = await fineRepo.getAffiliateUuidsWithFines();
  final allAffiliates = await affiliateRepo.getAllAffiliates();
  
  return allAffiliates.where((aff) => uuids.contains(aff.uuid)).toList();
});

// 3. Provider para obtener las multas de un afiliado específico
final finesByAffiliateProvider = FutureProvider.family<List<Fine>, String>((ref, affiliateUuid) {
  return ref.watch(fineRepositoryProvider).getFinesForAffiliate(affiliateUuid);
});

// 4. Provider para el Notifier de operaciones
final fineOperationProvider = StateNotifierProvider<FineOperationNotifier, FineOperationState>((ref) {
  return FineOperationNotifier(
    ref.watch(fineRepositoryProvider),
    ref.watch(affiliateRepositoryProvider),
    ref,
  );
});
