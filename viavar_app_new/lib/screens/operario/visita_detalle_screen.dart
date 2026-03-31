import 'package:flutter/material.dart';
import '../../services/operario_service.dart';
import '../../models/operario_models.dart';
import '../../models/maquina.dart';

class VisitaDetalleScreen extends StatefulWidget {
  final MaquinaRuta maquina;

  const VisitaDetalleScreen({super.key, required this.maquina});

  @override
  State<VisitaDetalleScreen> createState() => _VisitaDetalleScreenState();
}

class _VisitaDetalleScreenState extends State<VisitaDetalleScreen> {
  final OperarioService _operarioService = OperarioService();

  // Estado de la visita
  int? _visitaId;
  List<ProductoInventario> _productos = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isFinalizing = false;
  String? _error;
  bool _visitaIniciada = false;
  // ignore: unused_field
  bool _conteoRealizado = false;

  @override
  void initState() {
    super.initState();
    // Solo cargar productos faltantes, NO iniciar visita automáticamente
    _cargarProductosFaltantes();
  }

  // 1. Cargar productos faltantes (sin iniciar visita)
  // 1. Cargar productos faltantes (sin iniciar visita)
  Future<void> _cargarProductosFaltantes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print(
          '🟢 Cargando productos faltantes para máquina: ${widget.maquina.id}');
      final productos =
          await _operarioService.getProductosFaltantes(widget.maquina.id);

      // Mostrar información detallada para depuración
      for (var p in productos) {
        print('   📦 Producto: ${p.nombre}');
        print('      - stockActual: ${p.stockActual}');
        print('      - stockMaximo: ${p.stockMaximo}');
        print('      - cantidadFaltante: ${p.cantidadFaltante}');
        print('      - necesitaSurtir: ${p.necesitaSurtir}');
      }

      setState(() {
        _productos = productos;
        _isLoading = false;
      });

