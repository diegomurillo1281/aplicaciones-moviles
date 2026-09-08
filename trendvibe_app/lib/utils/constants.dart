import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Constants {
  // Configuración dinámica de la URL base según la plataforma
  static String get baseUrl {
    if (kIsWeb) {
      // Entorno Web
      return "http://127.0.0.1:5000";
    } else if (Platform.isAndroid) {
      // Emulador de Android (10.0.2.2 apunta al localhost del equipo anfitrión)
      return "http://10.0.2.2:5000";
    } else {
      // iOS / Windows / macOS / Linux Desktop
      return "http://127.0.0.1:5000";
    }
  }
}