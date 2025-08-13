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
import 'package:modus_pampa_v3/features/auth/screens/offline_splash_screen.dart';
import 'package:modus_pampa_v3/features/auth/screens/register_screen.dart';
import 'package:modus_pampa_v3/features/auth/screens/splash_screen.dart';
import 'package:modus_pampa_v3/features/contributions/screens/contributions_screen.dart';
import 'package:modus_pampa_v3/features/fines/screens/fines_screen.dart';
import 'package:modus_pampa_v3/features/settings/screens/settings_screen.dart';
import 'package:modus_pampa_v3/features/settings/screens/pending_operations_screen.dart';
import 'package:modus_pampa_v3/shared/widgets/main_scaffold.dart';
import 'package:modus_pampa_v3/shared/widgets/side_menu.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 1. Observa el estado de autenticación. GoRouter se reconstruirá si cambia.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splashScreen,
    // 2. El refreshListenable se encarga de los cambios en el modo invitado,
    // por lo que no necesitamos lógica de invitado en el redirect.
    refreshListenable: GoRouterRefreshStream(ref.watch(guestAffiliateProvider.notifier).stream),
    routes: [
      // --- RUTAS PÚBLICAS Y DE INVITADO ---
      GoRoute(
        path: AppRoutes.offlineSplashScreen,
        builder: (context, state) => const OfflineSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.splashScreen,
        builder: (context, state) => const SplashScreen(),
      ),
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
          GoRoute(path: AppRoutes.pendingOperations, builder: (context, state) => const PendingOperationsScreen()),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState is Authenticated;
      final location = state.matchedLocation;

      // Define todas las rutas que un usuario puede visitar SIN estar autenticado.
      final publicRoutes = [
        AppRoutes.splashScreen,
        AppRoutes.offlineSplashScreen,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.guestLogin,
        AppRoutes.guestDetail,
      ];

      // Si el usuario está logueado y trata de ir a la pantalla de login, lo mandamos a home.
      if (isAuthenticated && location == AppRoutes.login) {
        return AppRoutes.home;
      }

      // Si el usuario NO está logueado y trata de ir a una ruta que NO es pública,
      // lo mandamos al login.
      if (!isAuthenticated && !publicRoutes.contains(location)) {
        return AppRoutes.login;
      }

      // Para todos los demás casos (usuario logueado en ruta protegida, cualquier
      // usuario en una ruta pública), no hacemos nada.
      return null;
    },
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Ruta no encontrada: ${state.error}'))),
  );
});

// Helper para que GoRouter reaccione a cambios en un Stream
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}