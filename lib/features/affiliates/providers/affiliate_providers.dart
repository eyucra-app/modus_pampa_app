import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/repositories/affiliate_repository.dart';
import 'package:modus_pampa_v3/main.dart';

// --- ESTADOS ---

// Estado para la lista de afiliados (con filtrado)
class AffiliateListState {
  final AsyncValue<List<Affiliate>> allAffiliates;
  final Set<String> activeTags;

  AffiliateListState({
    this.allAffiliates = const AsyncLoading(),
    this.activeTags = const {},
  });

  // Deriva la lista filtrada del estado actual
  AsyncValue<List<Affiliate>> get filteredAffiliates {
    return allAffiliates.whenData((affiliates) {
      if (activeTags.isEmpty) {
        return affiliates;
      }
      return affiliates.where((aff) {
        return activeTags.any((tag) => aff.tags.contains(tag));
      }).toList();
    });
  }

  AffiliateListState copyWith({
    AsyncValue<List<Affiliate>>? allAffiliates,
    Set<String>? activeTags,
  }) {
    return AffiliateListState(
      allAffiliates: allAffiliates ?? this.allAffiliates,
      activeTags: activeTags ?? this.activeTags,
    );
  }
}

// Estado para operaciones CUD
abstract class AffiliateOperationState {}
class AffiliateOperationInitial extends AffiliateOperationState {}
class AffiliateOperationLoading extends AffiliateOperationState {}
class AffiliateOperationSuccess extends AffiliateOperationState { final String message; AffiliateOperationSuccess(this.message); }
class AffiliateOperationError extends AffiliateOperationState { final String message; AffiliateOperationError(this.message); }


// --- NOTIFIERS ---

// Notifier para la lista y el filtrado
class AffiliateListNotifier extends StateNotifier<AffiliateListState> {
  final AffiliateRepository _repository;
  AffiliateListNotifier(this._repository) : super(AffiliateListState()) {
    loadAffiliates();
  }

  Future<void> loadAffiliates() async {
    state = state.copyWith(allAffiliates: const AsyncLoading());
    try {
      final affiliates = await _repository.getAllAffiliates();
      state = state.copyWith(allAffiliates: AsyncData(affiliates));
    } catch (e, s) {
      state = state.copyWith(allAffiliates: AsyncError(e, s));
    }
  }

  void filterByTags(Set<String> tags) {
    state = state.copyWith(activeTags: tags);
  }
}

// Notifier para operaciones CUD
class AffiliateOperationNotifier extends StateNotifier<AffiliateOperationState> {
  final AffiliateRepository _repository;
  final Ref _ref;
  AffiliateOperationNotifier(this._repository, this._ref) : super(AffiliateOperationInitial());
  
  // CORRECCIÓN: Se llama a .loadAffiliates() en el notifier correcto
  Future<bool> createAffiliate(Affiliate affiliate) async { 
    state = AffiliateOperationLoading(); 
    try { 
      if (await _repository.checkIfIdExists(affiliate.id)) { state = AffiliateOperationError('El ID de afiliado ya existe.'); return false; } 
      if (await _repository.checkIfCiExists(affiliate.ci)) { state = AffiliateOperationError('El Carnet de Identidad ya está registrado.'); return false; } 
      await _repository.createAffiliate(affiliate); 
      _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates(); // Corregido
      state = AffiliateOperationSuccess('Afiliado creado con éxito.'); 
      return true; 
    } catch (e) { 
      state = AffiliateOperationError('Error al crear afiliado: ${e.toString()}'); return false; 
    } 
  }
  
  // CORRECCIÓN: Se llama a .loadAffiliates() en el notifier correcto
  Future<bool> updateAffiliate(Affiliate affiliate) async { 
    state = AffiliateOperationLoading(); 
    try { 
      if (await _repository.checkIfIdExists(affiliate.id, excludeUuid: affiliate.uuid)) { state = AffiliateOperationError('El ID de afiliado ya pertenece a otro registro.'); return false; } 
      if (await _repository.checkIfCiExists(affiliate.ci, excludeUuid: affiliate.uuid)) { state = AffiliateOperationError('El Carnet de Identidad ya pertenece a otro registro.'); return false; } 
      await _repository.updateAffiliate(affiliate); 
      _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates(); // Corregido
      state = AffiliateOperationSuccess('Afiliado actualizado con éxito.'); 
      return true; 
    } catch (e) { 
      state = AffiliateOperationError('Error al actualizar: ${e.toString()}'); return false; 
    } 
  }
  
  // CORRECCIÓN: Se llama a .loadAffiliates() en el notifier correcto
  Future<void> deleteAffiliate(String uuid) async { 
    state = AffiliateOperationLoading(); 
    try { 
      await _repository.deleteAffiliate(uuid); 
      _ref.read(affiliateListNotifierProvider.notifier).loadAffiliates(); // Corregido
      state = AffiliateOperationSuccess('Afiliado eliminado.'); 
    } catch(e) { 
      state = AffiliateOperationError('Error al eliminar: ${e.toString()}'); 
    } 
  }
}

// --- PROVIDERS ---

final affiliateRepositoryProvider = Provider<AffiliateRepository>((ref) => AffiliateRepository(dbHelper));

// ÚNICA FUENTE DE VERDAD para la lista de afiliados
final affiliateListNotifierProvider = StateNotifierProvider<AffiliateListNotifier, AffiliateListState>((ref) {
  return AffiliateListNotifier(ref.watch(affiliateRepositoryProvider));
});

final affiliateOperationProvider = StateNotifierProvider<AffiliateOperationNotifier, AffiliateOperationState>((ref) {
  return AffiliateOperationNotifier(ref.watch(affiliateRepositoryProvider), ref);
});
