import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/finanzas_service.dart';
import '../../../../services/maquinas_service.dart';
import '../../../../models/finanzas_modelos.dart';
import '../../../../models/maquina.dart';

class CierresFinanzasTab extends StatefulWidget {
  const CierresFinanzasTab({super.key});

  @override
  State<CierresFinanzasTab> createState() => _CierresFinanzasTabState();
}

class _CierresFinanzasTabState extends State<CierresFinanzasTab> {
  final FinanzasService _finanzasService = FinanzasService();
  final MaquinasService _maquinasService = MaquinasService();

  List<CierreMensual> _cierres = [];
  List<Maquina> _maquinas = [];
  bool _isLoading = true;
  String? _error;

  int? _filtroAnio;
  int? _filtroMes;
  List<int> _aniosDisponibles = [];

  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'es_CO');
  final NumberFormat _percentFormat = NumberFormat('#,##0.0');

  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color successColor = Color(0xFF10B981);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  //static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // CORREGIDO: getMaquinas() devuelve List<Maquina>
      final maquinasList = await _maquinasService.getMaquinas();
      _maquinas = maquinasList;

      final todosCierres = await _finanzasService.getCierres();
      final aniosSet = <int>{};
      for (var cierre in todosCierres) {
        aniosSet.add(cierre.anio);
      }
      _aniosDisponibles = aniosSet.toList()..sort((a, b) => b.compareTo(a));

      if (_aniosDisponibles.isEmpty) {
        _aniosDisponibles = [DateTime.now().year];
      }
      if (_filtroAnio == null) {
        _filtroAnio = _aniosDisponibles.first;
      }

      await _cargarCierres();
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarCierres() async {
    try {
      _cierres = await _finanzasService.getCierres(
        anio: _filtroAnio,
        mes: _filtroMes,
      );
    } catch (e) {
      setState(() {
        _error = 'Error al cargar cierres: $e';
      });
    }
  }

  Future<void> _crearOEditarCierre([CierreMensual? cierre]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CierreFormDialog(
        maquinas: _maquinas,
        cierre: cierre,
      ),
    );

    if (result == true) {
      _cargarDatos();
    }
  }

  Future<void> _eliminarCierre(CierreMensual cierre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cierre'),
        content: Text(
          '¿Eliminar cierre de ${cierre.maquinaNombre} para ${_getNombreMes(cierre.mes)}/${cierre.anio}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _finanzasService.eliminarCierre(cierre.id);
      if (success) {
        _cargarDatos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar cierre')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatPeso(double value) => '\$${_currencyFormat.format(value)}';
  String _getNombreMes(int mes) =>
      DateFormat('MMMM').format(DateTime(2000, mes));

  @override
  Widget build(BuildContext context) {
    final totalVentas = _cierres.fold(0.0, (s, c) => s + c.ventasTotales);
    final totalGastos = _cierres.fold(0.0, (s, c) => s + c.gastosTotales);
    final totalUtilidad = totalVentas - totalGastos;
    final margen = totalVentas > 0 ? (totalUtilidad / totalVentas) * 100 : 0;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: primaryColor,
      child: Column(
        children: [
          // Barra de filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _filtroAnio,
                    decoration: InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _aniosDisponibles.map((a) {
                      return DropdownMenuItem(
                          value: a, child: Text(a.toString()));
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _filtroAnio = v;
                        _filtroMes = null;
                      });
                      _cargarCierres();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _filtroMes,
                    decoration: InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...List.generate(12, (i) => i + 1).map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(_getNombreMes(m)),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      setState(() => _filtroMes = v);
                      _cargarCierres();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  onPressed: () => _crearOEditarCierre(),
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Tarjeta de resumen (estilo Dashboard)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Ventas',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            _formatPeso(totalVentas),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: successColor),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.grey[300]),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Gastos',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            _formatPeso(totalGastos),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: dangerColor),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.grey[300]),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Utilidad',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            _formatPeso(totalUtilidad),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: totalUtilidad >= 0
                                  ? successColor
                                  : dangerColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.grey[300]),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Margen',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '${_percentFormat.format(margen)}%',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: warningColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de cierres
          Expanded(
            child: _cierres.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No hay cierres registrados',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _crearOEditarCierre(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          child: const Text('Crear primer cierre'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cierres.length,
                    itemBuilder: (context, index) {
                      final c = _cierres[index];
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child:
                                Icon(Icons.calendar_month, color: primaryColor),
                          ),
                          title: Text(
                            c.maquinaNombre,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text('${_getNombreMes(c.mes)}/${c.anio}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatPeso(c.ventasTotales),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: successColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _crearOEditarCierre(c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 20, color: Colors.red),
                                onPressed: () => _eliminarCierre(c),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Diálogo para crear/editar cierre
class _CierreFormDialog extends StatefulWidget {
  final List<Maquina> maquinas;
  final CierreMensual? cierre;

  const _CierreFormDialog({required this.maquinas, this.cierre});

  @override
  State<_CierreFormDialog> createState() => _CierreFormDialogState();
}

class _CierreFormDialogState extends State<_CierreFormDialog> {
  final FinanzasService _finanzasService = FinanzasService();
  final _formKey = GlobalKey<FormState>();
  final _ventasController = TextEditingController();
  final _gastosController = TextEditingController();
  final _observacionesController = TextEditingController();

  int? _selectedMaquinaId;
  int _selectedMes = DateTime.now().month;
  int _selectedAnio = DateTime.now().year;
  double _ventas = 0;
  double _gastos = 0;
  String _observaciones = '';

  @override
  void initState() {
    super.initState();
    if (widget.cierre != null) {
      _selectedMaquinaId = widget.cierre!.maquinaId;
      _selectedMes = widget.cierre!.mes;
      _selectedAnio = widget.cierre!.anio;
      _ventas = widget.cierre!.ventasTotales;
      _gastos = widget.cierre!.gastosTotales;
      _observaciones = widget.cierre!.observaciones ?? '';

      _ventasController.text = _ventas.toString();
      _gastosController.text = _gastos.toString();
      _observacionesController.text = _observaciones;
    }
  }

  @override
  void dispose() {
    _ventasController.dispose();
    _gastosController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  String _getNombreMes(int mes) =>
      DateFormat('MMMM').format(DateTime(2000, mes));

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMaquinaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una máquina')),
      );
      return;
    }

    // Asegurar que los valores sean números, no strings
    final ventasValor = _ventas;
    final gastosValor = _gastos;
    final gananciaValor = ventasValor - gastosValor;

    final data = {
      'maquina': _selectedMaquinaId,
      'mes': _selectedMes,
      'año': _selectedAnio,
      'ventas_totales': ventasValor,
      'gastos_totales': gastosValor,
      'ganancia_neta': gananciaValor,
      'observaciones': _observaciones,
    };

    print('📤 Guardando cierre: $data');

    try {
      bool success;
      if (widget.cierre != null) {
        success =
            await _finanzasService.actualizarCierre(widget.cierre!.id, data);
      } else {
        final result = await _finanzasService.crearCierre(data);
        success = result != null;
      }

      if (success) {
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar el cierre')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.maquinas.map<DropdownMenuItem<int>>((maquina) {
      return DropdownMenuItem<int>(
        value: maquina.id,
        child: Text(maquina.nombre),
      );
    }).toList();

    return AlertDialog(
      title: Text(widget.cierre == null ? 'Nuevo Cierre' : 'Editar Cierre'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedMaquinaId,
                  decoration: const InputDecoration(
                    labelText: 'Máquina',
                    border: OutlineInputBorder(),
                  ),
                  items: items,
                  onChanged: (value) =>
                      setState(() => _selectedMaquinaId = value),
                  validator: (value) =>
                      value == null ? 'Seleccione una máquina' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMes,
                        decoration: const InputDecoration(
                          labelText: 'Mes',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (i) => i + 1)
                            .map<DropdownMenuItem<int>>((mes) {
                          return DropdownMenuItem<int>(
                            value: mes,
                            child: Text(_getNombreMes(mes)),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedMes = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedAnio,
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          border: OutlineInputBorder(),
                        ),
                        items: [2024, 2025, 2026, 2027]
                            .map<DropdownMenuItem<int>>((anio) {
                          return DropdownMenuItem<int>(
                            value: anio,
                            child: Text(anio.toString()),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedAnio = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ventasController,
                  decoration: const InputDecoration(
                    labelText: 'Ventas Totales',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _ventas = double.tryParse(value) ?? 0,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese ventas';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gastosController,
                  decoration: const InputDecoration(
                    labelText: 'Gastos Totales',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _gastos = double.tryParse(value) ?? 0,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese gastos';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observacionesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => _observaciones = value,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
          ),
          child: Text(widget.cierre == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
