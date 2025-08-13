// auth_repository.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:modus_pampa_v3/data/models/pending_operation_model.dart';
import 'package:modus_pampa_v3/data/models/user_model.dart';
import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/repositories/pending_operation_repository.dart';
import 'package:modus_pampa_v3/features/settings/providers/settings_provider.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper;
  final PendingOperationRepository _pendingOpRepo;
  final Dio _dio;
  final SettingsService _settingsService;

  AuthRepository(this._dbHelper, this._pendingOpRepo, this._dio, this._settingsService);

  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.ethernet);
  }

  Future<Response?> _sendToBackend(String endpoint, OperationType type, Map<String, dynamic> data) async {
    final backendUrl = _settingsService.getBackendUrl();
    try {
      switch (type) {
        case OperationType.CREATE:
          // Asumimos un endpoint de registro, ajusta si es diferente
          return await _dio.post('$backendUrl/api$endpoint', data: data); 
        case OperationType.UPDATE:
          return await _dio.put('$backendUrl/api$endpoint/${data['uuid']}', data: data);
        case OperationType.DELETE:
          return await _dio.delete('$backendUrl/api$endpoint/${data['uuid']}');
        default:
          return null;
      }
    } on DioException catch (e) {
      print('Error al enviar usuario a backend: ${e.message}');
      return null;
    } catch (e) {
      print('Error inesperado al enviar usuario a backend: $e');
      return null;
    }
  }

  Future<void> register(User user) async {
    final db = await _dbHelper.database;
    await db.insert(DatabaseHelper.tableUsers, user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    if (await _isConnected()) {
      // Usamos un endpoint genérico, podría ser '/users' o '/auth/register'
      final response = await _sendToBackend('/users', OperationType.CREATE, user.toMap());
      if (response != null && response.statusCode == 201) {
        print('Usuario registrado en backend y localmente.');
        return;
      }
    }
    
    // Si no hay conexión o la llamada a la red falló
    final op = PendingOperation(
      operationType: OperationType.CREATE,
      tableName: DatabaseHelper.tableUsers,
      data: user.toMap(),
      createdAt: DateTime.now(),
    );
    await _pendingOpRepo.createPendingOperation(op);
    print('Usuario guardado localmente, registro pendiente de sincronización.');
  }

  // ... resto de los métodos (login, updateUserRole, etc. no necesitan cambios)
  Future<User?> login(String email, String passwordHash) async {
    final db = await _dbHelper.database;
    print("🔍 Buscando usuario en DB local: email=$email");
    print("🔍 Hash a buscar: $passwordHash");
    
    // Primero verificar que el usuario existe
    final allUsers = await db.query(DatabaseHelper.tableUsers, where: 'email = ?', whereArgs: [email]);
    if (allUsers.isNotEmpty) {
      final storedHash = allUsers.first['password_hash'];
      print("🔍 Hash almacenado en DB: $storedHash");
      print("🔍 Hashes coinciden: ${storedHash == passwordHash}");
    } else {
      print("❌ Usuario no encontrado en DB local");
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, passwordHash],
    );

    print("🔍 Resultados de consulta: ${maps.length}");
    if (maps.isNotEmpty) {
      print("✅ Login exitoso en DB local");
      return User.fromMap(maps.first);
    }
    print("❌ Credenciales no coinciden en DB local");
    return null;
  }
  
  Future<bool> checkIfEmailExists(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }
  
  Future<User?> getUserByUuid(String uuid) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
          DatabaseHelper.tableUsers,
          where: 'uuid = ?',
          whereArgs: [uuid],
      );

      if (maps.isNotEmpty) {
          return User.fromMap(maps.first);
      }
      return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableUsers);
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<void> updateUserRole(String uuid, UserRole newRole) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableUsers,
      {'role': newRole.toString()},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    final data = {'uuid': uuid, 'role': newRole.toString()};

    if (await _isConnected()) {
      final response = await _sendToBackend('/users', OperationType.UPDATE, data);
      if (response != null && response.statusCode == 200) {
        print('Rol de usuario actualizado en backend y localmente.');
        return;
      }
    }
    final op = PendingOperation(
      operationType: OperationType.UPDATE,
      tableName: DatabaseHelper.tableUsers,
      data: data,
      createdAt: DateTime.now(),
    );
    await _pendingOpRepo.createPendingOperation(op);
    print('Rol de usuario actualizado como operación pendiente.');
  }

  Future<void> upsertUser(User user) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Elimina un usuario solo de la base de datos local.
  Future<void> deleteLocally(String uuid) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableUsers,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    print('Usuario con uuid: $uuid eliminado localmente.');
  }
}