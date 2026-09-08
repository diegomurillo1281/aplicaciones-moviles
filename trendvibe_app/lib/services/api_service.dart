import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'secure_storage_service.dart';

class ApiService {
  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Constants.baseUrl, // ej: http://10.0.2.2:5000 en emulador Android
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // Inyecta el token JWT guardado
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        // Manejo y renovación automática si el token expira (HTTP 401)
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            bool isRetry = error.requestOptions.extra['is_retry'] ?? false;
            
            // Marca previa para evitar bucles infinitos
            if (!isRetry) {
              error.requestOptions.extra['is_retry'] = true;
              bool refreshed = await _refreshToken();

              if (refreshed) {
                final newToken = await _storage.getToken();
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        await _storage.saveToken(response.data['access_token']);
        return true;
      }
    } catch (_) {
      await _storage.clearAll();
    }
    return false;
  }

  // --- MÉTODOS DE LA API CONSERVANDO TU ESTRUCTURA ORIGINAL ---

  Future<void> registrar(String nombreUsuario, String correo, String contrasena) async {
    try {
      await _dio.post('/api/auth/register', data: {
        "nombre_usuario": nombreUsuario,
        "correo": correo,
        "contrasena": contrasena,
      });
    } on DioException catch (e) {
      throw Exception(_parseError(e, "Error en registro"));
    }
  }

  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        "correo": correo,
        "contrasena": contrasena,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_parseError(e, "Error de login"));
    }
  }

  Future<List<dynamic>> obtenerPublicaciones() async {
    try {
      final response = await _dio.get('/api/publicaciones');
      return response.data["datos"] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(_parseError(e, "Error al cargar publicaciones"));
    }
  }

  Future<void> crearPublicacion(int usuarioId, String titulo, String contenido) async {
    try {
      await _dio.post('/api/publicaciones', data: {
        "usuario_id": usuarioId,
        "titulo": titulo,
        "contenido": contenido,
      });
    } on DioException catch (e) {
      throw Exception(_parseError(e, "Error creando publicación"));
    }
  }

  Future<void> actualizarPublicacion(int id, String titulo, String contenido) async {
    try {
      await _dio.put('/api/publicaciones/$id', data: {
        "titulo": titulo,
        "contenido": contenido,
      });
    } on DioException catch (e) {
      throw Exception(_parseError(e, "Error actualizando publicación"));
    }
  }

  Future<void> eliminarPublicacion(int id) async {
    try {
      await _dio.delete('/api/publicaciones/$id');
    } on DioException catch (e) {
      throw Exception(_parseError(e, "Error eliminando publicación"));
    }
  }

  // Captura y formateo de errores (HTTP 422 y errores generales)
  String _parseError(DioException e, String defaultMessage) {
    if (e.response?.statusCode == 422) {
      final errors = e.response?.data['errors'];
      if (errors != null && errors is Map) {
        return errors.values.join(', ');
      }
    }
    return e.response?.data["error"] ?? e.response?.data["message"] ?? defaultMessage;
  }
}