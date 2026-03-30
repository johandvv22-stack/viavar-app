import 'package:flutter/material.dart';
import '../../services/productos_service.dart';
import '../../models/producto.dart';

class ProductosConsultaScreen extends StatefulWidget {
  const ProductosConsultaScreen({super.key});

  @override
  State<ProductosConsultaScreen> createState() =>
      _ProductosConsultaScreenState();
}

class _ProductosConsultaScreenState extends State<ProductosConsultaScreen> {
  final ProductosService _productosService = ProductosService();
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _categoriaFiltro = 'Todas';

  final List<String> _categorias = [
    'Todas',
    'snack',
    'bebidas',
    'paquete_mediano',
    'paquete_grande',
    'liquido_grande'
  ];

  final Map<String, IconData> _iconosCategorias = {
    'Todas': Icons.category,
    'snack': Icons.cookie,
    'bebidas': Icons.local_drink,
    'paquete_mediano': Icons.inventory,
    'paquete_grande': Icons.inventory_2,
    'liquido_grande': Icons.water_drop,
  };

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productos = await _productosService.getProductos();
      setState(() {
        _productos = productos;
        _productosFiltrados = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filtrarProductos() {
    setState(() {
      _productosFiltrados = _productos.where((p) {
        // Filtrar por búsqueda
        final matchesSearch = _searchQuery.isEmpty ||
            p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.codigo.toLowerCase().contains(_searchQuery.toLowerCase());

        // Filtrar por categoría
        final matchesCategoria = _categoriaFiltro == 'Todas' ||
            p.categoria.toLowerCase() == _categoriaFiltro.toLowerCase();

        return matchesSearch && matchesCategoria;
      }).toList();
    });
  }

  String _getCategoriaLabel(String categoria) {
    switch (categoria) {
      case 'snack':
        return 'Snacks';
      case 'bebidas':
        return 'Bebidas';
      case 'paquete_mediano':
        return 'Paquete Mediano';
      case 'paquete_grande':
        return 'Paquete Grande';
      case 'liquido_grande':
        return 'Líquido Grande';
      default:
        return categoria;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda y filtros
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[50],
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar producto por nombre o código...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filtrarProductos();
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categorias.map((categoria) {
                    final isSelected = _categoriaFiltro == categoria;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconosCategorias[categoria] ?? Icons.category,
                              size: 16,
                              color:
                                  isSelected ? Colors.white : Colors.green[800],
                            ),
                            const SizedBox(width: 4),
                            Text(_getCategoriaLabel(categoria)),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _categoriaFiltro = categoria;
                            _filtrarProductos();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.green[800],
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Resultados
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $_error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _cargarProductos,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _productosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text(
                                'No se encontraron productos',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Intenta con otros filtros de búsqueda',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarProductos,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _productosFiltrados.length,
                            itemBuilder: (context, index) {
                              final producto = _productosFiltrados[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green[100],
                                    child: Icon(
                                      _iconosCategorias[producto.categoria] ??
                                          Icons.category,
                                      color: Colors.green[800],
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    producto.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Código: ${producto.codigo}'),
                                      Row(
                                        children: [
                                          Text(
                                            'Compra: \$${producto.precioCompra.toStringAsFixed(0)}',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Venta: \$${producto.precioVentaSugerido.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}
