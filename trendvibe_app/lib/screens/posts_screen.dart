import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'edit_post_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> publicaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPublicaciones();
  }

  Future<void> _cargarPublicaciones() async {
    try {
      final data = await _apiService.obtenerPublicaciones();

      setState(() {
        publicaciones = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminar(int id) async {
    try {
      await _apiService.eliminarPublicacion(id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Publicación eliminada"),
          backgroundColor: Colors.green,
        ),
      );

      _cargarPublicaciones();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Publicaciones"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : publicaciones.isEmpty
              ? const Center(
                  child: Text(
                    "No existen publicaciones",
                  ),
                )
              : ListView.builder(
                  itemCount: publicaciones.length,
                  itemBuilder: (context, index) {
                    final post = publicaciones[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    post["titulo"],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // EDITAR
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    final resultado =
                                        await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditPostScreen(
                                          id: post["id"],
                                          titulo:
                                              post["titulo"],
                                          contenido:
                                              post["contenido"],
                                        ),
                                      ),
                                    );

                                    if (resultado == true) {
                                      _cargarPublicaciones();
                                    }
                                  },
                                ),

                                // ELIMINAR
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirmar =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (context) =>
                                          AlertDialog(
                                        title: const Text(
                                          "Eliminar publicación",
                                        ),
                                        content: const Text(
                                          "¿Desea eliminar esta publicación?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                context,
                                                false,
                                              );
                                            },
                                            child: const Text(
                                              "Cancelar",
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                context,
                                                true,
                                              );
                                            },
                                            child: const Text(
                                              "Eliminar",
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmar == true) {
                                      _eliminar(post["id"]);
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Text(
                              post["contenido"],
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Autor: ${post["autor"]}",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}