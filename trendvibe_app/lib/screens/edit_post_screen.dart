import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditPostScreen extends StatefulWidget {

  final int id;
  final String titulo;
  final String contenido;

  const EditPostScreen({
    super.key,
    required this.id,
    required this.titulo,
    required this.contenido,
  });

  @override
  State<EditPostScreen> createState() =>
      _EditPostScreenState();
}

class _EditPostScreenState
    extends State<EditPostScreen> {

  final ApiService api = ApiService();

  late TextEditingController tituloController;
  late TextEditingController contenidoController;

  bool cargando = false;

  @override
  void initState() {
    super.initState();

    tituloController =
        TextEditingController(text: widget.titulo);

    contenidoController =
        TextEditingController(
            text: widget.contenido);
  }

  Future<void> actualizar() async {

    setState(() {
      cargando = true;
    });

    try {

      await api.actualizarPublicacion(
        widget.id,
        tituloController.text,
        contenidoController.text,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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
        title: const Text("Editar publicación"),
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
                    cargando ? null : actualizar,
                child: const Text(
                  "Guardar cambios",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}