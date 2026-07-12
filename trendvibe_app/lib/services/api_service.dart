import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ApiService {
  Future<void> registrar(
    String nombreUsuario,
    String correo,
    String contrasena,
  ) async {
    final response = await http.post(
      Uri.parse(
        "${Constants.baseUrl}/api/auth/register",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "nombre_usuario": nombreUsuario,
        "correo": correo,
        "contrasena": contrasena,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data["error"] ?? "Error en registro",
      );
    }
  }

  Future<Map<String, dynamic>> login(
    String correo,
    String contrasena,
  ) async {
    final response = await http.post(
      Uri.parse(
        "${Constants.baseUrl}/api/auth/login",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "correo": correo,
        "contrasena": contrasena,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data["error"] ?? "Error de login",
    );
  }

  Future<List<dynamic>> obtenerPublicaciones() async {
    final response = await http.get(
      Uri.parse(
        "${Constants.baseUrl}/api/publicaciones",
      ),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["datos"];
    }

    throw Exception(
      "Error al cargar publicaciones",
    );
  }

  Future<void> crearPublicacion(
    int usuarioId,
    String titulo,
    String contenido,
  ) async {
    final response = await http.post(
      Uri.parse(
        "${Constants.baseUrl}/api/publicaciones",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "usuario_id": usuarioId,
        "titulo": titulo,
        "contenido": contenido,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data["error"] ??
            "Error creando publicación",
      );
    }
  }

  Future<void> actualizarPublicacion(
    int id,
    String titulo,
    String contenido,
  ) async {
    final response = await http.put(
      Uri.parse(
        "${Constants.baseUrl}/api/publicaciones/$id",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "titulo": titulo,
        "contenido": contenido,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data["error"] ??
            "Error actualizando publicación",
      );
    }
  }

  Future<void> eliminarPublicacion(
    int id,
  ) async {
    final response = await http.delete(
      Uri.parse(
        "${Constants.baseUrl}/api/publicaciones/$id",
      ),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data["error"] ??
            "Error eliminando publicación",
      );
    }
  }
}