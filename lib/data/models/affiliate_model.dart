import 'dart:convert';
// Importar para @override

class Affiliate {
  final String uuid;
  final String id; // ID único del afiliado (ej: 'AP-001')
  final String firstName;
  final String lastName;
  final String ci; // Carnet de Identidad
  final String? phone;
  final String originalAffiliateName;
  final String currentAffiliateName;
  final String? profilePhotoUrl;
  final String? credentialPhotoUrl;
  final List<String> tags;
  final double totalPaid;
  final double totalDebt;

  Affiliate({
    required this.uuid,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.ci,
    this.phone,
    this.originalAffiliateName = '-',
    this.currentAffiliateName = '-',
    this.profilePhotoUrl,
    this.credentialPhotoUrl,
    this.tags = const [],
    this.totalPaid = 0.0,
    this.totalDebt = 0.0,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'ci': ci,
      'phone': phone,
      'original_affiliate_name': originalAffiliateName,
      'current_affiliate_name': currentAffiliateName,
      'profile_photo_url': profilePhotoUrl,
      'credential_photo_url': credentialPhotoUrl,
      'tags': jsonEncode(tags),
      'total_paid': totalPaid,
      'total_debt': totalDebt,
    };
  }

  factory Affiliate.fromMap(Map<String, dynamic> map) {
    return Affiliate(
      uuid: map['uuid'],
      id: map['id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      ci: map['ci'],
      phone: map['phone'],
      originalAffiliateName: map['original_affiliate_name'],
      currentAffiliateName: map['current_affiliate_name'],
      profilePhotoUrl: map['profile_photo_url'],
      credentialPhotoUrl: map['credential_photo_url'],
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      totalPaid: map['total_paid'] ?? 0.0,
      totalDebt: map['total_debt'] ?? 0.0,
    );
  }

  Affiliate copyWith({
    String? uuid,
    String? id,
    String? firstName,
    String? lastName,
    String? ci,
    String? phone,
    String? originalAffiliateName,
    String? currentAffiliateName,
    String? profilePhotoUrl,
    String? credentialPhotoUrl,
    List<String>? tags,
    double? totalPaid,
    double? totalDebt,
  }) {
    return Affiliate(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      ci: ci ?? this.ci,
      phone: phone ?? this.phone,
      originalAffiliateName: originalAffiliateName ?? this.originalAffiliateName,
      currentAffiliateName: currentAffiliateName ?? this.currentAffiliateName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      credentialPhotoUrl: credentialPhotoUrl ?? this.credentialPhotoUrl,
      tags: tags ?? this.tags,
      totalPaid: totalPaid ?? this.totalPaid,
      totalDebt: totalDebt ?? this.totalDebt,
    );
  }


  // Sobrescribimos el operador de igualdad para que Flutter pueda
  // comparar afiliados basándose en su contenido (el uuid) y no en la instancia de memoria.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Affiliate &&
      other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;

}
