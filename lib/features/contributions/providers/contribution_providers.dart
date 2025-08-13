// contribution_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/core/providers/dio_provider.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/contribution_model.dart';
import 'package:modus_pampa_v3/data/repositories/affiliate_repository.dart';
import 'package:modus_pampa_v3/data/repositories/contribution_repository.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/main.dart';
import 'package:modus_pampa_v3/shared/utils/decimal_utils.dart';
import 'package:uuid/uuid.dart';

abstract class ContributionOperationState {}

class ContributionOperationInitial extends ContributionOperationState {}

class ContributionOperationLoading extends ContributionOperationState {}

class ContributionOperationSuccess extends ContributionOperationState {
  final String message;
  ContributionOperationSuccess(this.message);
}

class ContributionOperationError extends ContributionOperationState {
  final String message;
  ContributionOperationError(this.message);
}

class ContributionOperationNotifier
    extends StateNotifier<ContributionOperationState> {
  final ContributionRepository _contributionRepo;
  final AffiliateRepository _affiliateRepo;
  final Ref _ref;

  ContributionOperationNotifier(
    this._contributionRepo,
    this._affiliateRepo,
    this._ref,
  ) : super(ContributionOperationInitial());

  /// **LÓGICA DE CREACIÓN SIMPLIFICADA**
  /// Ahora solo prepara los datos y llama al método transaccional del repositorio.
  Future<void> createContribution(
    Contribution contribution,
    List<Affiliate> selectedAffiliates,
  ) async {
    state = ContributionOperationLoading();
    try {
      final now = DateTime.now();
      final newContribution = contribution.copyWith(
        uuid: const Uuid().v4(),
        createdAt: now,
        updatedAt: now,
      );

      final links =
          selectedAffiliates.map((aff) {
            return ContributionAffiliateLink(
              uuid: const Uuid().v4(),
              contributionUuid: newContribution.uuid,
              affiliateUuid: aff.uuid,
              amountToPay: newContribution.defaultAmount,
              createdAt: now,
              updatedAt: now,
            );
          }).toList();

      // **LLAMADA AL NUEVO MÉTODO ATÓMICO**
      // Este método se encarga de la transacción local y la sincronización.
      await _contributionRepo.createContributionInTransaction(
        newContribution,
        links,
      );

      // Ahora, actualizamos la deuda de los afiliados en un solo lote.
      final Map<String, double> debtChanges = {
        for (var aff in selectedAffiliates)
          aff.uuid: newContribution.defaultAmount,
      };
      await _affiliateRepo.bulkUpdateAffiliateDebts(debtChanges);

      print("✅ Deudas de afiliados actualizadas localmente en lote.");

      // Invalidamos los providers para que la UI se refresque desde la fuente de verdad (la BD).
      _ref.invalidate(contributionListProvider);
      _ref.invalidate(affiliateListNotifierProvider);

      state = ContributionOperationSuccess(
        'Aporte creado y asignado con éxito.',
      );
    } catch (e) {
      print("❌ Error catastrófico al crear aporte: ${e.toString()}");
      state = ContributionOperationError(
        'Error al crear el aporte: ${e.toString()}',
      );
    }
  }

  Future<void> updateContributionAmountForAffiliate(
    ContributionAffiliateLink oldLink,
    double newAmount,
    Affiliate affiliate,
  ) async {
    state = ContributionOperationLoading();
    try {
      final double amountDifference = newAmount - oldLink.amountToPay;
      final now = DateTime.now();

      // Creamos el nuevo link con el monto actualizado
      final newLink = oldLink.copyWith(
        amountToPay: newAmount,
        isPaid: newAmount <= oldLink.amountPaid, // Re-evaluamos si está pagado
        updatedAt: now,
      );

      // 1. Actualizamos el enlace del aporte en su repositorio
      await _contributionRepo.updateContributionLink(newLink);

      // 2. Aplicamos la diferencia de deuda al afiliado usando el método robusto
      if (amountDifference != 0) {
        await _affiliateRepo.bulkUpdateAffiliateDebts({
          affiliate.uuid: amountDifference,
        });
      }

      // 3. Invalidamos providers para refrescar la UI
      _ref.invalidate(contributionDetailProvider(oldLink.contributionUuid));
      _ref.invalidate(affiliateListNotifierProvider);

      state = ContributionOperationSuccess(
        "Monto actualizado para ${affiliate.fullName}.",
      );
    } catch (e) {
      state = ContributionOperationError(
        "Error al actualizar monto: ${e.toString()}",
      );
    }
  }

  Future<void> payContribution(
    ContributionAffiliateLink link,
    double paymentAmount,
    Affiliate affiliate,
  ) async {
    state = ContributionOperationLoading();
    try {
      final newAmountPaid = link.amountPaid + paymentAmount;

      // 1. Actualizar el enlace del aporte (esto ahora maneja 'is_paid' correctamente).
      await _contributionRepo.payContribution(link, newAmountPaid);

      // 2. Aplicar el pago al afiliado (esto actualiza 'total_debt' y 'total_paid').
      // Este método ya no es necesario aquí si 'sync_service' hace el recálculo.
      // Lo dejamos para la actualización inmediata en el dispositivo que realiza la acción.
      await _affiliateRepo.applyPaymentToAffiliate(
        affiliateUuid: affiliate.uuid,
        paymentAmount: paymentAmount,
      );

      // 3. Invalidar providers para refrescar la UI localmente.
      _ref.invalidate(contributionDetailProvider(link.contributionUuid));
      _ref.invalidate(pendingContributionsProvider(link.affiliateUuid));
      _ref.invalidate(affiliateListNotifierProvider);

      state = ContributionOperationSuccess(
        "Pago de Bs. $paymentAmount registrado.",
      );
    } catch (e) {
      state = ContributionOperationError(
        "Error al registrar el pago: ${e.toString()}",
      );
    }
  }

  Future<void> deleteContribution(String contributionUuid) async {
    state = ContributionOperationLoading();
    try {
      // 1. Obtener los enlaces para saber qué afiliados y montos están involucrados
      final links = await _contributionRepo.getLinksForContribution(contributionUuid);

      // 2. Obtener un mapa de todos los afiliados para acceder fácilmente a sus datos actuales
      final allAffiliates = await _ref.read(affiliateRepositoryProvider).getAllAffiliates();
      final affiliateMap = {for (var aff in allAffiliates) aff.uuid: aff};

      // 3. Eliminar la contribución (esto maneja la BD local y la sincronización)
      await _contributionRepo.deleteContribution(contributionUuid);

      // 4. Iterar sobre cada enlace para ajustar los totales de cada afiliado afectado
      for (var link in links) {
        final originalAffiliate = affiliateMap[link.affiliateUuid];
        if (originalAffiliate != null) {
          final debtToReverse = link.amountToPay - link.amountPaid;
          final paidToReverse = link.amountPaid;

          // Solo actualizamos si hay algo que revertir para evitar operaciones innecesarias
          if (debtToReverse > 0 || paidToReverse > 0) {
              final updatedAffiliate = originalAffiliate.copyWith(
                totalDebt: DecimalUtils.round(originalAffiliate.totalDebt - debtToReverse),
                totalPaid: DecimalUtils.round(originalAffiliate.totalPaid - paidToReverse),
                updatedAt: DateTime.now() // Es importante actualizar la fecha de modificación
              );
              // Usamos el método existente que ya maneja la actualización local y la sincronización
              await _ref.read(affiliateRepositoryProvider).updateAffiliate(updatedAffiliate);
          }
        }
      }

      // 5. Invalidar los providers para que la interfaz de usuario se actualice
      _ref.invalidate(contributionListProvider);
      _ref.invalidate(affiliateListNotifierProvider); 
      
      state = ContributionOperationSuccess("Aporte eliminado y totales de afiliados ajustados con éxito.");

    } catch (e) {
      state = ContributionOperationError("Error al eliminar el aporte: ${e.toString()}");
    }
  }
}

