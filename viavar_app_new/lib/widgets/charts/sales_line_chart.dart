//TENDENCIA DE VENTAS
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Modelo simple para datos de ventas
class VentaChartData {
  final DateTime fecha;
  final double venta;
  final String? label;

  VentaChartData({
    required this.fecha,
    required this.venta,
    this.label,
  });
}

class SalesLineChart extends StatelessWidget {
  final List<VentaChartData> ventasData;
  final bool animate;
  final String? title;

  const SalesLineChart({
    super.key,
    required this.ventasData,
    this.animate = true,
    this.title = "Ventas por Día",
  });

  @override
  Widget build(BuildContext context) {
    if (ventasData.isEmpty) {
      return _buildEmptyChart(title ?? "Ventas por Día");
    }

    final maxVenta =
        ventasData.map((d) => d.venta).fold(0.0, (a, b) => a > b ? a : b);
    //final minVenta = 0;
    ventasData.map((d) => d.venta).fold(maxVenta, (a, b) => a < b ? a : b);
    final interval = _calculateInterval(maxVenta);

    return Container(
      width: double.infinity,
      height: 280, // ALTURA FIJA
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
              title ?? "Ventas por Día",
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
              "${ventasData.length} días",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Gráfica
          Expanded(
            child: LineChart(
              LineChartData(
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
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < ventasData.length) {
                          // Mostrar solo algunos labels para no saturar
                          if (ventasData.length > 7) {
                            if (index % 3 != 0 &&
                                index != ventasData.length - 1) {
                              return const Text('');
                            }
                          }
                          final data = ventasData[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatDate(data.fecha),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
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
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    left: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSpots(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue,
                        );
                      },
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxVenta * 1.25,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade800,
                    fitInsideVertically: true,
                    fitInsideHorizontally: true,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final data = ventasData[spot.x.toInt()];
                        return LineTooltipItem(
                          '${_formatDate(data.fecha)}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: '\$${data.venta.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Resumen
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
                  "Total período",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  _formatCurrency(
                      ventasData.fold(0.0, (sum, d) => sum + d.venta)),
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

  List<FlSpot> _generateSpots() {
    return ventasData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index.toDouble(), data.venta);
    }).toList();
  }

  double _calculateInterval(double maxVenta) {
    if (maxVenta <= 5000) return 1000;
    if (maxVenta <= 20000) return 5000;
    if (maxVenta <= 50000) return 10000;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  Widget _buildEmptyChart(String title) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 40, color: Colors.grey.shade300),
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
          ),
        ],
      ),
    );
  }
}
