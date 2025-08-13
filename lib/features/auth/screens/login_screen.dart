import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modus_pampa_v3/core/config/constants.dart';
import 'package:modus_pampa_v3/features/auth/providers/auth_providers.dart';
import 'package:modus_pampa_v3/shared/utils/validators.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  int _welcomeTapCount = 0;
  bool _showRegisterButton = false;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  void _handleWelcomeTap() {
    setState(() {
      _welcomeTapCount++;
      if (_welcomeTapCount >= 5) {
        _showRegisterButton = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      print("🎧 Login screen listener - Previous: ${previous.runtimeType}, Next: ${next.runtimeType}");
      if (next is AuthError) {
        print("🚨 Mostrando SnackBar de error: ${next.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (next is Authenticated) {
        print("✅ Usuario autenticado en UI: ${next.user.email}");
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _handleWelcomeTap,
                  child: Text(
                    'Bienvenido a\nModus Pampa v3',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ).animate().fade(duration: 500.ms).slideY(begin: -0.5),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ).animate().fade(delay: 200.ms),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                      Validators.notEmpty(value, 'Contraseña'),
                ).animate().fade(delay: 300.ms),
                const SizedBox(height: 32),
                if (authState is AuthLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('INICIAR SESIÓN'),
                  ).animate().fade(delay: 400.ms),
                const SizedBox(height: 16),
                Visibility(
                  visible: _showRegisterButton,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.register),
                    child: const Text('¿No tienes una cuenta? Regístrate'),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.guestLogin),
                  child: const Text('Soy Afiliado (Ingresar como invitado)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
