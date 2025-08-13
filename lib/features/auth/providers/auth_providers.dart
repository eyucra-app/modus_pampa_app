import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/core/providers/dio_provider.dart';
import 'package:modus_pampa_v3/data/models/user_model.dart';
import 'package:modus_pampa_v3/data/repositories/auth_repository.dart';
import 'package:modus_pampa_v3/features/affiliates/providers/affiliate_providers.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:modus_pampa_v3/main.dart'; // Para dbHelper y sharedPreferences
import 'package:uuid/uuid.dart';

// Estado de la Autenticación
abstract class AuthState {
  const AuthState();
}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
}
class Unauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ---- StateNotifier para la Autenticación ----
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthInitial()) {
    _init();
  }
  
  // Inicia y comprueba si hay una sesión guardada
  Future<void> _init() async {
    final userUuid = sharedPreferences.getString('session_user_uuid');
    if (userUuid != null) {
      final user = await _authRepository.getUserByUuid(userUuid);
      if (user != null) {
        state = Authenticated(user);
      } else {
        state = Unauthenticated();
      }
    } else {
      state = Unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      print("🔐 Intentando login para: $email");
      print("🔑 Contraseña ingresada: $password");
      print("🔒 Hash generado: $passwordHash");
      
      final user = await _authRepository.login(email, passwordHash);
      if (user != null) {
        print("✅ Usuario autenticado correctamente: ${user.email}");
        await sharedPreferences.setString('session_user_uuid', user.uuid);
        state = Authenticated(user);
      } else {
        print("❌ Credenciales incorrectas para: $email");
        print("🚨 Emitiendo estado AuthError...");
        state = const AuthError('Correo o contraseña incorrectos.');
        print("🚨 Estado AuthError emitido correctamente.");
      }
    } catch (e) {
      print("💥 Error en login: $e");
      state = AuthError('Error al iniciar sesión: ${e.toString()}');
    }
  }

  Future<void> register({
    required String userName,
    required String email,
    required String password,
    UserRole role = UserRole.superAdmin, // Rol por defecto
  }) async {
    state = AuthLoading();
    try {
      final emailExists = await _authRepository.checkIfEmailExists(email);
      if (emailExists) {
        state = const AuthError('El correo electrónico ya está registrado.');
        return;
      }

      final now = DateTime.now(); // Get current time
      final newUser = User(
        uuid: const Uuid().v4(),
        userName: userName,
        email: email,
        passwordHash: sha256.convert(utf8.encode(password)).toString(),
        role: role,
        createdAt: now, // Provide createdAt
        updatedAt: now, // Initialize updatedAt
      );
      await _authRepository.register(newUser);
      // Después de registrar, iniciar sesión automáticamente
      await login(email, password);
    } catch (e) {
      state = AuthError('Error al registrar: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await sharedPreferences.remove('session_user_uuid');
    state = Unauthenticated();
  }

  Future<void> updateUserRole(String uuid, UserRole newRole) async {
    await _authRepository.updateUserRole(uuid, newRole);
    // Si el usuario actualizado es el actual, refresca su estado
    if (state is Authenticated && (state as Authenticated).user.uuid == uuid) {
        final updatedUser = await _authRepository.getUserByUuid(uuid);
        state = Authenticated(updatedUser!);
    }
  }
}

// ---- Providers de Riverpod ----

// Provider para el Repositorio
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dbHelper,
    ref.watch(pendingOperationRepositoryProvider),
    ref.watch(dioProvider), // Inyectar Dio
    ref.watch(settingsServiceProvider), // Inyectar SettingsService
  );
});

// Provider para el StateNotifier de Autenticación
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

final allUsersProvider = FutureProvider<List<User>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getAllUsers();
});