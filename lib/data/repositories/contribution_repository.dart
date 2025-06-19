import 'package:modus_pampa_v3/core/database/database_helper.dart';
import 'package:modus_pampa_v3/data/models/contribution_model.dart';
import 'package:sqflite/sqflite.dart';

class ContributionRepository {
  final DatabaseHelper _dbHelper;

  ContributionRepository(this._dbHelper);

  Future<void> createContribution(Contribution contribution, List<ContributionAffiliateLink> links) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final contributionId = await txn.insert(DatabaseHelper.tableContributions, contribution.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (final link in links) {
        final linkMap = link.toMap();
        linkMap['contribution_id'] = contributionId; 
        await txn.insert(DatabaseHelper.tableContributionAffiliates, linkMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Contribution>> getAllContributions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableContributions, orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Contribution.fromMap(maps[i]));
  }

  Future<List<ContributionAffiliateLink>> getLinksForContribution(int contributionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableContributionAffiliates, where: 'contribution_id = ?', whereArgs: [contributionId]);
     return List.generate(maps.length, (i) => ContributionAffiliateLink.fromMap(maps[i]));
  }
  
  // -- NUEVO MÉTODO --
  // Actualiza un enlace específico (ej: para cambiar el monto a pagar)
  Future<void> updateContributionLink(ContributionAffiliateLink link) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableContributionAffiliates,
      link.toMap(),
      where: 'contribution_id = ? AND affiliate_uuid = ?',
      whereArgs: [link.contributionId, link.affiliateUuid],
    );
  }

  Future<void> payContribution(int contributionId, String affiliateUuid, double paymentAmount) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> maps = await txn.query(DatabaseHelper.tableContributionAffiliates, where: 'contribution_id = ? AND affiliate_uuid = ?', whereArgs: [contributionId, affiliateUuid]);

      if (maps.isNotEmpty) {
        final link = ContributionAffiliateLink.fromMap(maps.first);
        final newAmountPaid = link.amountPaid + paymentAmount;
        final isPaid = newAmountPaid >= link.amountToPay;

        await txn.update(DatabaseHelper.tableContributionAffiliates, {'amount_paid': newAmountPaid, 'is_paid': isPaid ? 1 : 0}, where: 'contribution_id = ? AND affiliate_uuid = ?', whereArgs: [contributionId, affiliateUuid]);
      }
    });
  }

  Future<void> deleteContribution(int contributionId) async {
    final db = await _dbHelper.database;
    // Se elimina el aporte. Gracias a la configuración de la base de datos
    // con 'ON DELETE CASCADE', los enlaces en la tabla 'contribution_affiliates'
    // se eliminarán automáticamente.
    await db.delete(
      DatabaseHelper.tableContributions,
      where: 'id = ?',
      whereArgs: [contributionId],
    );
  }

  Future<List<ContributionAffiliateLink>> getAllContributionsForAffiliate(String affiliateUuid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableContributionAffiliates,
      where: 'affiliate_uuid = ?',
      whereArgs: [affiliateUuid],
    );
     return List.generate(maps.length, (i) => ContributionAffiliateLink.fromMap(maps[i]));
  }

  Future<List<ContributionAffiliateLink>> getPendingContributionsForAffiliate(String affiliateUuid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableContributionAffiliates,
      where: 'affiliate_uuid = ? AND is_paid = 0',
      whereArgs: [affiliateUuid],
    );
     return List.generate(maps.length, (i) => ContributionAffiliateLink.fromMap(maps[i]));
  }
}
