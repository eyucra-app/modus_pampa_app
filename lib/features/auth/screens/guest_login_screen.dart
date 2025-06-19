import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modus_pampa_v3/core/config/constants.dart';
import 'package:modus_pampa_v3/features/auth/providers/guest_affiliate_provider.dart';
import 'package:modus_pampa_v3/features/auth/providers/guest_login_provider.dart';
import 'package:modus_pampa_v3/shared/utils/validators.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GuestLoginScreen extends ConsumerStatefulWidget {
  const GuestLoginScreen({super.key});

  @override
  ConsumerState<GuestLoginScreen> createState() => _GuestLoginScreenState();
}

class _GuestLoginScreenState extends ConsumerState<GuestLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _ciController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  void _findAffiliate() {
    if (_formKey.currentState!.validate()) {
      ref.read(guestLoginProvider.notifier).loginAsGuest(
            _idController.text.trim(),
            _ciController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(guestLoginProvider, (previous, next) {
      if (next is GuestLoginSuccess) {

        // 1. Establece el estado global del invitado para que el router lo reconozca.
        ref.read(guestAffiliateProvider.notifier).state = next.affiliate;
        
        // 2. Navega a la pantalla de detalle del invitado.
        context.push(AppRoutes.guestDetail, extra: next.affiliate);

      } else if (next is GuestLoginError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    final guestLoginState = ref.watch(guestLoginProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso de Afiliado'),
        // El back button automático funcionará si se navega con .push()
        // pero añadimos uno explícito por si acaso.
        automaticallyImplyLeading: false, 
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_search_outlined, size: 80).animate().fade().scale(),
                const SizedBox(height: 24),
                Text('Ingrese sus datos para ver su información', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 32),
                TextFormField(controller: _idController, decoration: const InputDecoration(labelText: 'ID de Afiliado', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()), validator: (value) => Validators.notEmpty(value, 'ID')).animate().fade(delay: 200.ms),
                const SizedBox(height: 16),
                TextFormField(controller: _ciController, decoration: const InputDecoration(labelText: 'Carnet de Identidad (CI)', prefixIcon: Icon(Icons.fingerprint), border: OutlineInputBorder()), validator: (value) => Validators.notEmpty(value, 'CI')).animate().fade(delay: 300.ms),
                const SizedBox(height: 32),
                if (guestLoginState is GuestLoginLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(onPressed: _findAffiliate, child: const Text('VER MI INFORMACIÓN')).animate().fade(delay: 400.ms),
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('<< Volver al Inicio de Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
