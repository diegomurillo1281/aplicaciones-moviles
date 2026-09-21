import 'dart:io';
import 'package:flutter/foundation.dart'; // Importante para kIsWeb
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../models/prenda_model.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  List<PrendaModel> _prendas = [];
  bool _isLoading = true;
  String? _rutaImagenSeleccionada;

  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarPrendas();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _cargarPrendas() async {
    setState(() => _isLoading = true);
    try {
      final prendas = await DBService.db.obtenerPrendas();
      setState(() {
        _prendas = prendas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarSnackBar('Error al cargar el inventario: $e');
    }
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _rutaImagenSeleccionada = image.path;
        });
      }
    } catch (e) {
      _mostrarSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _guardarPrenda() async {
    if (_nombreController.text.trim().isEmpty ||
        _precioController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty) {
      _mostrarSnackBar('Por favor completa todos los campos requeridos');
      return;
    }

    final nuevaPrenda = PrendaModel(
      nombre: _nombreController.text.trim(),
      precio: double.tryParse(_precioController.text.trim()) ?? 0.0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
      imagenUrl: _rutaImagenSeleccionada,
    );

    try {
      await DBService.db.insertarPrenda(nuevaPrenda);
      _limpiarFormulario();
      Navigator.of(context).pop();
      _cargarPrendas();
      _mostrarSnackBar('Prenda guardada en SQLite');
    } catch (e) {
      _mostrarSnackBar('Error al registrar prenda: $e');
    }
  }

  Future<void> _eliminarPrenda(int id) async {
    try {
      await DBService.db.eliminarPrenda(id);
      _cargarPrendas();
      _mostrarSnackBar('Prenda eliminada del inventario');
    } catch (e) {
      _mostrarSnackBar('Error al eliminar prenda: $e');
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _precioController.clear();
    _stockController.clear();
    _rutaImagenSeleccionada = null;
  }

  void _mostrarSnackBar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 3)),
    );
  }

  void _abrirModalFormulario() {
    _limpiarFormulario();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nueva Prenda - TrendVibe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de Prenda',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _precioController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Precio (\$)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stock',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _seleccionarImagen(ImageSource.camera);
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cámara'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _seleccionarImagen(ImageSource.gallery);
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_rutaImagenSeleccionada != null && _rutaImagenSeleccionada!.isNotEmpty)
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                _rutaImagenSeleccionada!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 40),
                              )
                            : Image.file(
                                File(_rutaImagenSeleccionada!),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _guardarPrenda,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: const Text(
                      'Guardar en BD',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _construirAvatarImagen(String? ruta) {
    if (ruta != null && ruta.isNotEmpty) {
      if (kIsWeb) {
        return CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(ruta),
        );
      } else {
        final file = File(ruta);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: 28,
            backgroundImage: FileImage(file),
          );
        }
      }
    }
    return const CircleAvatar(
      radius: 28,
      backgroundColor: Colors.deepPurple,
      child: Icon(Icons.checkroom, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario TrendVibe'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPrendas,
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<dynamic>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              bool hayConexion = false;

              if (snapshot.hasData) {
                final data = snapshot.data;
                if (data is List<ConnectivityResult>) {
                  hayConexion = data.any((result) => result != ConnectivityResult.none);
                } else if (data is ConnectivityResult) {
                  hayConexion = data != ConnectivityResult.none;
                }
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: hayConexion ? Colors.green[700] : Colors.orange[800],
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hayConexion ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hayConexion ? 'Modo Online (Sincronizado)' : 'Modo Offline (Base Local)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _prendas.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay prendas registradas.\nUsa el botón + para agregar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarPrendas,
                        child: ListView.builder(
                          itemCount: _prendas.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final prenda = _prendas[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: ListTile(
                                leading: _construirAvatarImagen(prenda.imagenUrl),
                                title: Text(
                                  prenda.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  'Precio: \$${prenda.precio.toStringAsFixed(2)} | Stock: ${prenda.stock} uds.',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () {
                                    if (prenda.id != null) {
                                      _eliminarPrenda(prenda.id!);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalFormulario,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Prenda', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}