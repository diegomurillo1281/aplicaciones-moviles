import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../services/sync_service.dart';

class HomeScreen extends StatefulWidget {
  final String nombreUsuario;
  final String idUsuario;

  const HomeScreen({
    Key? key, 
    required this.nombreUsuario, 
    required this.idUsuario
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOffline = false;
  List<Map<String, dynamic>> productos = [];
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  @override
  void initState() {
    super.initState();
    _cargarDatosLocales();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      bool sinInternet = results.contains(ConnectivityResult.none);
      setState(() {
        isOffline = sinInternet;
      });

      if (!sinInternet) {
        SyncService().processSyncQueue();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conexión restablecida. Sincronizando...')),
          );
        }
      }
    });
  }

  Future<void> _cargarDatosLocales() async {
    var datos = await DatabaseService.instance.getProductosLocales();

    // Si la base de datos local no tiene productos, inserta 3 por defecto
    if (datos.isEmpty) {
      final productosBase = [
        {
          'nombre': 'Camiseta TrendVibe',
          'precio': 25.00,
          'last_updated_server': DateTime.now().toString().split('.')[0],
        },
        {
          'nombre': 'Jean Slim Fit',
          'precio': 45.00,
          'last_updated_server': DateTime.now().toString().split('.')[0],
        },
        {
          'nombre': 'Chaqueta Urbana',
          'precio': 65.00,
          'last_updated_server': DateTime.now().toString().split('.')[0],
        },
      ];

      for (var prod in productosBase) {
        await DatabaseService.instance.insertarProductoLocal(prod);
      }

      datos = await DatabaseService.instance.getProductosLocales();
    }

    if (mounted) {
      setState(() {
        productos = datos;
      });
    }
  }

  void _mostrarFormularioCrearProducto() {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController precioController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nuevo Producto',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del producto',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.shopping_bag),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre del producto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: precioController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Precio (\$)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el precio';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final String nombre = nombreController.text.trim();
                      final double precio = double.parse(precioController.text.trim());
                      final clientUuid = const Uuid().v4();

                      final nuevoProducto = {
                        'nombre': nombre,
                        'precio': precio,
                        'last_updated_server': isOffline ? 'Pendiente' : DateTime.now().toString().split('.')[0],
                      };

                      // 1. Guardar en la base de datos / memoria
                      await DatabaseService.instance.insertarProductoLocal(nuevoProducto);

                      if (isOffline) {
                        await DatabaseService.instance.addToQueue(
                          clientUuid,
                          'http://localhost:5000/api/productos',
                          '{"nombre": "$nombre", "precio": $precio, "client_uuid": "$clientUuid"}',
                        );
                      }

                      // 2. Cerrar el modal y refrescar la pantalla inmediatamente
                      if (mounted) {
                        Navigator.of(modalContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isOffline 
                                  ? 'Guardado en almacén local y cola pendientes' 
                                  : 'Producto guardado en almacén local'
                            ),
                          ),
                        );
                      }

                      // 3. Forzar actualización de datos en el estado
                      await _cargarDatosLocales();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Guardar Producto', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cerrarSesion() async {
    await SecureStorageService().clearAll();
    await DatabaseService.instance.clearAllData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada. Almacén local eliminado.')),
    );
    await _cargarDatosLocales();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, ${widget.nombreUsuario.toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Column(
        children: [
          if (isOffline)
            Container(
              color: Colors.orange.shade900,
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Modo sin conexión - Datos locales desactualizados',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: productos.isEmpty
                ? const Center(child: Text('No hay datos en el almacén local.'))
                : ListView.builder(
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final p = productos[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.shopping_bag),
                        ),
                        title: Text(p['nombre'] ?? 'Sin Nombre'),
                        subtitle: Text('Sincronizado: ${p['last_updated_server'] ?? 'N/A'}'),
                        trailing: Text('\$${p['precio']}'),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioCrearProducto,
        child: const Icon(Icons.add),
      ),
    );
  }
}