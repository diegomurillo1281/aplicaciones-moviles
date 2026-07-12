class Post {
  final int? id;
  final String contenido;
  final String usuario;


  Post({
    this.id,
    required this.contenido,
    required this.usuario,
  });


  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      contenido: json['contenido'],
      usuario: json['usuario'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "contenido": contenido,
      "usuario": usuario,
    };
  }
}