import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Instanciamos la caja fuerte del teléfono
  final _storage = const FlutterSecureStorage();
  static const _keyToken = 'auth_token';

  // 1. Guardar el token de forma segura
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  // 2. Leer el token cuando necesitemos hacer peticiones al servidor
  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // 3. Borrar el token cuando el usuario presione "Cerrar Sesión"
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}