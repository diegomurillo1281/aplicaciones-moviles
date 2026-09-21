class PrendaModel {
  final int? id;
  final String nombre;
  final double precio;
  final int stock;
  final String? imagenUrl;

  PrendaModel({
    this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.imagenUrl,
  });

  // Convertir un mapa (SQLite / API REST) a un objeto PrendaModel
  factory PrendaModel.fromMap(Map<String, dynamic> json) => PrendaModel(
        id: json['id'] as int?,
        nombre: json['nombre'] as String? ?? '',
        precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
        stock: json['stock'] as int? ?? 0,
        imagenUrl: json['imagen_url'] as String?,
      );

  // Convertir el objeto a Map para inserción en SQLite o envío a Flask
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'imagen_url': imagenUrl,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}