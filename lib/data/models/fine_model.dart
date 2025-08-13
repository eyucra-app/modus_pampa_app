enum FineCategory {
  Varios,
  Retraso,
  Falta,
}

class Fine {
  final int? id; // ID local autoincremental de SQLite
  final String uuid; // UUID para consistencia con backend
  final String affiliateUuid; // UUID del afiliado
  final String? relatedAttendanceUuid; // UUID de la lista de asistencia relacionada (opcional)
  final String description;
  final double amount;
  final double amountPaid;
  final bool isPaid;
  final FineCategory category; // Categoria de la multa
  final DateTime date;
  final DateTime createdAt; // Agregado explícitamente y hecho requerido
  final DateTime? updatedAt; 

  Fine({
    this.id,
    required this.uuid, // Ahora es requerido
    required this.affiliateUuid,
    this.relatedAttendanceUuid, // Ahora es opcional
    required this.description,
    required this.amount,
    this.amountPaid = 0.0,
    this.isPaid = false,
    required this.category, // Categoria de la multa
    required this.date,
    required this.createdAt, // Ahora es requerido
    this.updatedAt,
  });

   Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid, // Incluir en toMap
      'affiliate_uuid': affiliateUuid,
      'amount': amount,
      'description': description,
      'category': category.toString().split('.').last, // Guarda 'Varios', 'Retraso', etc.
      'date': date.toIso8601String(),
      'amount_paid': amountPaid,
      'is_paid': isPaid ? 1 : 0,
      'related_attendance_uuid': relatedAttendanceUuid, // Incluir en toMap
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Fine.fromMap(Map<String, dynamic> map) {
    return Fine(
      id: map['id'],
      uuid: map['uuid'], // Incluir en fromMap
      affiliateUuid: map['affiliate_uuid'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'],
      category: FineCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => FineCategory.Varios, // Si no hay coincidencia, asigna 'Varios' por defecto.
      ),
      date: DateTime.parse(map['date']),
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      isPaid: map['is_paid'] == 1,
      relatedAttendanceUuid: map['related_attendance_uuid'], // Incluir en fromMap
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Fine copyWith({
    int? id,
    String? uuid, // Incluir en copyWith
    String? affiliateUuid,
    double? amount,
    String? description,
    FineCategory? category,
    DateTime? date,
    double? amountPaid,
    bool? isPaid,
    String? relatedAttendanceUuid, // Incluir en copyWith
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fine(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid, // Asignar uuid
      affiliateUuid: affiliateUuid ?? this.affiliateUuid,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      amountPaid: amountPaid ?? this.amountPaid,
      isPaid: isPaid ?? this.isPaid,
      relatedAttendanceUuid: relatedAttendanceUuid ?? this.relatedAttendanceUuid, // Asignar relatedAttendanceUuid
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}