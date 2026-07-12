class User {
  final int? id;
  final String nombre;
  final String email;

  User({
    this.id,
    required this.nombre,
    required this.email,
  });


  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre,
      "email": email,
    };
  }
}