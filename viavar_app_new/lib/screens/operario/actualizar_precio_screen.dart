import 'package:flutter/material.dart';
import '../../services/operario_service.dart';
import '../../services/maquinas_service.dart';
import '../../models/maquina.dart';
import '../../models/operario_models.dart';

class ActualizarPrecioScreen extends StatefulWidget {
  const ActualizarPrecioScreen({super.key});

  @override
  State<ActualizarPrecioScreen> createState() => _ActualizarPrecioScreenState();
}

class _ActualizarPrecioScreenState extends State<ActualizarPrecioScreen> {
  final OperarioService _operarioService = OperarioService();
  final MaquinasService _maquinasService = MaquinasService();

  List<Maquina> _maquinas = [];
  List<ProductoInventario> _inventario = [];

  int? _maquinaSeleccionadaId;
  ProductoInventario? _productoSeleccionado;

  final TextEditingController _precioController = TextEditingController();

  bool _cargandoMaquinas = true;
  bool _cargandoInventario = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarMaquinas();
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _cargarMaquinas() async {
    try {
      final maquinas = await _maquinasService.getMaquinas();
      setState(() {
        _maquinas = maquinas
            .where((m) => m.estado == 'activa' || m.estado == 'activo')
            .toList();
        _cargandoMaquinas = false;
      });
    } catch (e) {
      setState(() {
        _cargandoMaquinas = false;
      });
    }
  }

  Future<void> _cargarInventario() async {
    if (_maquinaSeleccionadaId == null) return;

    setState(() {
      _cargandoInventario = true;
      _productoSeleccionado = null;
      _precioController.clear();
    });

    try {
      final inventario =
          await _operarioService.getInventarioMaquina(_maquinaSeleccionadaId!);
      setState(() {
        _inventario = inventario.where((p) => p.stockMaximo > 0).toList();
        _cargandoInventario = false;
      });
    } catch (e) {
      setState(() {
        _cargandoInventario = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar inventario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _actualizarPrecio() async {
    if (_productoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nuevoPrecio = double.tryParse(_precioController.text);
    if (nuevoPrecio == null || nuevoPrecio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un precio válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _operarioService.actualizarPrecio(
        _productoSeleccionado!.id,
        nuevoPrecio,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Precio actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Error al actualizar precio');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Precio'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _cargandoMaquinas
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de máquina
                  const Text(
                    'Seleccionar Máquina',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _maquinaSeleccionadaId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon:
                          const Icon(Icons.settings_applications_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('-- Seleccionar máquina --'),
                      ),
                      ..._maquinas.map((maquina) {
                        return DropdownMenuItem<int>(
                          value: maquina.id,
                          child: Text('${maquina.nombre} (${maquina.codigo})'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _maquinaSeleccionadaId = value;
                      });
                      _cargarInventario();
                    },
                  ),

                  const SizedBox(height: 20),

                  // Selector de producto (solo si hay máquina seleccionada)
                  if (_maquinaSeleccionadaId != null) ...[
                    const Text(
                      'Seleccionar Producto',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _cargandoInventario
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<ProductoInventario>(
                            value: _productoSeleccionado,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.inventory),
                            ),
                            items: _inventario.map((producto) {
                              return DropdownMenuItem<ProductoInventario>(
                                value: producto,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(producto.nombre),
                                    Text(
                                      'Precio actual: \$${producto.precioVenta.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _productoSeleccionado = value;
                                if (value != null) {
                                  _precioController.text =
                                      value.precioVenta.toStringAsFixed(0);
                                }
                              });
                            },
                          ),
                  ],

                  const SizedBox(height: 20),

                  // Campo para nuevo precio
                  if (_productoSeleccionado != null) ...[
                    const Text(
                      'Nuevo Precio',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _precioController,
                      decoration: InputDecoration(
                        labelText: 'Precio de venta',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],

                  const Spacer(),

                  // Botón actualizar
                  if (_productoSeleccionado != null)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _actualizarPrecio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ACTUALIZAR PRECIO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                ],
              ),
            ),
    );
  }
}
