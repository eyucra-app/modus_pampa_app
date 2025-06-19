enum FineCategory {
  Varios,
  Retraso,
  Falta,
}

class Fine {
  final int? id;
  final String affiliateUuid;
  final double amount;
  final String description;
  final FineCategory category;
  final DateTime date;
  final double amountPaid;
  final bool isPaid;
  final int? relatedAttendanceId;

  Fine({
    this.id,
    required this.affiliateUuid,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    this.amountPaid = 0.0,
    this.isPaid = false,
    this.relatedAttendanceId,
  });

   Map<String, dynamic> toMap() {
    return {
      'id': id,
      'affiliate_uuid': affiliateUuid,
      'amount': amount,
      'description': description,
      'category': category.toString().split('.').last, // Guarda 'Varios', 'Retraso', etc.
      'date': date.toIso8601String(),
      'amount_paid': amountPaid,
      'is_paid': isPaid ? 1 : 0,
      'related_attendance_id': relatedAttendanceId,
    };
  }

  factory Fine.fromMap(Map<String, dynamic> map) {
    return Fine(
      id: map['id'],
      affiliateUuid: map['affiliate_uuid'],
      amount: map['amount'],
      description: map['description'],
      category: FineCategory.values.firstWhere((e) => e.toString().split('.').last == map['category']),
      date: DateTime.parse(map['date']),
      amountPaid: map['amount_paid'],
      isPaid: map['is_paid'] == 1,
      relatedAttendanceId: map['related_attendance_id'],
    );
  }
}
