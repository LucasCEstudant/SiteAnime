// DTOs para o CRUD de usuários admin — Etapa 13.

/// Resposta do GET /api/users e GET /api/users/{id}.
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAtUtc,
  });

  final int id;
  final String email;
  final String role;
  final DateTime createdAtUtc;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }
}

/// Body do POST /api/users.
class UserCreateDto {
  const UserCreateDto({
    required this.email,
    required this.password,
    required this.role,
  });

  final String email;
  final String password;
  final String role;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'role': role,
      };
}

/// Body do PUT /api/users/{id}.
/// Todos os campos são opcionais — ao menos um deve estar preenchido.
class UserUpdateDto {
  const UserUpdateDto({
    this.email,
    this.password,
    this.role,
  });

  final String? email;
  final String? password;
  final String? role;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (email != null) map['email'] = email;
    if (password != null) map['password'] = password;
    if (role != null) map['role'] = role;
    return map;
  }
}
