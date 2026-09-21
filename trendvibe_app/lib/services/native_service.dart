import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class NativeService {
  final ImagePicker _picker = ImagePicker();

  // Permiso y captura de cámara
  Future<String?> tomarFoto(BuildContext context) async {
    try {
      PermissionStatus status = await Permission.camera.status;

      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      if (status.isGranted) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80, // Optimiza el tamaño de la imagen guardada
        );
        return photo?.path;
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) _abrirAjustes(context, "cámara");
      }
    } catch (e) {
      debugPrint("Error al capturar imagen: $e");
    }
    return null; // Degradación: continúa sin imagen
  }

  // Permiso y captura de GPS
  Future<Map<String, double>?> obtenerUbicacion(BuildContext context) async {
    try {
      // 1. Verifica si el GPS del dispositivo está encendido a nivel del sistema
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, activa el GPS del dispositivo.')),
          );
        }
        return null;
      }

      // 2. Comprueba el permiso específico de la app
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 10), // Evita bloqueos indefinidos
        );
        return {'lat': pos.latitude, 'lng': pos.longitude};
      } else if (permission == LocationPermission.deniedForever) {
        if (context.mounted) _abrirAjustes(context, "ubicación");
      }
    } catch (e) {
      debugPrint("Error al obtener ubicación: $e");
    }
    return null; // Degradación: continúa sin coordenadas GPS
  }

  // Cuadro de diálogo para denegación permanente
  void _abrirAjustes(BuildContext context, String funcion) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso requerido'),
        content: Text('El acceso a la $funcion está desactivado. Para usar esta opción, habilítalo en los ajustes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings(); // Abre la configuración de Android/iOS
            },
            child: const Text('Ir a Ajustes'),
          ),
        ],
      ),
    );
  }
}