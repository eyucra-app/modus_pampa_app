import 'package:modus_pampa_v3/data/models/user_model.dart';
import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper;

  AuthRepository(this._dbHelper);

  // Registrar un nuevo usuario
  Future<void> register(User user) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Iniciar sesión
  Future<User?> login(String email, String passwordHash) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, passwordHash],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }
  
  // Verificar si un email ya existe
  Future<bool> checkIfEmailExists(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }
  
  // Obtener usuario por UUID (útil para la sesión)
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
  }
}
