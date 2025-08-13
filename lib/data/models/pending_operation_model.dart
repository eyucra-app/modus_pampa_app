import 'dart:convert';

// Enum para los tipos de operaciones
enum OperationType {
  CREATE,
  UPDATE,
  DELETE,
}

class PendingOperation {
  final int? id;
  final OperationType operationType;
  final String tableName;
  final Map<String, dynamic> data; // Los datos a sincronizar, como un mapa
  final DateTime createdAt;

  PendingOperation({
    this.id,
    required this.operationType,
    required this.tableName,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation_type': operationType.name, // Guarda 'CREATE', 'UPDATE', etc.
      'table_name': tableName,
      'data': jsonEncode(data), // Convierte el mapa a un string JSON para guardarlo
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingOperation.fromMap(Map<String, dynamic> map) {
    return PendingOperation(
      id: map['id'],
      operationType: OperationType.values.firstWhere((e) => e.name == map['operation_type']),
      tableName: map['table_name'],
      data: jsonDecode(map['data']), // Convierte el string JSON de vuelta a un mapa
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
