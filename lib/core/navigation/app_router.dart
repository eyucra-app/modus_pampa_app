// MODIFICATION: Import the async library for StreamSubscription.
import 'dart:async'; 

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/core/config/constants.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/features/affiliates/screens/affiliate_form_screen.dart';
import 'package:modus_pampa_v3/features/affiliates/screens/affiliates_screen.dart';
import 'package:modus_pampa_v3/features/attendance/screens/attendance_screen.dart';
import 'package:modus_pampa_v3/features/auth/providers/auth_providers.dart';
import 'package:modus_pampa_v3/features/auth/providers/guest_affiliate_provider.dart';
import 'package:modus_pampa_v3/features/auth/screens/guest_login_screen.dart';
import 'package:modus_pampa_v3/features/auth/screens/login_screen.dart';
import 'package:modus_pampa_v3/features/auth/screens/register_screen.dart';
import 'package:modus_pampa_v3/features/contributions/screens/contributions_screen.dart';
import 'package:modus_pampa_v3/features/fines/screens/fines_screen.dart';
import 'package:modus_pampa_v3/features/settings/screens/settings_screen.dart';
import 'package:modus_pampa_v3/shared/widgets/main_scaffold.dart';
import 'package:modus_pampa_v3/shared/widgets/side_menu.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    // Observa el provider de invitado para refrescar la redirección
    refreshListenable: GoRouterRefreshStream(ref.watch(guestAffiliateProvider.notifier).stream),
    routes: [
      // --- RUTAS PÚBLICAS Y DE INVITADO ---
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.guestLogin,
        builder: (context, state) => const GuestLoginScreen(),
      ),

      // --- RUTA PROTEGIDA PARA EL MODO INVITADO ---
      // Esta ruta construye su propio Scaffold con un SideMenu personalizado
      GoRoute(
        path: AppRoutes.guestDetail,
        builder: (context, state) {
          final affiliate = state.extra as Affiliate?;
          if (affiliate == null) {
            return const Scaffold(body: Center(child: Text("Error: Afiliado no proporcionado.")));
          }
          // Se pasa el afiliado al SideMenu para que se muestre en modo invitado.
          return Scaffold(
            // MODIFICATION: The 'guestAffiliate' parameter is removed.
            // SideMenu now gets its state from Riverpod automatically.
            drawer: const SideMenu(), 
            body: AffiliateFormScreen(
              affiliate: affiliate,
              isGuestMode: true,
            ),
          );
        },
      ),

      // --- RUTAS PROTEGIDAS PARA ADMINISTRADORES/USUARIOS ---
      // Todas estas rutas están envueltas por el MainScaffold, que tiene el SideMenu de admin.
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, redirect: (_, __) => AppRoutes.affiliates),
          GoRoute(path: AppRoutes.affiliates, builder: (context, state) => const AffiliatesScreen()),
          GoRoute(path: AppRoutes.contributions, builder: (context, state) => const ContributionsScreen()),
          GoRoute(path: AppRoutes.fines, builder: (context, state) => const FinesScreen()),
          GoRoute(path: AppRoutes.attendance, builder: (context, state) => const AttendanceScreen()),
          GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState is Authenticated;
      final isGuest = ref.read(guestAffiliateProvider) != null;

      final publicRoutes = [AppRoutes.login, AppRoutes.register, AppRoutes.guestLogin];
      final isGoingToPublic = publicRoutes.contains(state.matchedLocation);

      // Si no estamos autenticados Y no hay un invitado activo Y no vamos a una ruta pública -> al login.
      if (!isAuthenticated && !isGuest && !isGoingToPublic) {
        return AppRoutes.login;
      }
      
      // Si estamos autenticados y vamos a una ruta pública -> al home de admin.
      if (isAuthenticated && isGoingToPublic) {
        return AppRoutes.home;
      }

      // No se necesita redirección en los demás casos.
      return null;
    },
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Ruta no encontrada: ${state.error}'))),
  );
});

// Helper para que GoRouter reaccione a cambios en un Stream (como el de nuestro provider)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  // MODIFICATION: Changed 'Subscription' to the correct type 'StreamSubscription'.
  late final StreamSubscription _subscription;
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}