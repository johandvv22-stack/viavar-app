import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/finanzas_service.dart';
import '../../../../models/finanzas_modelos.dart';

class GastosFinanzasTab extends StatefulWidget {
  const GastosFinanzasTab({super.key});

  @override
  State<GastosFinanzasTab> createState() => _GastosFinanzasTabState();
}

class _GastosFinanzasTabState extends State<GastosFinanzasTab> {
  final FinanzasService _finanzasService = FinanzasService();

  List<Gasto> _gastos = [];
  bool _isLoading = true;
  String? _error;

  // Filtros
  DateTime _fechaInicio =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fechaFin = DateTime.now();
  String? _filtroCategoria;
  int? _filtroMaquina;
  String _periodoRapido = 'MES';

  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'es_CO');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static const Color primaryColor = Color(0xFF1E3A8A);
  //static const Color successColor = Color(0xFF10B981);
  static const Color dangerColor = Color(0xFFEF4444);
  //static const Color warningColor = Color(0xFFF59E0B);

  final List<Map<String, dynamic>> _categorias = [
    {
      'value': 'transporte',
      'label': 'Transporte',
      'icon': Icons.local_shipping,
      'color': Color(0xFFF59E0B)
    },
    {
      'value': 'mantenimiento',
      'label': 'Mantenimiento',
      'icon': Icons.build,
      'color': Color(0xFFEF4444)
    },
    {
      'value': 'reposicion',
      'label': 'Reposición',
      'icon': Icons.inventory,
      'color': Color(0xFF10B981)
    },
    {
      'value': 'servicios',
      'label': 'Servicios',
      'icon': Icons.miscellaneous_services,
      'color': Color(0xFF3B82F6)
    },
    {
      'value': 'otros',
      'label': 'Otros',
      'icon': Icons.category,
      'color': Color(0xFF6B7280)
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _gastos = await _finanzasService.getGastos(
        startDate: _fechaInicio,
        endDate: _fechaFin,
        tipo: _filtroCategoria,
        maquinaId: _filtroMaquina,
      );
    } catch (e) {
      setState(() {
        _error = 'Error al cargar gastos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setPeriodoRapido(String periodo) {
    setState(() {
      _periodoRapido = periodo;
      final now = DateTime.now();
      switch (periodo) {
        case 'HOY':
          _fechaInicio = DateTime(now.year, now.month, now.day);
          _fechaFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'SEMANA':
          _fechaInicio = now.subtract(const Duration(days: 7));
          _fechaFin = now;
          break;
        case 'MES':
          _fechaInicio = DateTime(now.year, now.month, 1);
          _fechaFin = now;
          break;
        case 'TRIMESTRE':
          _fechaInicio = now.subtract(const Duration(days: 90));
          _fechaFin = now;
          break;
        case 'ANIO':
          _fechaInicio = DateTime(now.year, 1, 1);
          _fechaFin = now;
          break;
      }
    });
    _cargarGastos();
  }

  Future<void> _seleccionarRangoPersonalizado() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fechaInicio, end: _fechaFin),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _periodoRapido = 'PERSONALIZADO';
        _fechaInicio = range.start;
        _fechaFin = range.end;
      });
      _cargarGastos();
    }
  }

  void _mostrarFiltrosAvanzados() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FiltrosAvanzadosSheet(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        categoria: _filtroCategoria,
        categorias: _categorias,
        onApply: (start, end, cat) {
          setState(() {
            _fechaInicio = start;
            _fechaFin = end;
            _filtroCategoria = cat;
            _periodoRapido = 'PERSONALIZADO';
          });
          _cargarGastos();
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _fechaInicio =
                DateTime(DateTime.now().year, DateTime.now().month, 1);
            _fechaFin = DateTime.now();
            _filtroCategoria = null;
            _periodoRapido = 'MES';
          });
          _cargarGastos();
          Navigator.pop(context);
        },
      ),
    );
  }

  String _formatPeso(double value) => '\$${_currencyFormat.format(value)}';
  double _calcularTotal() => _gastos.fold(0, (s, g) => s + g.valor);

  Future<void> _crearGasto() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _GastoFormDialog(
        categorias: _categorias,
        maquinaId: _filtroMaquina,
      ),
    );
    if (result == true) _cargarGastos();
  }

  Future<void> _eliminarGasto(Gasto gasto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
            '¿Eliminar "${gasto.descripcion}" por ${_formatPeso(gasto.valor)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _finanzasService.eliminarGasto(gasto.id);
      if (success)
        _cargarGastos();
      else
        setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _getCategoriaInfo(String categoria) {
    return _categorias.firstWhere(
      (c) => c['value'] == categoria,
      orElse: () => _categorias.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcularTotal();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return RefreshIndicator(
      onRefresh: _cargarGastos,
      color: primaryColor,
      child: Column(
        children: [
          // Filtros rápidos
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Período',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodoChip('Hoy', 'HOY', Icons.today),
                      const SizedBox(width: 8),
                      _buildPeriodoChip('Semana', 'SEMANA', Icons.date_range),
                      const SizedBox(width: 8),
                      _buildPeriodoChip('Mes', 'MES', Icons.calendar_month),
                      const SizedBox(width: 8),
                      _buildPeriodoChip(
                          'Trimestre', 'TRIMESTRE', Icons.calendar_view_month),
                      const SizedBox(width: 8),
                      _buildPeriodoChip('Año', 'ANIO', Icons.calendar_today),
                      const SizedBox(width: 8),
                      _buildPeriodoChip(
                          'Personalizado', 'PERSONALIZADO', Icons.edit_calendar,
                          isCustom: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Rango seleccionado y botón filtros
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              '${DateFormat('dd/MM/yy').format(_fechaInicio)} - ${DateFormat('dd/MM/yy').format(_fechaFin)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _mostrarFiltrosAvanzados,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _filtroCategoria != null
                              ? primaryColor.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _filtroCategoria != null
                                  ? primaryColor
                                  : Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.filter_list,
                                size: 16,
                                color: _filtroCategoria != null
                                    ? primaryColor
                                    : Colors.grey[700]),
                            const SizedBox(width: 4),
                            Text(
                              _filtroCategoria != null
                                  ? 'Filtros activos'
                                  : 'Filtros',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _filtroCategoria != null
                                      ? primaryColor
                                      : Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      onPressed: _crearGasto,
                      backgroundColor: primaryColor,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_filtroCategoria != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt, size: 12, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Categoría: ${_getCategoriaInfo(_filtroCategoria!)?['label']}',
                          style: TextStyle(fontSize: 11, color: primaryColor),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _filtroCategoria = null;
                            });
                            _cargarGastos();
                          },
                          child: const Icon(Icons.close,
                              size: 12, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tarjeta total (estilo Dashboard)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: dangerColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Gastos',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatPeso(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: dangerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de gastos
          Expanded(
            child: _gastos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No hay gastos registrados',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _crearGasto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          child: const Text('Registrar primer gasto'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _gastos.length,
                    itemBuilder: (context, index) {
                      final g = _gastos[index];
                      final categoriaInfo = _getCategoriaInfo(g.tipo);
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                categoriaInfo?['color'].withOpacity(0.2),
                            child: Icon(
                              categoriaInfo?['icon'],
                              color: categoriaInfo?['color'],
                              size: 20,
                            ),
                          ),
                          title: Text(
                            g.descripcion,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${_dateFormat.format(DateTime.parse(g.fecha))} • ${g.usuarioNombre}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: dangerColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatPeso(g.valor),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: dangerColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 20, color: Colors.red),
                                onPressed: () => _eliminarGasto(g),
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

  Widget _buildPeriodoChip(String label, String value, IconData icon,
      {bool isCustom = false}) {
    final isSelected = _periodoRapido == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => isCustom
            ? _seleccionarRangoPersonalizado()
            : _setPeriodoRapido(value),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: isSelected ? primaryColor : Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Diálogo para crear gasto
class _GastoFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> categorias;
  final int? maquinaId;

  const _GastoFormDialog({
    required this.categorias,
    this.maquinaId,
  });

  @override
  State<_GastoFormDialog> createState() => _GastoFormDialogState();
}

class _GastoFormDialogState extends State<_GastoFormDialog> {
  final FinanzasService _finanzasService = FinanzasService();
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _categoria = 'transporte';
  double _monto = 0;
  DateTime _fecha = DateTime.now();
  String _descripcion = '';
  int? _maquinaId;

  @override
  void initState() {
    super.initState();
    _maquinaId = widget.maquinaId;
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.categorias.map<DropdownMenuItem<String>>((c) {
      return DropdownMenuItem<String>(
        value: c['value'] as String,
        child: Row(
          children: [
            Icon(c['icon'], size: 18, color: c['color']),
            const SizedBox(width: 8),
            Text(c['label'] as String),
          ],
        ),
      );
    }).toList();

    return AlertDialog(
      title: const Text('Nuevo Gasto'),
      content: SizedBox(
        width: 350,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: items,
                  onChanged: (v) => setState(() => _categoria = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _montoController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _monto = double.tryParse(v) ?? 0,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingrese el monto' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Fecha'),
                  subtitle: Text(_fecha.toIso8601String().split('T')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _fecha = date);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (v) => _descripcion = v,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Ingrese una descripción'
                      : null,
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
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final Map<String, dynamic> data = {
              'tipo': _categoria,
              'descripcion': _descripcion,
              'valor': _monto,
              'fecha': _fecha.toIso8601String().split('T')[0],
            };
            if (_maquinaId != null) {
              data['maquina'] = _maquinaId as int;
            }
            try {
              await _finanzasService.crearGasto(data);
              if (mounted) Navigator.pop(context, true);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// Hoja de filtros avanzados
class _FiltrosAvanzadosSheet extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? categoria;
  final List<Map<String, dynamic>> categorias;
  final Function(DateTime, DateTime, String?) onApply;
  final VoidCallback onReset;

  const _FiltrosAvanzadosSheet({
    required this.fechaInicio,
    required this.fechaFin,
    required this.categoria,
    required this.categorias,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FiltrosAvanzadosSheet> createState() => _FiltrosAvanzadosSheetState();
}

class _FiltrosAvanzadosSheetState extends State<_FiltrosAvanzadosSheet> {
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  String? _categoria;

  @override
  void initState() {
    super.initState();
    _fechaInicio = widget.fechaInicio;
    _fechaFin = widget.fechaFin;
    _categoria = widget.categoria;
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      const DropdownMenuItem<String?>(
          value: null, child: Text('Todas las categorías')),
      ...widget.categorias.map<DropdownMenuItem<String>>((c) {
        return DropdownMenuItem<String>(
          value: c['value'] as String,
          child: Row(
            children: [
              Icon(c['icon'], size: 18, color: c['color']),
              const SizedBox(width: 8),
              Text(c['label'] as String),
            ],
          ),
        );
      }),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros Avanzados',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Rango de fechas'),
            subtitle: Text(
              '${_fechaInicio.toIso8601String().split('T')[0]} - ${_fechaFin.toIso8601String().split('T')[0]}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange:
                    DateTimeRange(start: _fechaInicio, end: _fechaFin),
              );
              if (range != null) {
                setState(() {
                  _fechaInicio = range.start;
                  _fechaFin = range.end;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _categoria,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
            items: items,
            onChanged: (v) => setState(() => _categoria = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReset,
                  child: const Text('Limpiar filtros'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      widget.onApply(_fechaInicio, _fechaFin, _categoria),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
