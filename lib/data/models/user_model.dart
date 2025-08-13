// Enum para los roles de usuario. Usar un enum previene errores de tipeo.
enum UserRole {
  superAdmin,
  admin,
  user,
  guest
}

class User {
  final String uuid;
  final String userName;
  final String email;
  final String passwordHash;
  final UserRole role;
  final DateTime createdAt; // Agregado explícitamente y hecho requerido
  final DateTime? updatedAt; 

  User({
    required this.uuid,
    required this.userName,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.createdAt, // Ahora es requerido
    this.updatedAt,
  });

  // Método para convertir un User a un Map (para la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'user_name': userName,
      'email': email,
      'password_hash': passwordHash,
      'role': role.toString().split('.').last, 
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Método para crear un User desde un Map (desde la base de datos)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      // Añadimos protección contra nulos para todos los campos
      uuid: map['uuid'] ?? '',
      userName: map['user_name'] ?? '',
      email: map['email'] ?? '',
      passwordHash: map['password_hash'] ?? map['password'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.guest, // Si el rol no se reconoce, se asigna 'guest'
      ),
      
      // Hacemos el parseo de fechas más seguro
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }

  User copyWith({
    String? uuid,
    String? userName,
    String? email,
    String? passwordHash,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}