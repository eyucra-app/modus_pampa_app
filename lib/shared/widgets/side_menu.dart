import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modus_pampa_v3/core/config/constants.dart';
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
            ListTile(
              leading: const Icon(Icons.wifi_off, color: Colors.grey),
              title: const Text('Modo Offline'),
              subtitle: const Text('Sincronización pendiente'),
              onTap: () {
                // TODO: Navegar a la pantalla de operaciones pendientes
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
