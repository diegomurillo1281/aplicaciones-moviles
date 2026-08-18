import 'package:flutter/material.dart';
import '../models/prenda_model.dart';

class DetallePrendaScreen extends StatefulWidget {
  final Prenda prenda;

  const DetallePrendaScreen({Key? key, required this.prenda}) : super(key: key);

  @override
  State<DetallePrendaScreen> createState() => _DetallePrendaScreenState();
}

class _DetallePrendaScreenState extends State<DetallePrendaScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  int _currentImageIndex = 0;
  double _userRating = 5.0;

  void _agregarComentario() {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      widget.prenda.comentarios.insert(
        0,
        Comentario(
          usuario: 'Tú (Usuario)',
          texto: _commentController.text.trim(),
          calificacion: _userRating,
          fecha: 'Ahora',
        ),
      );
      _commentController.clear();
      _userRating = 5.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Reseña publicada correctamente!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
        title: Text(
          widget.prenda.nombre,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. GALERÍA / CARRUSEL DE IMÁGENES
                _buildGaleriaImagenes(),

                const SizedBox(height: 20),

                // 2. INFORMACIÓN PRINCIPAL Y PRECIO REFERENCIAL
                _buildInfoPrenda(),

                const SizedBox(height: 24),

                // 3. FORMULARIO PARA AGREGAR RESEÑA Y CALIFICACIÓN
                _buildFormularioResena(),

                const SizedBox(height: 24),

                // 4. LISTA DE COMENTARIOS Y CRÍTICAS
                _buildListaComentarios(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGaleriaImagenes() {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black12,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.prenda.fotos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  widget.prenda.fotos[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                    );
                  },
                );
              },
            ),
          ),
          // Indicador de foto actual (Puntos)
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.prenda.fotos.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPrenda() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(
                  widget.prenda.categoria.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                backgroundColor: const Color(0xFF3B5998),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 26),
                  const SizedBox(width: 4),
                  Text(
                    widget.prenda.promedioCalificacion.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' (${widget.prenda.comentarios.length} opiniones)',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.prenda.nombre,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Precio Referencial: ',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              Text(
                '\$${widget.prenda.precioReferencial.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Tipo de Tela / Material: ',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              Text(
                widget.prenda.tipoTela,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioResena() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Escribe tu opinión o crítica',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Evalúa la calidad de la tela, el acabado, si el precio lo vale o el estilo de la prenda:',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Tu valoración: ', style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _userRating = (index + 1).toDouble();
                      });
                    },
                  );
                }),
              ),
            ],
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ejemplo: La tela es ligera pero el acabado del cuello podría mejorar. El precio me parece justo...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B5998),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _agregarComentario,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              label: const Text('Publicar Opinión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaComentarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comentarios de la Comunidad (${widget.prenda.comentarios.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.prenda.comentarios.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Aún no hay comentarios. ¡Sé el primero en opinar!'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.prenda.comentarios.length,
            itemBuilder: (context, index) {
              final c = widget.prenda.comentarios[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF3B5998).withOpacity(0.1),
                              child: Text(
                                c.usuario[0].toUpperCase(),
                                style: const TextStyle(color: Color(0xFF3B5998), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c.usuario, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            Text('${c.calificacion.toStringAsFixed(1)} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('• ${c.fecha}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(c.texto, style: const TextStyle(fontSize: 14, height: 1.3)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}