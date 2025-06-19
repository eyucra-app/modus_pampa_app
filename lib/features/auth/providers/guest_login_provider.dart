import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/repositories/affiliate_repository.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';

// Estados para el login de invitado
abstract class GuestLoginState {}
class GuestLoginInitial extends GuestLoginState {}
class GuestLoginLoading extends GuestLoginState {}
class GuestLoginSuccess extends GuestLoginState {
  final Affiliate affiliate;
  GuestLoginSuccess(this.affiliate);
}
class GuestLoginError extends GuestLoginState {
  final String message;
  GuestLoginError(this.message);
}

// Notifier que maneja la lógica
class GuestLoginNotifier extends StateNotifier<GuestLoginState> {
  final AffiliateRepository _affiliateRepo;

  GuestLoginNotifier(this._affiliateRepo) : super(GuestLoginInitial());

  Future<void> loginAsGuest(String id, String ci) async {
    state = GuestLoginLoading();
    try {
      final affiliate = await _affiliateRepo.findAffiliateByIdAndCi(id, ci);
      if (affiliate != null) {
        state = GuestLoginSuccess(affiliate);
      } else {
        state = GuestLoginError("Afiliado no encontrado. Verifique el ID y CI ingresados.");
      }
    } catch (e) {
      state = GuestLoginError("Ocurrió un error al buscar al afiliado.");
    }
  }
}

// Provider para la UI
final guestLoginProvider = StateNotifierProvider<GuestLoginNotifier, GuestLoginState>((ref) {
  return GuestLoginNotifier(ref.watch(affiliateRepositoryProvider));
});
