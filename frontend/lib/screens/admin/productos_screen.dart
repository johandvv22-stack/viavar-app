import "dart:async";
import "package:flutter/material.dart";
import "../../services/productos_service.dart";
import "../../models/producto.dart";
import './formulario_producto_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductosService _productosService = ProductosService();
  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = "";
  String? _categoriaFiltro;
  bool? _estadoFiltro;
  Timer? _searchDebounce;

  List<String> _categoriasDisponibles = [];
  // final List<bool?> _estadosDisponibles = [null, true, false]; // Campo no usado

  // Getter para productos filtrados (filtra en memoria para respuesta más rápida)
  List<Producto> get _productosFiltrados {
    List<Producto> filtrados = _productos;

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtrados = filtrados
          .where((p) =>
              p.nombre.toLowerCase().contains(query) ||
              p.codigo.toLowerCase().contains(query) ||
              (p.descripcion?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    // Filtrar por categoría
    if (_categoriaFiltro != null) {
      filtrados =
          filtrados.where((p) => p.categoria == _categoriaFiltro).toList();
    }

    // Filtrar por estado
    if (_estadoFiltro != null) {
      filtrados = filtrados.where((p) => p.estado == _estadoFiltro).toList();
    }

    return filtrados;
  }

  @override
  void initState() {
    super.initState();
    _loadProductos();
    _loadCategorias();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadProductos() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productos = await _productosService.getProductos(
        categoria: _categoriaFiltro,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        estado: _estadoFiltro,
      );

      if (!mounted) return;

      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategorias() async {
    try {
      final categorias = await _productosService.getCategorias();
      if (mounted) {
        setState(() {
          _categoriasDisponibles = categorias;
        });
      }
    } catch (e) {
      print("Error cargando categorías: $e");
    }
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadProductos();
    });
  }

  void _onCategoriaFiltroChanged(String? value) {
    setState(() {
      _categoriaFiltro = value;
    });
    _loadProductos();
  }

  void _onEstadoFiltroChanged(bool? value) {
    setState(() {
      _estadoFiltro = value;
    });
    _loadProductos();
  }

  Future<void> _eliminarProducto(Producto producto) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content:
            Text("¿Estás seguro de eliminar el producto '${producto.nombre}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _productosService.deleteProducto(producto.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Producto '${producto.nombre}' eliminado"),
            backgroundColor: Colors.green,
          ),
        );
        _loadProductos(); // Recargar lista
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editarProducto(Producto producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FormularioProductoScreen(productoEditar: producto),
      ),
    ).then((value) {
      if (value == true) {
        _loadProductos(); // Recargar lista si se guardó
      }
    });
  }

  void _nuevoProducto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormularioProductoScreen(),
      ),
    ).then((value) {
      if (value == true) {
        _loadProductos(); // Recargar lista si se guardó
      }
    });
  }

  void _verDetallesProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(producto.nombre),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow("Código:", producto.codigo),
                _buildInfoRow("Categoría:", producto.nombreCategoria),
                _buildInfoRow("Estado:", producto.estadoTexto),
                _buildInfoRow("Precio compra:",
                    "\$${producto.precioCompra.toStringAsFixed(0)}"),
                _buildInfoRow("Precio venta:",
                    "\$${producto.precioVentaSugerido.toStringAsFixed(0)}"),
                _buildInfoRow("Ganancia unitaria:",
                    "\$${producto.gananciaUnitaria.toStringAsFixed(0)}"),
                _buildInfoRow("Margen ganancia:",
                    "${producto.margenGanancia.toStringAsFixed(1)}%"),
                if (producto.descripcion != null &&
                    producto.descripcion!.isNotEmpty)
                  _buildInfoRow("Descripción:", producto.descripcion!),
                _buildInfoRow("Fecha creación:",
                    "${producto.fechaCreacion.day}/${producto.fechaCreacion.month}/${producto.fechaCreacion.year}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
            ElevatedButton(
              onPressed: () => _editarProducto(producto),
              child: const Text("Editar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(Producto producto) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ícono de categoría
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: producto.estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    producto.iconoCategoria,
                    color: producto.estadoColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Código: ${producto.codigo}  ${producto.nombreCategoria}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Estado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: producto.estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: producto.estadoColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        producto.estadoIcono,
                        size: 12,
                        color: producto.estadoColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        producto.estadoTexto,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: producto.estadoColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Precios y ganancia
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Precio compra: \$${producto.precioCompra.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        "Precio venta: \$${producto.precioVentaSugerido.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Margen de ganancia
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: producto.colorMargen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: producto.colorMargen),
                  ),
                  child: Text(
                    "${producto.margenGanancia.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: producto.colorMargen,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _verDetallesProducto(producto),
                    child: const Text("Detalles"),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _editarProducto(producto),
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: "Editar",
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                  ),
                ),
                IconButton(
                  onPressed: () => _eliminarProducto(producto),
                  icon: const Icon(Icons.delete, size: 20),
                  tooltip: "Eliminar",
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[50],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Catálogo de productos",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: _isLoading ? Colors.grey : Colors.white,
            onPressed: _loadProductos,
            tooltip: "Recargar productos",
          ),
          IconButton(
            icon: const Icon(Icons.add),
            color: _isLoading ? Colors.grey : Colors.white,
            onPressed: _nuevoProducto,
            tooltip: "Nuevo producto",
          ),
        ],
      ),
      body: _isLoading && _productos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _productos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text("Error: $_error",
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProductos,
                        child: const Text("Reintentar"),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Barra de búsqueda y filtros
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Column(
                        children: [
                          // Barra de búsqueda
                          TextField(
                            decoration: InputDecoration(
                              hintText: "Buscar productos...",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: _onSearchChanged,
                          ),

                          const SizedBox(height: 12),

                          // Filtros
                          Row(
                            children: [
                              // Filtro por categoría
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _categoriaFiltro,
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text("Todas las categorías"),
                                    ),
                                    ..._categoriasDisponibles.map((categoria) {
                                      final productoEjemplo = Producto(
                                        id: 0,
                                        codigo: "",
                                        nombre: "",
                                        categoria: categoria,
                                        precioCompra: 0,
                                        precioVentaSugerido: 0,
                                        gananciaUnitaria: 0,
                                        estado: true,
                                        fechaCreacion: DateTime.now(),
                                      );
                                      return DropdownMenuItem(
                                        value: categoria,
                                        child: Row(
                                          children: [
                                            Icon(productoEjemplo.iconoCategoria,
                                                size: 16),
                                            const SizedBox(width: 8),
                                            Text(productoEjemplo
                                                .nombreCategoria),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: _onCategoriaFiltroChanged,
                                  decoration: InputDecoration(
                                    labelText: "Categoría",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  isExpanded: true,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Filtro por estado
                              Expanded(
                                child: DropdownButtonFormField<bool?>(
                                  value: _estadoFiltro,
                                  items: const [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text("Todos los estados"),
                                    ),
                                    DropdownMenuItem(
                                      value: true,
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              size: 16, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text("Activos"),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: false,
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel,
                                              size: 16, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text("Inactivos"),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: _onEstadoFiltroChanged,
                                  decoration: InputDecoration(
                                    labelText: "Estado",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  isExpanded: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Contador de resultados
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${_productosFiltrados.length} producto${_productosFiltrados.length != 1 ? 's' : ''} encontrado${_productosFiltrados.length != 1 ? 's' : ''}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          if (_categoriaFiltro != null ||
                              _estadoFiltro != null ||
                              _searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = "";
                                  _categoriaFiltro = null;
                                  _estadoFiltro = null;
                                });
                                _loadProductos();
                              },
                              child: const Text("Limpiar filtros"),
                            ),
                        ],
                      ),
                    ),

                    // Lista de productos
                    Expanded(
                      child: _productosFiltrados.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    "No se encontraron productos",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Intenta con otros filtros de búsqueda",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadProductos,
                              child: ListView.builder(
                                itemCount: _productosFiltrados.length,
                                itemBuilder: (context, index) {
                                  return _buildProductoCard(
                                      _productosFiltrados[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _nuevoProducto,
        backgroundColor: Colors.blue[900],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
