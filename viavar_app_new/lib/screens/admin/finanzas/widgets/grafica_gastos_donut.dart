import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../models/finanzas_modelos.dart';

class GraficaGastosDonut extends StatelessWidget {
  final List<CategoriaGasto> categorias;

  const GraficaGastosDonut({super.key, required this.categorias});

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) {
      return const Center(
        child: Text('No hay gastos registrados'),
      );
    }

    return PieChart(
      PieChartData(
        sections: categorias.map((categoria) {
          return PieChartSectionData(
            value: categoria.total,
            title: '${categoria.porcentaje.toStringAsFixed(0)}%',
            color: _getColorFromHex(categoria.color),
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
