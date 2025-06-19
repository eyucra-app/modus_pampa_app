import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/contribution_model.dart';
import 'package:modus_pampa_v3/data/repositories/affiliate_repository.dart';
import 'package:modus_pampa_v3/data/repositories/contribution_repository.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/main.dart';
import 'package:modus_pampa_v3/shared/utils/decimal_utils.dart';

abstract class ContributionOperationState {}
class ContributionOperationInitial extends ContributionOperationState {}
class ContributionOperationLoading extends ContributionOperationState {}
class ContributionOperationSuccess extends ContributionOperationState { final String message; ContributionOperationSuccess(this.message); }
class ContributionOperationError extends ContributionOperationState { final String message; ContributionOperationError(this.message); }

class ContributionOperationNotifier extends StateNotifier<ContributionOperationState> {
  final ContributionRepository _contributionRepo;
  final AffiliateRepository _affiliateRepo;
  final Ref _ref;

  ContributionOperationNotifier(this._contributionRepo, this._affiliateRepo, this._ref) : super(ContributionOperationInitial());

  Future<void> createContribution(Contribution contribution, List<Affiliate> selectedAffiliates) async {
    state = ContributionOperationLoading();
    try {
      final links = selectedAffiliates.map((aff) {
        return ContributionAffiliateLink(
          contributionId: 0,
          affiliateUuid: aff.uuid,
          amountToPay: contribution.defaultAmount, // Usa el monto base
        );
      }).toList();

      await _contributionRepo.createContribution(contribution, links);

      for (var affiliate in selectedAffiliates) {
          final updatedAffiliate = affiliate.copyWith(totalDebt: DecimalUtils.round(affiliate.totalDebt + contribution.defaultAmount)); 
          await _affiliateRepo.updateAffiliate(updatedAffiliate);
      }
      _ref.invalidate(contributionListProvider);
      _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates();
      state = ContributionOperationSuccess('Aporte creado y asignado con éxito.');
    } catch (e) {
      state = ContributionOperationError('Error al crear el aporte: ${e.toString()}');
    }
  }
  
  Future<void> updateContributionAmountForAffiliate(ContributionAffiliateLink oldLink, double newAmount, Affiliate affiliate) async {
    state = ContributionOperationLoading();
    try {
        final double amountDifference = newAmount - oldLink.amountToPay;
        final newLink = ContributionAffiliateLink(
            contributionId: oldLink.contributionId,
            affiliateUuid: oldLink.affiliateUuid,
            amountToPay: newAmount,
            amountPaid: oldLink.amountPaid,
            isPaid: newAmount <= oldLink.amountPaid,
        );
        await _contributionRepo.updateContributionLink(newLink);
        final updatedAffiliate = affiliate.copyWith(totalDebt: DecimalUtils.round(affiliate.totalDebt + amountDifference)); 
        await _affiliateRepo.updateAffiliate(updatedAffiliate);
        _ref.invalidate(contributionDetailProvider(oldLink.contributionId));
        _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates();
        state = ContributionOperationSuccess("Monto actualizado para ${affiliate.fullName}.");
    } catch (e) {
        state = ContributionOperationError("Error al actualizar monto: ${e.toString()}");
    }
  }

  Future<void> payContribution(ContributionAffiliateLink link, double paymentAmount, Affiliate affiliate) async {
    state = ContributionOperationLoading();
    try {
        await _contributionRepo.payContribution(link.contributionId, link.affiliateUuid, paymentAmount);
        
        double newDebt = affiliate.totalDebt - paymentAmount;
        if (newDebt.abs() < 0.001) {
          newDebt = 0.0;
        }
        
        final updatedAffiliate = affiliate.copyWith(
          totalPaid: DecimalUtils.round(affiliate.totalPaid + paymentAmount),
          totalDebt: DecimalUtils.round(affiliate.totalDebt - paymentAmount)
        ); 
        
        await _affiliateRepo.updateAffiliate(updatedAffiliate);

        // Se invalidan todos los providers relevantes para refrescar la UI en todas las pantallas.
        _ref.invalidate(contributionDetailProvider(link.contributionId));
        _ref.invalidate(pendingContributionsProvider(link.affiliateUuid)); // Invalida la lista del diálogo de pago
        _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates();
        
        state = ContributionOperationSuccess("Pago de Bs. $paymentAmount registrado.");

    } catch (e) {
        state = ContributionOperationError("Error al registrar el pago: ${e.toString()}");
    }
  }

  Future<void> deleteContribution(int contributionId) async {
    state = ContributionOperationLoading();
    try {
      // 1. Obtener los enlaces para saber a quiénes y cuánto se les descontará
      final links = await _contributionRepo.getLinksForContribution(contributionId);
      
      // 2. Eliminar el aporte (y sus enlaces en cascada)
      await _contributionRepo.deleteContribution(contributionId);

      // 3. Actualizar la deuda de los afiliados afectados
      final allAffiliates = _ref.read(affiliateListNotifierProvider.notifier).state.allAffiliates.asData?.value ?? [];
      for (var link in links) {
        final affiliate = allAffiliates.firstWhere((a) => a.uuid == link.affiliateUuid, orElse: () => Affiliate(uuid: '', id: '', firstName: '', lastName: '', ci: ''));
        
        if (affiliate.uuid.isNotEmpty) {

          final debtToDiscount = link.amountToPay - link.amountPaid;

          final updatedAffiliate = affiliate.copyWith(
            totalDebt: DecimalUtils.round(affiliate.totalDebt - debtToDiscount),
            totalPaid: DecimalUtils.round(affiliate.totalPaid - link.amountPaid),
          );

          await _affiliateRepo.updateAffiliate(updatedAffiliate);
        }
      }
      _ref.invalidate(contributionListProvider);
      _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates();
      state = ContributionOperationSuccess("Aporte eliminado con éxito.");
    } catch (e) {
      state = ContributionOperationError("Error al eliminar el aporte: ${e.toString()}");
    }
  }
}

final contributionRepositoryProvider = Provider<ContributionRepository>((ref) => ContributionRepository(dbHelper));
final contributionListProvider = FutureProvider<List<Contribution>>((ref) => ref.watch(contributionRepositoryProvider).getAllContributions());
final contributionDetailProvider = FutureProvider.family<List<ContributionAffiliateLink>, int>((ref, id) => ref.watch(contributionRepositoryProvider).getLinksForContribution(id));
final contributionOperationProvider = StateNotifierProvider<ContributionOperationNotifier, ContributionOperationState>((ref) => ContributionOperationNotifier(ref.watch(contributionRepositoryProvider), ref.watch(affiliateRepositoryProvider), ref));
final pendingContributionsProvider = FutureProvider.family<List<ContributionAffiliateLink>, String>((ref, affiliateUuid) {
  return ref.watch(contributionRepositoryProvider).getPendingContributionsForAffiliate(affiliateUuid);
});
final allContributionsByAffiliateProvider = FutureProvider.family<List<ContributionAffiliateLink>, String>((ref, affiliateUuid) {
  return ref.watch(contributionRepositoryProvider).getAllContributionsForAffiliate(affiliateUuid);
});