// --- PROVIDERS (sin cambios en su definición) ---
final contributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  return ContributionRepository(
    dbHelper,
    ref.watch(pendingOperationRepositoryProvider),
    ref.watch(dioProvider),
    ref.watch(settingsServiceProvider),
  );
});
final contributionListProvider = FutureProvider<List<Contribution>>(
  (ref) => ref.watch(contributionRepositoryProvider).getAllContributions(),
);
final contributionDetailProvider =
    FutureProvider.family<List<ContributionAffiliateLink>, String>(
      (ref, uuid) => ref
          .watch(contributionRepositoryProvider)
          .getLinksForContribution(uuid),
    );
final contributionOperationProvider = StateNotifierProvider<
  ContributionOperationNotifier,
  ContributionOperationState
>(
  (ref) => ContributionOperationNotifier(
    ref.watch(contributionRepositoryProvider),
    ref.watch(affiliateRepositoryProvider),
    ref,
  ),
);
final pendingContributionsProvider =
    FutureProvider.family<List<ContributionAffiliateLink>, String>((
      ref,
      affiliateUuid,
    ) {
      return ref
          .watch(contributionRepositoryProvider)
          .getPendingContributionsForAffiliate(affiliateUuid);
    });
final allContributionsByAffiliateProvider =
    FutureProvider.family<List<ContributionAffiliateLink>, String>((
      ref,
      affiliateUuid,
    ) {
      return ref
          .watch(contributionRepositoryProvider)
          .getAllContributionsForAffiliate(affiliateUuid);
    });
