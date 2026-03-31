import "package:flutter/material.dart";
import "../../services/productos_service.dart";
import "../../models/producto.dart";

class FormularioProductoScreen extends StatefulWidget {
  final Producto? productoEditar;

  const FormularioProductoScreen({
    super.key,
    this.productoEditar,
  });

  @override
  State<FormularioProductoScreen> createState() =>
      _FormularioProductoScreenState();
}

class _FormularioProductoScreenState extends State<FormularioProductoScreen> {
  final ProductosService _productosService = ProductosService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _error;

  // Controladores para los campos del formulario
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioCompraController = TextEditingController();
  final TextEditingController _precioVentaController = TextEditingController();

  String _categoriaSeleccionada = "paquete_grande";
  bool _estadoSeleccionado = true;

  // Categorías disponibles
  final List<Map<String, dynamic>> _categorias = [
    {
      "codigo": "paquete_grande",
      "nombre": "Paquete Grande",
      "icono": Icons.fastfood
    },
    {
      "codigo": "paquete_pequeno",
      "nombre": "Paquete Pequeño",
      "icono": Icons.fastfood
    },
    {
      "codigo": "liquido_grande",
      "nombre": "Líquido Grande",
      "icono": Icons.local_drink
    },
    {
      "codigo": "liquido_pequeno",
      "nombre": "Líquido Pequeño",
      "icono": Icons.local_drink
    },
    {"codigo": "snack", "nombre": "Snack", "icono": Icons.fastfood},
    {"codigo": "bebida", "nombre": "Bebida", "icono": Icons.local_drink},
    {"codigo": "cafe", "nombre": "Café", "icono": Icons.coffee},
  ];

  @override
  void initState() {
    super.initState();

    // Si estamos editando, cargar los datos del producto
    if (widget.productoEditar != null) {
      final producto = widget.productoEditar!;
      _codigoController.text = producto.codigo;
      _nombreController.text = producto.nombre;
      _descripcionController.text = producto.descripcion ?? "";
      _precioCompraController.text = producto.precioCompra.toStringAsFixed(0);
      _precioVentaController.text =
          producto.precioVentaSugerido.toStringAsFixed(0);
      _categoriaSeleccionada = producto.categoria;
      _estadoSeleccionado = producto.estado;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    super.dispose();
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final datos = {
        "codigo": _codigoController.text.trim(),
        "nombre": _nombreController.text.trim(),
        "descripcion": _descripcionController.text.trim().isNotEmpty
            ? _descripcionController.text.trim()
            : null,
        "categoria": _categoriaSeleccionada,
        "precio_compra": double.parse(_precioCompraController.text),
        "precio_venta_sugerido": double.parse(_precioVentaController.text),
        "estado": _estadoSeleccionado,
      };

      Producto productoGuardado;

      if (widget.productoEditar != null) {
        // Actualizar producto existente
        productoGuardado = await _productosService.updateProducto(
          widget.productoEditar!.id,
          datos,
        );
      } else {
        // Crear nuevo producto
        productoGuardado = await _productosService.createProducto(datos);
      }

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.productoEditar != null
                ? " Producto '${productoGuardado.nombre}' actualizado"
                : " Producto '${productoGuardado.nombre}' creado",
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Regresar a la pantalla anterior
      if (mounted) {
        Navigator.pop(context, productoGuardado);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(" Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCampoTexto({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obligatorio = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
          suffixIcon: obligatorio
              ? Icon(Icons.circle, size: 12, color: Colors.red)
              : null,
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.productoEditar != null;
    final titulo = esEdicion ? "Editar Producto" : "Nuevo Producto";

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.blue[900],
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      body: _isLoading && !esEdicion
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del formulario
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              esEdicion ? Icons.edit : Icons.add_circle,
                              color: Colors.blue[800],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                esEdicion
                                    ? "Editando producto existente"
                                    : "Complete todos los campos para crear un nuevo producto",
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Campo: Código
                    _buildCampoTexto(
                      label: "Código del Producto",
                      controller: _codigoController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "El código es obligatorio";
                        }
                        if (value.trim().length < 3) {
                          return "El código debe tener al menos 3 caracteres";
                        }
                        return null;
                      },
                    ),

                    // Campo: Nombre
                    _buildCampoTexto(
                      label: "Nombre del Producto",
                      controller: _nombreController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "El nombre es obligatorio";
                        }
                        return null;
                      },
                    ),

