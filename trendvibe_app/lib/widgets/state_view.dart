import 'package:flutter/material.dart';
import '../widgets/state_view.dart'; // Importa el widget

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  ViewState _state = ViewState.loading;
  List<dynamic> _products = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _state = ViewState.loading);

    try {
      // Petición a tu API backend app.py
      // Si la lista está vacía:
      // setState(() => _state = ViewState.empty);
      
      // Si la carga es exitosa:
      setState(() => _state = ViewState.success);
    } catch (e) {
      setState(() {
        _state = ViewState.error;
        _errorMessage = 'No se pudo conectar con el servidor Flask';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo TrendVibe')),
      body: StateView(
        state: _state,
        message: _errorMessage,
        onRetry: _fetchProducts, // Función al presionar "Reintentar"
        child: GridView.builder(
          // Tu código de la grilla de productos va aquí
          itemCount: _products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
          itemBuilder: (context, index) => const Card(child: Text('Producto')),
        ),
      ),
    );
  }
}