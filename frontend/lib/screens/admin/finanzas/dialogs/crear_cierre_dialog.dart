import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/finanzas_service.dart';

class CrearCierreDialog extends StatefulWidget {
  final List<dynamic> maquinas;
  final dynamic cierre;

  const CrearCierreDialog({
    super.key,
    required this.maquinas,
    this.cierre,
  });

  @override
  State<CrearCierreDialog> createState() => _CrearCierreDialogState();
}

class _CrearCierreDialogState extends State<CrearCierreDialog> {
  final FinanzasService _finanzasService = FinanzasService();
  final _formKey = GlobalKey<FormState>();

  int? _selectedMaquinaId;
  int _selectedMes = DateTime.now().month;
  int _selectedAnio = DateTime.now().year;
  double _ventas = 0;
  double _gastos = 0;
  String _observaciones = '';

  final _ventasController = TextEditingController();
  final _gastosController = TextEditingController();
  final _observacionesController = TextEditingController();

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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMaquinaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una máquina')),
      );
      return;
    }

    final data = {
      'maquina': _selectedMaquinaId,
      'mes': _selectedMes,
      'año': _selectedAnio,
      'ventas_totales': _ventas,
      'gastos_totales': _gastos,
      'ganancia_neta': _ventas - _gastos,
      'observaciones': _observaciones,
    };

    try {
      if (widget.cierre != null) {
        await _finanzasService.actualizarCierre(widget.cierre!.id, data);
      } else {
        await _finanzasService.crearCierre(data);
      }
      if (mounted) Navigator.pop(context, true);
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
        value: maquina['id'] as int,
        child: Text(maquina['nombre'] as String),
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
                            child: Text(
                                DateFormat('MMMM').format(DateTime(2000, mes))),
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
                  onChanged: (value) {
                    _ventas = double.tryParse(value) ?? 0;
                  },
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
                  onChanged: (value) {
                    _gastos = double.tryParse(value) ?? 0;
                  },
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
          child: Text(widget.cierre == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
