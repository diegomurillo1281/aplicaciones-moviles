import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrendVibe Mobile',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      debugShowCheckedModeBanner: false,
      home: const CatalogScreen(),
    );
  }
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<dynamic> _productos = [];
  List<dynamic> _productosFiltrados = [];
  bool _cargando = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _obtenerProductosDesdeFlask();
  }

  // GET: Leer productos de la Base de Datos
  Future<void> _obtenerProductosDesdeFlask() async {
    final url = Uri.parse('http://127.0.0.1:5000/api/productos');
    try {
      final respuesta = await http.get(url);
      if (respuesta.statusCode == 200) {
        setState(() {
          _productos = json.decode(respuesta.body);
          _productosFiltrados = _productos;
          _cargando = false;
        });
      } else {
        throw Exception('Error al cargar datos');
      }
    } catch (e) {
      setState(() { _cargando = false; });
      print('Error de conexión: $e');
    }
  }

  // POST: Enviar nueva prenda al backend para persistencia real
  Future<void> _registrarNuevoProducto(String nombre, double precio, int categoriaId) async {
    final url = Uri.parse('http://127.0.0.1:5000/api/productos');
    try {
      final respuesta = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "nombre": nombre,
          "precio": precio,
          "categoria_id": categoriaId,
        }),
      );

      if (respuesta.statusCode == 201) {
        _obtenerProductosDesdeFlask(); // Recargar lista automáticamente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Prenda guardada en la Base de Datos!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error al guardar: $e');
    }
  }

  // OPTIMIZACIÓN: Filtrado local inmediato para ahorro de cómputo
  void _filtrarProductos(String consulta) {
    setState(() {
      _productosFiltrados = _productos.where((p) {
        final nombre = p['nombre'].toString().toLowerCase();
        final categoria = p['categoria'].toString().toLowerCase();
        final input = consulta.toLowerCase();
        return nombre.contains(input) || categoria.contains(input);
      }).toList();
    });
  }

  // Modal interactivo para el formulario CRUD de creación
  void _mostrarFormularioIngreso() {
    final nombreCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    int categoriaSeleccionada = 1; // 1: Streetwear, 2: Hoodies, 3: Pantalones

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('NUEVA PRENDA - TRENDVIBE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 15),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del Artículo', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: precioCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio (\$)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: categoriaSeleccionada,
              items: const [
                DropdownMenuItem(value: 1, child: Text('Streetwear')),
                DropdownMenuItem(value: 2, child: Text('Hoodies')),
                DropdownMenuItem(value: 3, child: Text('Pantalones')),
              ],
              onChanged: (val) { if (val != null) categoriaSeleccionada = val; },
              decoration: const InputDecoration(labelText: 'Categoría Estilo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
              onPressed: () {
                if (nombreCtrl.text.isNotEmpty && precioCtrl.text.isNotEmpty) {
                  _registrarNuevoProducto(nombreCtrl.text, double.parse(precioCtrl.text), categoriaSeleccionada);
                  Navigator.pop(context);
                }
              },
              child: const Text('GUARDAR EN BASE DE DATOS'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TRENDVIBE • INTERACTIVO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de Optimización del Rendimiento (Filtros en red)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarProductos,
              decoration: InputDecoration(
                hintText: 'Buscar por prenda o categoría...',
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _productosFiltrados.isEmpty
                    ? const Center(child: Text('No se encontraron artículos.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final producto = _productosFiltrados[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: const Icon(Icons.checkroom, color: Colors.black),
                              title: Text(producto['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Estilo: ${producto['categoria']}'),
                              trailing: Text('\$${producto['precio'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      // Botón de creación interactiva (CRUD - POST)
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioIngreso,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}