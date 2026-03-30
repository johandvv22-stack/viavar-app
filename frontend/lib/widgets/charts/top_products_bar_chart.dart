import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Modelo para datos de productos top
class TopProductoChartData {
  final String nombre;
  final double ventas;
  final double ganancia;
  final int cantidad;
  final String categoria;

  TopProductoChartData({
    required this.nombre,
    required this.ventas,
    required this.ganancia,
    required this.cantidad,
    required this.categoria,
  });
}

class TopProductsBarChart extends StatelessWidget {
  final List<TopProductoChartData> productosData;
  final bool animate;
  final String? title;

  const TopProductsBarChart({
    super.key,
    required this.productosData,
    this.animate = true,
    this.title = "Productos Más Vendidos",
  });

  @override
  Widget build(BuildContext context) {
    if (productosData.isEmpty) {
      return _buildEmptyChart(title ?? "Productos Más Vendidos");
    }

    // Ordenar por ventas descendente y tomar top 6 (menos productos para mejor visualización)
    final topProductos = (List<TopProductoChartData>.from(productosData)
          ..sort((a, b) => b.ventas.compareTo(a.ventas)))
        .take(6)
        .toList();

    final maxVentas = _getMaxVentas(topProductos);
    final interval = _calculateInterval(maxVentas);

    return Container(
      width: double.infinity,
      height: 380, // ALTURA FIJA
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
              title ?? "Productos Más Vendidos",
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
              "Top ${topProductos.length} productos",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Gráfica - BARRAS HORIZONTALES
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxVentas * 1.25,
                minY: 0,
                barGroups: _generateBarGroups(topProductos),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 90, // MÁS ESPACIO para nombres largos
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topProductos.length) {
                          final producto = topProductos[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _abreviarNombre(producto.nombre),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: false,
                  verticalInterval: interval,
                  getDrawingVerticalLine: (value) {
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
                      final producto = topProductos[group.x.toInt()];
                      return BarTooltipItem(
                        "${producto.nombre}\n",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: "\$${producto.ventas.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          TextSpan(
                            text: "\n${producto.cantidad} unid.",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
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

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<TopProductoChartData> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final producto = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: producto.ventas,
            color: _getCategoryColor(producto.categoria),
            width: 20,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();
  }

  Color _getCategoryColor(String categoria) {
    final categoryMap = {
      "Snack": const Color(0xFFFF9800), // Naranja
      "Bebida": const Color(0xFF2196F3), // Azul
      "Café": const Color(0xFF795548), // Café
      "Dulce": const Color(0xFF9C27B0), // Púrpura
      "paquete_grande": const Color(0xFF4CAF50), // Verde
      "paquete_pequeno": const Color(0xFF8BC34A), // Verde claro
      "liquido_grande": const Color(0xFF03A9F4), // Azul claro
      "liquido_pequeno": const Color(0xFF00BCD4), // Cyan
    };

    return categoryMap[categoria] ?? Colors.grey;
  }

  double _getMaxVentas(List<TopProductoChartData> data) {
    if (data.isEmpty) return 1000;
    return data.map((p) => p.ventas).reduce((a, b) => a > b ? a : b);
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
    if (nombre.isEmpty) return 'Producto';

    // Para nombres muy largos, tomar primeras palabras
    final parts = nombre.split(' ');
    if (parts.length > 2) {
      return '${parts[0]} ${parts[1].substring(0, 1)}.';
    }
    if (nombre.length > 15) {
      return '${nombre.substring(0, 12)}...';
    }
    return nombre;
  }

  Widget _buildEmptyChart(String title) {
    return Container(
      height: 380,
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
                  Icon(Icons.inventory_2,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    "Sin datos de productos",
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
