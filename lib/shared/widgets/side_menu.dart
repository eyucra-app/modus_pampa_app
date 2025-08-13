import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modus_pampa_v3/core/config/constants.dart';
import 'package:modus_pampa_v3/core/providers/connectivity_provider.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:modus_pampa_v3/data/models/user_model.dart';
import 'package:modus_pampa_v3/features/auth/providers/auth_providers.dart';

class SideMenu extends ConsumerWidget {
  final Affiliate? guestAffiliate; // Parámetro para activar el modo invitado

  const SideMenu({super.key, this.guestAffiliate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final bool isGuestMode = guestAffiliate != null;

    return Drawer(
      child: Column(
        children: [
          // --- Encabezado dinámico ---
          if (isGuestMode)
            _buildGuestHeader(context, guestAffiliate!)
          else if (authState is Authenticated)
            _buildUserHeader(context, authState.user),
          
          // --- Contenido del menú ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: isGuestMode
                  ? _buildGuestMenuItems(context)
                  : (authState is Authenticated ? _buildAdminMenuItems(authState.user.role, context) : []),
            ),
          ),
          
          // --- Pie de menú (solo para admin) ---
          if (!isGuestMode) ...[
            const Divider(),
            _buildConnectivityStatus(context, ref), // Indicador de conectividad dinámico
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Operaciones Pendientes'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.pendingOperations);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authStateProvider.notifier).logout();
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildConnectivityStatus(BuildContext context, WidgetRef ref) {
    final connectivityResult = ref.watch(connectivityStreamProvider);
    return connectivityResult.when(
      data: (result) {
        final isOnline = result.contains(ConnectivityResult.mobile) || 
                        result.contains(ConnectivityResult.wifi) || 
                        result.contains(ConnectivityResult.ethernet);
        print("🔄 Connectivity status - Online: $isOnline, Result: $result");
        return ListTile(
          leading: Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: isOnline ? Colors.green.shade600 : Colors.grey,
          ),
          title: Text(isOnline ? 'En Línea' : 'Modo Offline'),
          subtitle: isOnline ? null : const Text('Las operaciones se guardarán localmente'),
          onTap: () {
            // Aquí se podría navegar a la pantalla de sincronización
          },
        );
      },
      loading: () {
        print("⏳ Connectivity status - Loading state");
        // En web, mostrar directamente "En Línea" si está cargando por mucho tiempo
        if (kIsWeb) {
          return ListTile(
            leading: Icon(Icons.wifi, color: Colors.green.shade600),
            title: const Text('En Línea'),
          );
        }
        return const ListTile(title: Text("Verificando conexión..."));
      },
      error: (err, stack) {
        print("❌ Connectivity status - Error: $err");
        return const ListTile(
          title: Text("Error de conectividad"), 
          leading: Icon(Icons.error, color: Colors.red)
        );
      },
    );
  }

  // --- WIDGETS DE CONSTRUCCIÓN ---

  Widget _buildGuestHeader(BuildContext context, Affiliate affiliate) {
    return UserAccountsDrawerHeader(
      accountName: Text(affiliate.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      accountEmail: const Text("Modo Afiliado"),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
      ),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildUserHeader(BuildContext context, User user) {
    return UserAccountsDrawerHeader(
      accountName: Text(user.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
      accountEmail: Text(user.email),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Text(
          user.userName.isNotEmpty ? user.userName[0].toUpperCase() : 'U',
          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24),
        ),
      ),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
    );
  }

  List<Widget> _buildGuestMenuItems(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.exit_to_app),
        title: const Text('Salir del Modo Afiliado'),
        onTap: () {
          context.go('/login');
        },
      ),
    ];
  }

  List<Widget> _buildAdminMenuItems(UserRole role, BuildContext context) {
    List<Widget> menuItems = [
      _menuItem(context, 'Afiliados', FontAwesomeIcons.users, AppRoutes.affiliates),
      _menuItem(context, 'Asistencia', FontAwesomeIcons.clipboardUser, AppRoutes.attendance),
    ];
    if (role == UserRole.admin || role == UserRole.superAdmin) {
      menuItems.insertAll(1, [
        _menuItem(context, 'Aportes', FontAwesomeIcons.handHoldingDollar, AppRoutes.contributions),
        _menuItem(context, 'Multas', FontAwesomeIcons.fileInvoiceDollar, AppRoutes.fines),
      ]);
    }
    return menuItems;
  }

  Widget _menuItem(BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      leading: FaIcon(icon, size: 20),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
