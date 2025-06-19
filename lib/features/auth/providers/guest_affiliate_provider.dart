import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';

/// Provider que mantiene el estado del afiliado que ha iniciado sesión como invitado.
///
/// Si es `null`, significa que no hay ningún invitado activo.
/// Si contiene un objeto [Affiliate], el SideMenu y otras partes de la UI
/// pueden adaptarse para mostrar la vista de invitado.
final guestAffiliateProvider = StateProvider<Affiliate?>((ref) => null);
