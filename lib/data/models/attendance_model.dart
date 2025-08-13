// Enum para los estados de una lista de asistencia
enum AttendanceListStatus {
  PREPARADA, // Recién creada, lista para empezar a registrar.
  INICIADA,  // El registro ha comenzado.
  TERMINADA, // El registro principal ha terminado, pero se aceptan registros con retraso.
  FINALIZADA // La lista está cerrada, ya no se aceptan registros.
}

// Representa una lista de asistencia para un evento o reunión.
class AttendanceList {
  final String uuid; // UUID para consistencia con backend
  final String name;
  final AttendanceListStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceList({
    required this.uuid, // Ahora es requerido
    required this.name,
    this.status = AttendanceListStatus.PREPARADA,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid, // Incluir en toMap
      'name': name,
      'status': status.toString().split('.').last, // Guarda 'PREPARADA', etc.
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(), 
    };
  }

  factory AttendanceList.fromMap(Map<String, dynamic> map) {
    return AttendanceList(
      uuid: map['uuid'], // Incluir en fromMap
      name: map['name'],
      status: AttendanceListStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
  
  AttendanceList copyWith({
    String? uuid, // Incluir en copyWith
    String? name,
    AttendanceListStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceList(
      uuid: uuid ?? this.uuid, // Asignar uuid
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Enum para el estado de un afiliado en una lista de asistencia.
enum AttendanceRecordStatus {
  PRESENTE,
  RETRASO,
  FALTA, // Este estado se asignará a los no registrados al finalizar la lista.
}

// Representa el registro de un afiliado en una lista de asistencia específica.
class AttendanceRecord {
  final String uuid; // UUID para consistencia con backend (representa el ID del registro en backend)
  final String listUuid; // UUID de la lista de asistencia del backend
  final String affiliateUuid; // UUID del afiliado
  final DateTime registeredAt;
  final AttendanceRecordStatus status;
  final DateTime createdAt; // Agregado explícitamente y hecho requerido
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.uuid, // Ahora es requerido
    required this.listUuid, // Ahora es requerido
    required this.affiliateUuid,
    required this.registeredAt,
    required this.status,
    required this.createdAt, // Ahora es requerido
    this.updatedAt, 
  });

   Map<String, dynamic> toMap() {
    return {
      'uuid': uuid, // Incluir en toMap
      'list_uuid': listUuid, // Incluir en toMap
      'affiliate_uuid': affiliateUuid,
      'registered_at': registeredAt.toIso8601String(),
      'status': status.toString().split('.').last, // Guarda 'PRESENTE', etc.
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      uuid: map['uuid'], // Incluir en fromMap
      listUuid: map['list_uuid'], // Incluir en fromMap
      affiliateUuid: map['affiliate_uuid'],
      registeredAt: DateTime.parse(map['registered_at']),
      status: AttendanceRecordStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  AttendanceRecord copyWith({
    String? uuid, // Incluir en copyWith
    String? listUuid, // Incluir en copyWith
    String? affiliateUuid,
    DateTime? registeredAt,
    AttendanceRecordStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      uuid: uuid ?? this.uuid, // Asignar uuid
      listUuid: listUuid ?? this.listUuid, // Asignar listUuid
      affiliateUuid: affiliateUuid ?? this.affiliateUuid,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}