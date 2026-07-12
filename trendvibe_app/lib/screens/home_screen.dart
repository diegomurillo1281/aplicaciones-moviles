import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'posts_screen.dart';
import 'post_screen.dart';

class HomeScreen extends StatelessWidget {
  final int idUsuario;
  final String nombreUsuario;

  const HomeScreen({
    super.key,
    required this.idUsuario,
    required this.nombreUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TrendVibe"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¡Bienvenido, $nombreUsuario!",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "ID usuario: $idUsuario",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            // CREAR PUBLICACIÓN
            Card(
              elevation: 3,
              child: ListTile(
                leading: const Icon(
                  Icons.add_circle,
                  color: Colors.blue,
                ),
                title: const Text(
                  "Crear publicación",
                ),
                subtitle: const Text(
                  "Crear una nueva publicación",
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePostScreen(
                        usuarioId: idUsuario,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // VER PUBLICACIONES
            Card(
              elevation: 3,
              child: ListTile(
                leading: const Icon(
                  Icons.list,
                  color: Colors.green,
                ),
                title: const Text(
                  "Ver publicaciones",
                ),
                subtitle: const Text(
                  "Explorar contenido de TrendVibe",
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PostsScreen(),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Cerrar sesión"),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}