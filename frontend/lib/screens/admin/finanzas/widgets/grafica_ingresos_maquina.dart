import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../models/cierre.dart';
import 'package:intl/intl.dart';

class GraficaIngresosMaquina extends StatefulWidget {
  final List<Cierre> cierres;
  final int mes;
  final int anio;

  const GraficaIngresosMaquina({
    super.key,
    required this.cierres,
    required this.mes,
    required this.anio,
  });

  @override
  State<GraficaIngresosMaquina> createState() => _GraficaIngresosMaquinaState();
}

class _GraficaIngresosMaquinaState extends State<GraficaIngresosMaquina> {
  List<String> _selectedMaquinas = [];
  List<Cierre> _filteredCierres = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredCierres = widget.cierres;
    _selectedMaquinas = widget.cierres.map((c) => c.maquinaNombre).toList();
  }

  @override
  void didUpdateWidget(GraficaIngresosMaquina oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cierres != widget.cierres) {
      _filteredCierres = widget.cierres;
      _selectedMaquinas = widget.cierres.map((c) => c.maquinaNombre).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cierresOrdenados = List<Cierre>.from(_filteredCierres)
      ..sort((a, b) => b.ventasTotales.compareTo(a.ventasTotales));

    final cierresFiltrados = cierresOrdenados
        .where((c) => _selectedMaquinas.contains(c.maquinaNombre))
        .take(8)
        .toList();

    final maxVentas = cierresFiltrados.isNotEmpty
        ? cierresFiltrados
            .map((c) => c.ventasTotales)
            .reduce((a, b) => a > b ? a : b)
        : 1000;

    return Column(
      children: [
        // FILTRO DE MÁQUINAS
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.blue[900]),
                  const SizedBox(width: 10),
                  const Text(
                    'Filtrar máquinas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _toggleAllMaquinas,
                    child: Text(
                      _selectedMaquinas.length == widget.cierres.length
                          ? 'Deseleccionar todas'
                          : 'Seleccionar todas',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar máquina...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView(
                  children: widget.cierres
                      .where((c) =>
                          c.maquinaNombre.toLowerCase().contains(_searchQuery))
                      .map((cierre) {
                    final isSelected =
                        _selectedMaquinas.contains(cierre.maquinaNombre);
                    return CheckboxListTile(
                      title: Text(
                        cierre.maquinaNombre,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: isSelected,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedMaquinas.add(cierre.maquinaNombre);
                          } else {
                            _selectedMaquinas.remove(cierre.maquinaNombre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // GRÁFICA
        if (cierresFiltrados.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text(
                  'No hay datos para mostrar',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 233,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVentas * 1.2,
                minY: 0,
                barGroups: _generateBarGroups(cierresFiltrados),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < cierresFiltrados.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 60,
                              child: Text(
                                _abreviarNombre(
                                    cierresFiltrados[index].maquinaNombre),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _formatCurrency(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 0.8,
                      dashArray: [3, 3],
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    left: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade800,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final cierre = cierresFiltrados[group.x.toInt()];
                      return BarTooltipItem(
                        '${cierre.maquinaNombre}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: '${_formatPeso(cierre.ventasTotales)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<Cierre> cierres) {
    return cierres.asMap().entries.map((entry) {
      final index = entry.key;
      final cierre = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: cierre.ventasTotales,
            color: Colors.amber,
            width: 16,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();
  }

  void _toggleAllMaquinas() {
    setState(() {
      if (_selectedMaquinas.length == widget.cierres.length) {
        _selectedMaquinas = [];
      } else {
        _selectedMaquinas = widget.cierres.map((c) => c.maquinaNombre).toList();
      }
    });
  }

  String _abreviarNombre(String nombre) {
    if (nombre.isEmpty) return 'Máquina';
    if (nombre.length > 15) {
      return '${nombre.substring(0, 12)}...';
    }
    return nombre;
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '${value.toInt()}';
    }
  }

  String _formatPeso(double value) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(value);
  }
}
