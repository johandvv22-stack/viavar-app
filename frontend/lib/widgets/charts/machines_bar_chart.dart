//VENTAS POR MAQUINA
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Modelo simple para datos de máquinas
class MaquinaChartData {
  final String nombre;
  final double ventas;
  final double ganancia;

  MaquinaChartData({
    required this.nombre,
    required this.ventas,
    required this.ganancia,
  });
}

class MachinesBarChart extends StatelessWidget {
  final List<MaquinaChartData> maquinasData;
  final bool animate;
  final String? title;

  const MachinesBarChart({
    super.key,
    required this.maquinasData,
    this.animate = true,
    this.title = "Ventas por Máquina",
  });

  @override
  Widget build(BuildContext context) {
    if (maquinasData.isEmpty) {
      return _buildEmptyChart(title ?? "Ventas por Máquina", context);
    }

    // Ordenar por ventas descendente y limitar a 5 para mejor visualización
    final sortedData = List<MaquinaChartData>.from(maquinasData);
    sortedData.sort((a, b) => b.ventas.compareTo(a.ventas));
    final displayData = sortedData.take(5).toList();

    final maxVentas = _getMaxVentas(displayData);
    final interval = _calculateInterval(maxVentas);

    return Container(
      width: double.infinity,
      height: 320, // ALTURA FIJA para evitar overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title ?? "Ventas por Máquina",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Subtítulo
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              "Top ${displayData.length} máquinas",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Gráfica - con altura fija
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxVentas * 1.25,
                minY: 0,
                barGroups: _generateBarGroups(displayData),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < displayData.length) {
                          final maquina = displayData[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SizedBox(
                              width: 55,
                              child: Text(
                                _abreviarNombre(maquina.nombre),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
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
                      reservedSize: 45,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _formatShortCurrency(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
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
                  horizontalInterval: interval,
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
                    fitInsideVertically: true,
                    fitInsideHorizontally: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final maquina = displayData[group.x.toInt()];
                      return BarTooltipItem(
                        "${maquina.nombre}\n",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: "\$${maquina.ventas.toStringAsFixed(0)}",
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

          const SizedBox(height: 8),

          // Resumen simplificado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${displayData.length} máquinas",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  _formatCurrency(
                      displayData.fold(0.0, (sum, m) => sum + m.ventas)),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<MaquinaChartData> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final maquina = entry.value;
      final color = _getBarColor(index);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: maquina.ventas,
            color: color,
            width: 20,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();
  }

  Color _getBarColor(int index) {
    const colors = [
      Color(0xFF2196F3), // Azul
      Color(0xFF4CAF50), // Verde
      Color(0xFFFF9800), // Naranja
      Color(0xFF9C27B0), // Púrpura
      Color(0xFF009688), // Teal
    ];
    return colors[index % colors.length];
  }

  double _getMaxVentas(List<MaquinaChartData> data) {
    if (data.isEmpty) return 1000;
    return data.map((m) => m.ventas).reduce((a, b) => a > b ? a : b);
  }

  double _calculateInterval(double maxVentas) {
    if (maxVentas <= 5000) return 1000;
    if (maxVentas <= 20000) return 5000;
    if (maxVentas <= 50000) return 10000;
    return 25000;
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '${value.toInt()}';
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${value.toInt()}';
    }
  }

  String _abreviarNombre(String nombre) {
    if (nombre.isEmpty) return 'Máquina';

    // Remover palabras comunes
    String abreviado = nombre
        .replaceAll('Máquina ', '')
        .replaceAll('Maquina ', '')
        .replaceAll('Oficina', 'Of.')
        .replaceAll('Recepción', 'Rec.')
        .replaceAll('Principal', 'Ppal');

    if (abreviado.length > 10) {
      return '${abreviado.substring(0, 8)}...';
    }
    return abreviado;
  }

  Widget _buildEmptyChart(String title, BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "Sin datos de ventas",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
