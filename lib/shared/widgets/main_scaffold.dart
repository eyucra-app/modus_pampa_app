import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modus_pampa_v3/core/config/constants.dart';
import 'package:modus_pampa_v3/core/providers/theme_provider.dart';
import 'package:modus_pampa_v3/data/models/user_model.dart';
import 'package:modus_pampa_v3/features/auth/providers/auth_providers.dart';
import 'package:modus_pampa_v3/shared/widgets/side_menu.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _handleAppBarTap() {
    final now = DateTime.now();
    final userState = ref.read(authStateProvider);

    if (userState is Authenticated &&
       (userState.user.role == UserRole.admin || userState.user.role == UserRole.superAdmin)) {
      if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
        // Si ha pasado mucho tiempo, reinicia el conteo
        _tapCount = 1;
      } else {
        _tapCount++;
      }

      if (_tapCount == 3) {
        // Navegar a configuración
        context.go(AppRoutes.settings);
        _tapCount = 0; // Reiniciar
      }

      _lastTapTime = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleAppBarTap,
          child: const Text('Modus Pampa'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () {
              themeNotifier.toggleTheme();
            },
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: widget.child,
    );
  }
}
