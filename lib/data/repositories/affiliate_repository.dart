import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/models/affiliate_model.dart';
import 'package:sqflite/sqflite.dart';

class AffiliateRepository {
  final DatabaseHelper _dbHelper;

  AffiliateRepository(this._dbHelper);

  // Crear un nuevo afiliado
  Future<void> createAffiliate(Affiliate affiliate) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableAffiliates,
      affiliate.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail, // Falla si hay conflicto de PK (uuid)
    );
  }

  // Obtener todos los afiliados
  Future<List<Affiliate>> getAllAffiliates() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableAffiliates, orderBy: 'last_name ASC');
    return List.generate(maps.length, (i) {
      return Affiliate.fromMap(maps[i]);
    });
  }

  // Actualizar un afiliado
  Future<void> updateAffiliate(Affiliate affiliate) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableAffiliates,
      affiliate.toMap(),
      where: 'uuid = ?',
      whereArgs: [affiliate.uuid],
    );
  }

  // Eliminar un afiliado
  Future<void> deleteAffiliate(String uuid) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableAffiliates,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  // Verificar si un ID ya existe (excluyendo el afiliado actual si se provee su uuid)
  Future<bool> checkIfIdExists(String id, {String? excludeUuid}) async {
    final db = await _dbHelper.database;
    String whereClause = 'id = ?';
    List<dynamic> whereArgs = [id];
    if (excludeUuid != null) {
      whereClause += ' AND uuid != ?';
      whereArgs.add(excludeUuid);
    }
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAffiliates,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.isNotEmpty;
  }

  // Verificar si un CI ya existe (excluyendo el afiliado actual si se provee su uuid)
  Future<bool> checkIfCiExists(String ci, {String? excludeUuid}) async {
    final db = await _dbHelper.database;
    String whereClause = 'ci = ?';
    List<dynamic> whereArgs = [ci];
    if (excludeUuid != null) {
      whereClause += ' AND uuid != ?';
      whereArgs.add(excludeUuid);
    }
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAffiliates,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.isNotEmpty;
  }
  
  Future<Affiliate?> findAffiliateByIdAndCi(String id, String ci) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAffiliates,
      where: 'id = ? AND ci = ?',
      whereArgs: [id, ci],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Affiliate.fromMap(maps.first);
    }
    return null;
  }
}