      print('✅ Productos faltantes: ${_productos.length}');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // 2. Iniciar visita y conteo ESP32
  Future<void> _iniciarConteo() async {
    setState(() {
      _isUpdating = true;
      _error = null;
    });

    try {
      print('🟢 Iniciando visita para máquina: ${widget.maquina.id}');
      final visitaData =
          await _operarioService.iniciarVisita(widget.maquina.id);
      _visitaId = visitaData['id'];

      setState(() {
        _visitaIniciada = true;
        _conteoRealizado = true;
        _isUpdating = false;
      });

      // Después de iniciar, recargar productos faltantes (el conteo puede haber cambiado)
      await _cargarProductosFaltantes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conteo realizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error en _iniciarConteo: $e');
      final errorMsg = e.toString();

      // Verificar si ya hay una visita en curso
      if (errorMsg.contains('Ya hay una visita en curso')) {
        final RegExp regExp = RegExp(r'visita_id":(\d+)');
        final match = regExp.firstMatch(errorMsg);
        final visitaId = match?.group(1);

        if (visitaId != null) {
          setState(() {
            _visitaId = int.parse(visitaId);
            _visitaIniciada = true;
            _conteoRealizado = true;
            _isUpdating = false;
          });
          await _cargarProductosFaltantes();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya había una visita en curso. Continuando...'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          setState(() {
            _error = 'Ya hay una visita en curso pero no se pudo recuperar';
            _isUpdating = false;
          });
        }
      } else {
        setState(() {
          _error = errorMsg;
          _isUpdating = false;
        });
      }
    }
  }

  // 3. Finalizar visita
  Future<void> _finalizarVisita() async {
    if (_visitaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay una visita activa'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isFinalizing = true;
    });

    try {
      final productosSurtidos =
          _productos.where((p) => p.surtido).map((p) => p.id).toList();

      await _operarioService.finalizarVisita(_visitaId!, productosSurtidos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Visita finalizada correctamente'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isFinalizing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 4. Cancelar visita actual
  Future<void> _cancelarVisitaActual() async {
    if (_visitaId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar visita'),
        content:
            const Text('¿Estás seguro de que quieres cancelar esta visita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir en visita'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar visita'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUpdating = true);
      try {
        final cancelada = await _operarioService.cancelarVisita(_visitaId!);
        if (cancelada) {
          setState(() {
            _visitaId = null;
            _visitaIniciada = false;
            _conteoRealizado = false;
            _isUpdating = false;
          });
          await _cargarProductosFaltantes();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Visita cancelada'),
                backgroundColor: Colors.orange),
          );
        } else {
          throw Exception('No se pudo cancelar');
        }
      } catch (e) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cancelar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleProducto(ProductoInventario producto) {
    setState(() {
      producto.surtido = !producto.surtido;
    });
  }

  void _seleccionarTodos() {
    setState(() {
      for (var producto in _productos) {
        producto.surtido = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visita: ${widget.maquina.nombre}'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          if (_visitaIniciada)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelarVisitaActual,
              tooltip: 'Cancelar visita',
            ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _cargarProductosFaltantes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Info de la máquina
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.maquina.nombre,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.maquina.ubicacion,
                              style: TextStyle(color: Colors.grey[700])),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.inventory,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: ${widget.maquina.porcentajeSurtido.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Botones de acción
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isUpdating
                                  ? null
                                  : _cargarProductosFaltantes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUpdating ? null : _iniciarConteo,
                              icon: _isUpdating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.sensors),
                              label: Text(_visitaIniciada
                                  ? 'Conteo realizado'
                                  : 'Iniciar conteo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _visitaIniciada
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Resumen de productos faltantes
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.grey[50],
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_productos.length} producto${_productos.length != 1 ? 's' : ''} a surtir',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_productos.isNotEmpty && _visitaIniciada)
                            TextButton(
                              onPressed: _seleccionarTodos,
                              child: const Text('Seleccionar todos'),
                            ),
                        ],
                      ),
                    ),

                    // Lista de productos
                    Expanded(
                      child: _productos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 64, color: Colors.green[300]),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '¡Todo está completo!',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'No hay productos faltantes en esta máquina'),
                                  const SizedBox(height: 24),
                                  if (_visitaIniciada)
                                    ElevatedButton(
                                      onPressed: _isFinalizing
                                          ? null
                                          : _finalizarVisita,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(200, 45),
                                      ),
                                      child: _isFinalizing
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Text('FINALIZAR VISITA'),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _productos.length,
                              itemBuilder: (context, index) {
                                final producto = _productos[index];
                                final habilitado = _visitaIniciada;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: producto.surtido
                                      ? Colors.green[50]
                                      : Colors.white,
                                  child: CheckboxListTile(
                                    title: Text(
                                      producto.nombre,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: producto.surtido
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Código: ${producto.codigo}'),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                                'Stock: ${producto.stockActual}/${producto.stockMaximo}'),
                                            const SizedBox(width: 16),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[100],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Faltan: ${producto.cantidadFaltante}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange[800],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    secondary: CircleAvatar(
                                      backgroundColor: producto.surtido
                                          ? Colors.green
                                          : Colors.orange,
                                      child: Text(
                                        producto.cantidadFaltante.toString(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    value: producto.surtido,
                                    onChanged: habilitado
                                        ? (_) => _toggleProducto(producto)
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),

                    // Botón finalizar (si hay productos)
                    if (_productos.isNotEmpty && _visitaIniciada)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Progreso',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[600])),
                                Text(
                                  '${_productos.where((p) => p.surtido).length}/${_productos.length}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _productos.isEmpty
                                    ? 0
                                    : _productos
                                            .where((p) => p.surtido)
                                            .length /
                                        _productos.length,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.green[700]!),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed:
                                  _isFinalizing ? null : _finalizarVisita,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isFinalizing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('FINALIZAR VISITA',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

// Modelo auxiliar para productos en visita
class ProductoVisita {
  final int id;
  final String codigo;
  final String nombre;
  final String categoria;
  final int stockActual;
  final int stockMaximo;
  final int faltante;
  bool surtido;

  ProductoVisita({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.stockActual,
    required this.stockMaximo,
    required this.faltante,
    this.surtido = false,
  });
}

// Modelo auxiliar para visita activa
class VisitaActiva {
  final int id;
  final int maquinaId;
  final String maquinaNombre;
  final DateTime fechaInicio;
  final List<ProductoVisita> productosFaltantes;
  bool finalizada;

  VisitaActiva({
    required this.id,
    required this.maquinaId,
    required this.maquinaNombre,
    required this.fechaInicio,
    required this.productosFaltantes,
    this.finalizada = false,
  });

  int get totalFaltantes => productosFaltantes.length;
  int get surtidos => productosFaltantes.where((p) => p.surtido).length;
  double get progreso => totalFaltantes == 0 ? 0 : surtidos / totalFaltantes;
}
