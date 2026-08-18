class Comentario {
  final String usuario;
  final String texto;
  final double calificacion;
  final String fecha;

  Comentario({
    required this.usuario,
    required this.texto,
    required this.calificacion,
    required this.fecha,
  });
}

class Prenda {
  final int id;
  final String nombre;
  final double precioReferencial;
  final String tipoTela;
  final String categoria;
  final List<String> fotos;
  final List<Comentario> comentarios;

  Prenda({
    required this.id,
    required this.nombre,
    required this.precioReferencial,
    required this.tipoTela,
    required this.categoria,
    required this.fotos,
    required this.comentarios,
  });

  double get promedioCalificacion {
    if (comentarios.isEmpty) return 0.0;
    double suma = comentarios.fold(0, (prev, element) => prev + element.calificacion);
    return suma / comentarios.length;
  }
}