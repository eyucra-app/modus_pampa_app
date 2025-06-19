import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/models/fine_model.dart';
import 'package:sqflite/sqflite.dart';

class FineRepository {
  final DatabaseHelper _dbHelper;

  FineRepository(this._dbHelper);

  // Crear una nueva multa
  Future<void> createFine(Fine fine) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableFines,
      fine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  // Obtiene todas las multas asociadas a un ID de lista de asistencia.
  Future<List<Fine>> getFinesByAttendanceList(int listId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableFines,
      where: 'related_attendance_id = ?',
      whereArgs: [listId],
    );
    return maps.map((map) => Fine.fromMap(map)).toList();
  }

  // Obtener todas las multas de un afiliado específico
  Future<List<Fine>> getFinesForAffiliate(String affiliateUuid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableFines,
      where: 'affiliate_uuid = ?',
      whereArgs: [affiliateUuid],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Fine.fromMap(maps[i]));
  }

  // Obtener todos los UUIDs de afiliados que tienen multas
  Future<List<String>> getAffiliateUuidsWithFines() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT affiliate_uuid FROM ${DatabaseHelper.tableFines} WHERE is_paid = 0'
    );
    return List.generate(maps.length, (i) => maps[i]['affiliate_uuid'] as String);
  }

  // Registrar un pago para una multa específica
  Future<void> payFine(int fineId, double paymentAmount) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Obtiene la multa actual
      final List<Map<String, dynamic>> maps = await txn.query(
        DatabaseHelper.tableFines,
        where: 'id = ?',
        whereArgs: [fineId],
      );

      if (maps.isNotEmpty) {
        final fine = Fine.fromMap(maps.first);
        final newAmountPaid = fine.amountPaid + paymentAmount;
        final isPaid = newAmountPaid >= fine.amount;

        // 2. Actualiza la multa
        await txn.update(
          DatabaseHelper.tableFines,
          {
            'amount_paid': newAmountPaid,
            'is_paid': isPaid ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [fineId],
        );
        // La actualización de los totales del afiliado se centralizará en el provider.
      }
    });
  }

  Future<void> deleteFine(int fineId) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableFines,
      where: 'id = ?',
      whereArgs: [fineId],
    );
  }

  
}
