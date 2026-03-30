import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../models/finanzas_modelos.dart';

class GraficaEvolucion extends StatelessWidget {
  final List<EvolucionMensual> data;

  const GraficaEvolucion({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No hay datos disponibles'),
      );
    }

    // Tomar solo últimos 12 meses con datos
    final mesesConDatos =
        data.where((d) => d.ventas > 0 || d.gastos > 0).toList();
    final mostrarData = mesesConDatos.length >= 6 ? mesesConDatos : data;

    final maxValue = [
      ...mostrarData.map((d) => d.ventas),
      ...mostrarData.map((d) => d.gastos),
    ].reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < mostrarData.length) {
                  return Text(
                    mostrarData[index].mes,
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: mostrarData.length - 1,
        minY: 0,
        maxY: maxValue * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: mostrarData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.ventas);
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: mostrarData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.gastos);
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
