import 'package:flutter/material.dart';

import '../services/api_service.dart';

class CreatePostScreen extends StatefulWidget {
  final int usuarioId;

  const CreatePostScreen({
    super.key,
    required this.usuarioId,
  });

  @override
  State<CreatePostScreen> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState
    extends State<CreatePostScreen> {
  final ApiService api = ApiService();

  final tituloController = TextEditingController();
  final contenidoController = TextEditingController();

  bool cargando = false;

  Future<void> guardar() async {
    if (tituloController.text.isEmpty ||
        contenidoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Complete todos los campos",
          ),
        ),
      );

      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      await api.crearPublicacion(
        widget.usuarioId,
        tituloController.text,
        contenidoController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Publicación creada correctamente",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nueva publicación",
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: "Título",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: contenidoController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Contenido",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    cargando ? null : guardar,
                child: cargando
                    ? const CircularProgressIndicator()
                    : const Text(
                        "Guardar publicación",
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    tituloController.dispose();
    contenidoController.dispose();
    super.dispose();
  }
}