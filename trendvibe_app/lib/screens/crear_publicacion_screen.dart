import 'package:flutter/material.dart';
import '../models/prenda_model.dart';

class CrearPublicacionScreen extends StatefulWidget {
  const CrearPublicacionScreen({Key? key}) : super(key: key);

  @override
  State<CrearPublicacionScreen> createState() => _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _telaController = TextEditingController();
  final _fotoUrlController = TextEditingController();

  String _categoriaSeleccionada = 'Camisetas';
  final List<String> _categorias = ['Camisetas', 'Jeans', 'Chaquetas', 'Calzado', 'Accesorios'];
  final List<String> _listaFotos = [];

  void _agregarFoto() {
    final url = _fotoUrlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _listaFotos.add(url);
        _fotoUrlController.clear();
      });
    }
  }

  void _guardarPublicacion() {
    if (_formKey.currentState!.validate()) {
      if (_listaFotos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor agrega al menos una imagen de la prenda'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final nuevaPrenda = Prenda(
        id: DateTime.now().millisecondsSinceEpoch,
        nombre: _nombreController.text.trim(),
        precioReferencial: double.parse(_precioController.text.trim()),
        tipoTela: _telaController.text.trim(),
        categoria: _categoriaSeleccionada,
        fotos: List.from(_listaFotos),
        comentarios: [],
      );

      // Retornamos la nueva prenda creada a la pantalla anterior
      Navigator.pop(context, nuevaPrenda);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
        title: const Text(
          'Nueva Publicación',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles de la Prenda',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Nombre de la prenda
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre o Título de la Prenda',
                          prefixIcon: const Icon(Icons.checkroom),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingresa un nombre' : null,
                      ),
                      const SizedBox(height: 16),

                      // Categoría y Precio
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _categoriaSeleccionada,
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _categorias
                                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _categoriaSeleccionada = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _precioController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Precio Referencial (\$)',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Ingresa precio';
                                if (double.tryParse(value) == null) return 'Número inválido';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tipo de Tela / Material
                      TextFormField(
                        controller: _telaController,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Tela / Material (ej. 100% Algodón, Denim 12oz)',
                          prefixIcon: const Icon(Icons.texture),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Especifica el material' : null,
                      ),
                      const SizedBox(height: 24),

                      // Sección de Fotos
                      const Text(
                        'Fotos de la Prenda (URL de Imagen)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _fotoUrlController,
                              decoration: InputDecoration(
                                hintText: 'https://ejemplo.com/imagen.jpg',
                                prefixIcon: const Icon(Icons.link),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B5998),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _agregarFoto,
                            icon: const Icon(Icons.add_a_photo, color: Colors.white, size: 20),
                            label: const Text('Añadir', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Previsualización de imágenes añadidas
                      if (_listaFotos.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _listaFotos.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: NetworkImage(_listaFotos[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _listaFotos.removeAt(index);
                                        });
                                      },
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Botón Publicar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF20C997),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _guardarPublicacion,
                          icon: const Icon(Icons.publish, color: Colors.white),
                          label: const Text(
                            'Publicar Prenda',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}