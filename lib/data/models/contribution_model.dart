// representa un aporte general, como una cuota mensual o una recaudación especial.

class Contribution {
  final String uuid; // UUID para consistencia con backend
  final String name;
  final String? description;
  final DateTime date;
  final double defaultAmount; // Monto por defecto del aporte
  final bool isGeneral; // Si es true, se aplica a todos por defecto
  final DateTime createdAt; // Agregado explícitamente y hecho requerido
  final DateTime? updatedAt; 

  Contribution({
    required this.uuid, // Ahora es requerido
    required this.name,
    this.description,
    required this.date,
    required this.defaultAmount,
    this.isGeneral = true,
    required this.createdAt, // Ahora es requerido
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid, // Incluir en toMap
      'name': name,
      'description': description ?? '',
      'date': date.toIso8601String(),
      'default_amount': defaultAmount, // Usar default_amount
      'is_general': isGeneral ? 1 : 0, // MODIFICADO: Enviar como booleano directamente
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Contribution.fromMap(Map<String, dynamic> map) {
    return Contribution(
      uuid: map['uuid'] as String? ?? '', // Manejar uuid que puede ser null
      name: map['name'] as String? ?? '', // Manejar name que puede ser null
      description: map['description'] as String?, // description es nullable, no necesita ?? '' aquí
      date: (map['date'] != null && map['date'].isNotEmpty) // Parsear de forma segura
          ? DateTime.parse(map['date'])
          : DateTime.now(), // Fallback seguro
      defaultAmount: (map['default_amount'] as num?)?.toDouble() ?? 0.0, // Usar default_amount
      isGeneral: map['is_general'] == 1, // Mantener para fromMap (compatibilidad con int si viene así)
      createdAt: (map['created_at'] != null && map['created_at'].isNotEmpty) // Parsear de forma segura
          ? DateTime.parse(map['created_at'])
          : DateTime.now(), // Fallback seguro
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Contribution copyWith({
    String? uuid, // Incluir en copyWith
    String? name,
    String? description,
    DateTime? date,
    double? defaultAmount,
    bool? isGeneral,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contribution(
      uuid: uuid ?? this.uuid, // Asignar uuid
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      isGeneral: isGeneral ?? this.isGeneral,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Representa la relación específica entre un afiliado y un aporte.
// Contiene el monto específico a pagar por ese afiliado y cuánto ha pagado.
class ContributionAffiliateLink {
  final String uuid; // UUID para el enlace individual (si el backend lo usa para estos)
  final String contributionUuid; // UUID de la contribución del backend
  final String affiliateUuid; // UUID del afiliado
  final double amountToPay;
  final double amountPaid;
  final bool isPaid;
  final DateTime createdAt; // Agregado explícitamente y hecho requerido
  final DateTime? updatedAt; 

  ContributionAffiliateLink({
    required this.uuid, // Ahora es requerido
    required this.contributionUuid, // Ahora es requerido
    required this.affiliateUuid,
    required this.amountToPay,
    this.amountPaid = 0.0,
    this.isPaid = false,
    required this.createdAt, // Ahora es requerido
    this.updatedAt, 
  });

   Map<String, dynamic> toMap() {
    return {
      'uuid': uuid, // Incluir en toMap
      'contribution_uuid': contributionUuid, // Incluir en toMap
      'affiliate_uuid': affiliateUuid,
      'amount_to_pay': amountToPay,
      'amount_paid': amountPaid,
      'is_paid': isPaid ? 1 : 0, // MODIFICADO: Enviar como booleano directamente
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ContributionAffiliateLink.fromMap(Map<String, dynamic> map) {

    final isPaidValue = map['is_paid'];
    final bool isPaid;

    if (isPaidValue is bool) {
      isPaid = isPaidValue;
    } else if (isPaidValue is int) {
      isPaid = isPaidValue == 1;
    } else {
      isPaid = false; // Valor por defecto
    }

    return ContributionAffiliateLink(
      uuid: map['uuid'] as String? ?? '', // Manejar uuid que puede ser null
      contributionUuid: map['contribution_uuid'] as String? ?? '', // Manejar contribution_uuid que puede ser null
      affiliateUuid: map['affiliate_uuid'] as String? ?? '', // Manejar affiliate_uuid que puede ser null
      amountToPay: (map['amount_to_pay'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      isPaid: isPaid, // Mantener para fromMap (compatibilidad con int si viene así)
      createdAt: (map['created_at'] != null && map['created_at'].isNotEmpty) // Parsear de forma segura
          ? DateTime.parse(map['created_at'])
          : DateTime.now(), // Fallback seguro
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  ContributionAffiliateLink copyWith({
    String? uuid, // Incluir en copyWith
    String? contributionUuid, // Incluir en copyWith
    String? affiliateUuid,
    double? amountToPay,
    double? amountPaid,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContributionAffiliateLink(
      uuid: uuid ?? this.uuid, // Asignar uuid
      contributionUuid: contributionUuid ?? this.contributionUuid, // Asignar contributionUuid
      affiliateUuid: affiliateUuid ?? this.affiliateUuid,
      amountToPay: amountToPay ?? this.amountToPay,
      amountPaid: amountPaid ?? this.amountPaid,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}