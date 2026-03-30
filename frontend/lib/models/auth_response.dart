class AuthResponse {
  final String access;
  final String refresh;
  final User user;

  AuthResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        access: json["access"],
        refresh: json["refresh"],
        user: User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "access": access,
        "refresh": refresh,
        "user": user.toJson(),
      };
}

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String rol;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.rol,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        username: json["username"],
        email: json["email"] ?? "",
        firstName: json["first_name"] ?? "",
        lastName: json["last_name"] ?? "",
        // Aceptar "rol" o "role"
        rol: json["rol"] ?? json["role"] ?? "operario",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "first_name": firstName,
        "last_name": lastName,
        "role": rol,
      };

  bool get isAdmin => rol.toLowerCase() == "admin";
  bool get isOperario => rol.toLowerCase() == "operario";
}
