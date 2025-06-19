// representa un aporte general, como una cuota mensual o una recaudación especial.
class Contribution {
  final int? id;
  final String name;
  final String? description;
  final DateTime date;
  final double defaultAmount; // Monto por defecto del aporte
  final bool isGeneral; // Si es true, se aplica a todos por defecto

  Contribution({
    this.id,
    required this.name,
    this.description,
    required this.date,
    required this.defaultAmount,
    this.isGeneral = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'total_amount': defaultAmount,
      'is_general': isGeneral ? 1 : 0,
    };
  }

  factory Contribution.fromMap(Map<String, dynamic> map) {
    return Contribution(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      defaultAmount: map['total_amount'],
      isGeneral: map['is_general'] == 1,
    );
  }
}

// Representa la relación específica entre un afiliado y un aporte.
// Contiene el monto específico a pagar por ese afiliado y cuánto ha pagado.
class ContributionAffiliateLink {
  final int contributionId;
  final String affiliateUuid;
  final double amountToPay;
  final double amountPaid;
  final bool isPaid;

  ContributionAffiliateLink({
    required this.contributionId,
    required this.affiliateUuid,
    required this.amountToPay,
    this.amountPaid = 0.0,
    this.isPaid = false,
  });

   Map<String, dynamic> toMap() {
    return {
      'contribution_id': contributionId,
      'affiliate_uuid': affiliateUuid,
      'amount_to_pay': amountToPay,
      'amount_paid': amountPaid,
      'is_paid': isPaid ? 1 : 0,
    };
  }

  factory ContributionAffiliateLink.fromMap(Map<String, dynamic> map) {
    return ContributionAffiliateLink(
      contributionId: map['contribution_id'],
      affiliateUuid: map['affiliate_uuid'],
      amountToPay: map['amount_to_pay'],
      amountPaid: map['amount_paid'],
      isPaid: map['is_paid'] == 1,
    );
  }
}
