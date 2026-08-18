import 'package:flutter/material.dart';
import '../models/prenda_model.dart';
import 'detalle_prenda_screen.dart';
import 'crear_publicacion_screen.dart';

class HomeScreen extends StatelessWidget {
  final String nombreUsuario;
  final int idUsuario;

  const HomeScreen({
    Key? key,
    this.nombreUsuario = "diego murillo",
    this.idUsuario = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3B5998),
        title: const Text(
          'TrendVibe',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BANNER / HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B5998), Color(0xFF4C6EF5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ID Usuario: #$idUsuario',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '¡Bienvenido, ${nombreUsuario.toUpperCase()}! 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Mira el catálogo de la tienda, revisa fotos y opina sobre calidad y precio.',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white12,
                        child: Icon(Icons.person_rounded, size: 45, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 2. RESUMEN GENERAL
                Text(
                  'Resumen General',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.8)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Publicaciones', '12', Icons.article_outlined, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Vistas', '1.4k', Icons.remove_red_eye_outlined, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Favoritos', '89', Icons.favorite_border, Colors.orange)),
                  ],
                ),

                const SizedBox(height: 28),

                // 3. ACCIONES PRINCIPALES
                Text(
                  'Acciones Rápidas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.8)),
                ),
                const SizedBox(height: 12),

                _buildActionCard(
                  context,
                  title: 'Crear publicación',
                  subtitle: 'Sube fotos de una nueva prenda para recibir opiniones',
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: const Color(0xFF3B5998),
                  onTap: () async {
                    final nuevaPrenda = await Navigator.push<Prenda>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CrearPublicacionScreen(),
                      ),
                    );

                    if (nuevaPrenda != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('¡Publicación "${nuevaPrenda.nombre}" creada con éxito!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 14),

                _buildActionCard(
                  context,
                  title: 'Ver publicaciones',
                  subtitle: 'Explora prendas, mira fotos y opina sobre calidad y precio',
                  icon: Icons.grid_view_rounded,
                  iconColor: const Color(0xFF20C997),
                  onTap: () {
                    final prendaEjemplo = Prenda(
                      id: 1,
                      nombre: 'Camiseta Oversize Heavy Cotton',
                      precioReferencial: 25.00,
                      tipoTela: '100% Algodón Peinado (240 GSM)',
                      categoria: 'Camisetas',
                      fotos: [
                        'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800',
                        'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800',
                      ],
                      comentarios: [
                        Comentario(
                          usuario: 'Carlos M.',
                          texto: 'El grosor del algodón es excelente, no se deforma tras las lavadas. El precio de \$25 vale totalmente la pena.',
                          calificacion: 5.0,
                          fecha: 'Hace 2 días',
                        ),
                        Comentario(
                          usuario: 'Andrea P.',
                          texto: 'El corte oversize es bueno pero viene un poco más larga de lo esperado en la talla M.',
                          calificacion: 4.0,
                          fecha: 'Hace 5 días',
                        ),
                      ],
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetallePrendaScreen(prenda: prendaEjemplo),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // 4. BOTÓN CERRAR SESIÓN
                Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}