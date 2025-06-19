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

  User({
    required this.uuid,
    required this.userName,
    required this.email,
    required this.passwordHash,
    required this.role,
  });

  // Método para convertir un User a un Map (para la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'user_name': userName,
      'email': email,
      'password_hash': passwordHash,
      'role': role.toString(), // Guardamos el rol como String
    };
  }

  // Método para crear un User desde un Map (desde la base de datos)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uuid: map['uuid'],
      userName: map['user_name'],
      email: map['email'],
      passwordHash: map['password_hash'],
      // Convertimos el String de vuelta a un enum UserRole
      role: UserRole.values.firstWhere((e) => e.toString() == map['role']),
    );
  }
}
