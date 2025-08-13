import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/models/pending_operation_model.dart';
import 'package:sqflite/sqflite.dart';

class PendingOperationRepository {
  final DatabaseHelper _dbHelper;

  PendingOperationRepository(this._dbHelper);

  /// Guarda una nueva operación pendiente en la base de datos local.
  Future<void> createPendingOperation(PendingOperation operation) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tablePendingOperations,
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las operaciones que están pendientes de ser sincronizadas.
  Future<List<PendingOperation>> getPendingOperations() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tablePendingOperations,
      orderBy: 'created_at ASC', // Las más antiguas primero
    );
    return maps.map((map) => PendingOperation.fromMap(map)).toList();
  }

  /// Elimina una operación pendiente, típicamente después de que se ha sincronizado con éxito.
  Future<void> deletePendingOperation(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tablePendingOperations,
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // Elimina todas las operaciones pendientes.
  Future<void> deleteAllPendingOperations() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tablePendingOperations);
  }
}
