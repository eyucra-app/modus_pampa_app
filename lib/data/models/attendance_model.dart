// Enum para los estados de una lista de asistencia
enum AttendanceListStatus {
  PREPARADA, // Recién creada, lista para empezar a registrar.
  INICIADA,  // El registro ha comenzado.
  TERMINADA, // El registro principal ha terminado, pero se aceptan registros con retraso.
  FINALIZADA // La lista está cerrada, ya no se aceptan registros.
}

// Representa una lista de asistencia para un evento o reunión.
class AttendanceList {
  final int? id;
  final String name;
  final DateTime createdAt;
  final AttendanceListStatus status;

  AttendanceList({
    this.id,
    required this.name,
    required this.createdAt,
    this.status = AttendanceListStatus.PREPARADA,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'status': status.toString().split('.').last, // Guarda 'PREPARADA', etc.
    };
  }

  factory AttendanceList.fromMap(Map<String, dynamic> map) {
    return AttendanceList(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      status: AttendanceListStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
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
  final int? id;
  final int listId;
  final String affiliateUuid;
  final DateTime registeredAt;
  final AttendanceRecordStatus status;

  AttendanceRecord({
    this.id,
    required this.listId,
    required this.affiliateUuid,
    required this.registeredAt,
    required this.status,
  });

   Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_id': listId,
      'affiliate_uuid': affiliateUuid,
      'registered_at': registeredAt.toIso8601String(),
      'status': status.toString().split('.').last, // Guarda 'PRESENTE', etc.
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      listId: map['list_id'],
      affiliateUuid: map['affiliate_uuid'],
      registeredAt: DateTime.parse(map['registered_at']),
      status: AttendanceRecordStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
    );
  }
}