                    // Campo: Descripción
                    _buildCampoTexto(
                      label: "Descripción (opcional)",
                      controller: _descripcionController,
                      validator: (value) => null,
                      obligatorio: false,
                      maxLines: 3,
                    ),

                    // Campo: Categoría
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Categoría *",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _categoriaSeleccionada,
                            items: _categorias.map((categoria) {
                              return DropdownMenuItem<String>(
                                value: categoria["codigo"],
                                child: Row(
                                  children: [
                                    Icon(
                                      categoria["icono"],
                                      size: 16,
                                      color: Colors.blue[800],
                                    ),
                                    const SizedBox(width: 12),
                                    Text(categoria["nombre"]),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _categoriaSeleccionada = value;
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: const Color(0xFFFAFAFA),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Seleccione una categoría";
                              }
                              return null;
                            },
                            isExpanded: true,
                          ),
                        ],
                      ),
                    ),

                    // Campos de precios en fila
                    Row(
                      children: [
                        Expanded(
                          child: _buildCampoTexto(
                            label: "Precio Compra",
                            controller: _precioCompraController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Precio compra es obligatorio";
                              }
                              final precio = double.tryParse(value);
                              if (precio == null || precio <= 0) {
                                return "Ingrese un precio válido";
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCampoTexto(
                            label: "Precio Venta Sugerido",
                            controller: _precioVentaController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Precio venta es obligatorio";
                              }
                              final precio = double.tryParse(value);
                              if (precio == null || precio <= 0) {
                                return "Ingrese un precio válido";
                              }

                              // Validar que precio venta sea mayor que compra
                              final precioCompra =
                                  double.tryParse(_precioCompraController.text);
                              if (precioCompra != null &&
                                  precio <= precioCompra) {
                                return "Precio venta debe ser mayor al de compra";
                              }

                              return null;
                            },
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    // Mostrar cálculo de ganancia
                    if (_precioCompraController.text.isNotEmpty &&
                        _precioVentaController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Card(
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up,
                                    color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Ganancia estimada:",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      _buildInfoGanancia(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Campo: Estado
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Text(
                            "Estado del producto:",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 16),
                                SizedBox(width: 4),
                                Text("Activo"),
                              ],
                            ),
                            selected: _estadoSeleccionado,
                            selectedColor: Colors.green,
                            onSelected: (selected) {
                              setState(() {
                                _estadoSeleccionado = true;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cancel, size: 16),
                                SizedBox(width: 4),
                                Text("Inactivo"),
                              ],
                            ),
                            selected: !_estadoSeleccionado,
                            selectedColor: Colors.red,
                            onSelected: (selected) {
                              setState(() {
                                _estadoSeleccionado = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Mostrar error si hay
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Card(
                          color: Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _guardarProducto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    esEdicion ? "Actualizar" : "Crear",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoGanancia() {
    try {
      final precioCompra = double.parse(_precioCompraController.text);
      final precioVenta = double.parse(_precioVentaController.text);
      final ganancia = precioVenta - precioCompra;
      final margen = ((ganancia / precioCompra) * 100);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ganancia unitaria: \$${ganancia.toStringAsFixed(0)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            "Margen: ${margen.toStringAsFixed(1)}%",
            style: TextStyle(
              color: margen >= 50
                  ? Colors.green[800]
                  : margen >= 20
                      ? Colors.blue[800]
                      : Colors.orange[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } catch (e) {
      return const Text("Ingrese precios válidos",
          style: TextStyle(fontSize: 12));
    }
  }
}
