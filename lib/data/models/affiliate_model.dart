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
  final DateTime createdAt; // Agregado explícitamente y hecho requerido
  final DateTime? updatedAt; 

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
    required this.createdAt, // Ahora es requerido
    this.updatedAt,
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
      'created_at': createdAt.toIso8601String(), // Convertir DateTime a String ISO 8601
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Affiliate.fromMap(Map<String, dynamic> map) {
    
    dynamic currentTags = map['tags'];

    // Bucle de limpieza para decodificar tags anidados
    while (currentTags is String && currentTags.startsWith('[') && currentTags.length > 2) {
      try {
        currentTags = jsonDecode(currentTags);
      } catch (e) {
        break; // Romper si no se puede decodificar más
      }
    }
    
    // Asegurar que el resultado final sea una lista de strings
    final List<String> tagsList = currentTags is List
        ? List<String>.from(currentTags.map((e) => e.toString()))
        : [];

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
      tags: tagsList,
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalDebt: (map['total_debt'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at']), // Convertir String a DateTime
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, 
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