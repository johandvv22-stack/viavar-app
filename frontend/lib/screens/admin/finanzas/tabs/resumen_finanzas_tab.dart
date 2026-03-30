import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/finanzas_service.dart';
import '../../../../models/finanzas_modelos.dart';

class ResumenFinanzasTab extends StatefulWidget {
  const ResumenFinanzasTab({super.key});

  @override
  State<ResumenFinanzasTab> createState() => _ResumenFinanzasTabState();
}

class _ResumenFinanzasTabState extends State<ResumenFinanzasTab> {
  final FinanzasService _finanzasService = FinanzasService();

  bool _isLoading = true;
  String? _error;

  // Datos financieros (basados en CIERRES y GASTOS)
  List<CierreMensual> _cierres = [];
  List<Gasto> _gastos = [];
  List<EvolucionMensual> _evolucion = [];
  ResumenGastos? _resumenGastos;
  TopFacturacion? _topFacturacion;

  // Filtros
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'MES';

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obtener años disponibles para evolución
      final todosCierres = await _finanzasService.getCierres();
      final aniosSet = <int>{};
      for (var cierre in todosCierres) {
        aniosSet.add(cierre.anio);
      }
      //final aniosDisponibles = aniosSet.toList()..sort();

      // Cargar evolución de cierres (últimos 12 meses)
      final evolucion = await _finanzasService.getEvolucionMensual();

      // Filtrar cierres por período seleccionado
      final cierresFiltrados = _filtrarCierresPorPeriodo(todosCierres);

      // Filtrar gastos por período seleccionado
      final gastosFiltrados = await _finanzasService.getGastos(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Calcular resumen de gastos por categoría
      final resumenGastos = await _finanzasService.getResumenGastos(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Calcular top facturación basado en CIERRES del período
      final topFacturacion = _calcularTopFacturacion(cierresFiltrados);

      setState(() {
        _cierres = cierresFiltrados;
        _gastos = gastosFiltrados;
        _evolucion = evolucion;
        _resumenGastos = resumenGastos;
        _topFacturacion = topFacturacion;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando resumen: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CierreMensual> _filtrarCierresPorPeriodo(List<CierreMensual> cierres) {
    return cierres.where((c) {
      final fechaCierre = DateTime(c.anio, c.mes, 1);
      return fechaCierre
              .isAfter(_startDate.subtract(const Duration(days: 1))) &&
          fechaCierre.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
  }

  TopFacturacion _calcularTopFacturacion(List<CierreMensual> cierres) {
    final Map<int, Map<String, dynamic>> maquinasMap = {};

    for (var cierre in cierres) {
      if (!maquinasMap.containsKey(cierre.maquinaId)) {
        maquinasMap[cierre.maquinaId] = {
          'id': cierre.maquinaId,
          'codigo': cierre.maquinaCodigo,
          'nombre': cierre.maquinaNombre,
          'ventas_totales': 0.0,
          'ganancias_totales': 0.0,
          'unidades_vendidas': 0,
        };
      }
      maquinasMap[cierre.maquinaId]!['ventas_totales'] += cierre.ventasTotales;
      maquinasMap[cierre.maquinaId]!['ganancias_totales'] +=
          cierre.gananciaNeta;
    }

    final totalGeneral = cierres.fold(0.0, (sum, c) => sum + c.ventasTotales);

    final topMaquinas = maquinasMap.values.map((m) {
      final porcentaje =
          totalGeneral > 0 ? (m['ventas_totales'] / totalGeneral) * 100 : 0;
      return MaquinaTopFacturacion(
        id: m['id'],
        codigo: m['codigo'],
        nombre: m['nombre'],
        ventasTotales: m['ventas_totales'],
        gananciasTotales: m['ganancias_totales'],
        unidadesVendidas: m['unidades_vendidas'],
        porcentaje: porcentaje,
      );
    }).toList()
      ..sort((a, b) => b.ventasTotales.compareTo(a.ventasTotales));

    return TopFacturacion(
      totalGeneral: totalGeneral,
      topMaquinas: topMaquinas,
      periodo: Periodo(
          fechaInicio: _startDate.toIso8601String().split('T')[0],
          fechaFin: _endDate.toIso8601String().split('T')[0]),
    );
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();

      switch (period) {
        case 'HOY':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'MES':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'TRIMESTRE':
          _startDate = now.subtract(const Duration(days: 90));
          _endDate = now;
          break;
        case 'SEMESTRE':
          _startDate = now.subtract(const Duration(days: 180));
          _endDate = now;
          break;
        case 'ANIO':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
        case 'custom':
          _showDatePicker();
          return;
      }
    });
    _cargarDatos();
  }

  Future<void> _showDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'custom';
      });
      _cargarDatos();
    }
  }

  String _formatPeso(double number) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    // KPIs basados en CIERRES y GASTOS
    final totalIngresos = _cierres.fold(0.0, (s, c) => s + c.ventasTotales);
    final totalGastos = _gastos.fold(0.0, (s, g) => s + g.valor);
    final utilidad = totalIngresos - totalGastos;
    final margen =
        totalIngresos > 0 ? ((utilidad / totalIngresos) * 100).toDouble() : 0.0;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros
            _buildFilterBar(),
            const SizedBox(height: 16),

            // KPIs
            _buildKpiSection(totalIngresos, totalGastos, utilidad, margen),
            const SizedBox(height: 24),

            // Evolución Mensual (basada en CIERRES)
            _buildEvolucionSection(),
            const SizedBox(height: 24),

            // Ingresos por Máquina (basado en CIERRES)
            _buildIngresosPorMaquinaSection(),
            const SizedBox(height: 24),

            // Gastos por Categoría
            _buildGastosCategoriaSection(),
            const SizedBox(height: 24),

            // Evolución de Gastos
            _buildGastosTiempoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Período',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Hoy', 'HOY', Icons.today),
                const SizedBox(width: 8),
                _buildFilterChip('Mes', 'MES', Icons.calendar_month),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Trimestre', 'TRIMESTRE', Icons.calendar_view_month),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Semestre', 'SEMESTRE', Icons.calendar_view_month),
                const SizedBox(width: 8),
                _buildFilterChip('Año', 'ANIO', Icons.calendar_today),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'Personalizado', 'custom', Icons.edit_calendar),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedPeriod == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onPeriodChanged(value),
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

  Widget _buildKpiSection(
      double ingresos, double gastos, double utilidad, double margen) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width < 800 ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildKpiCard(
            'Ingresos',
            _formatPeso(ingresos),
            Icons.trending_up,
            const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)])),
        _buildKpiCard(
            'Gastos',
            _formatPeso(gastos),
            Icons.trending_down,
            const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)])),
        _buildKpiCard(
            'Utilidad',
            _formatPeso(utilidad),
            Icons.account_balance,
            utilidad >= 0
                ? const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)])
                : const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)])),
        _buildKpiCard(
            'Margen',
            '${margen.toStringAsFixed(1)}%',
            Icons.percent,
            const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])),
      ],
    );
  }

  Widget _buildKpiCard(
      String title, String value, IconData icon, Gradient gradient) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolucionSection() {
    if (_evolucion.isEmpty) {
      return _buildEmptyCard(
          'No hay datos de evolución mensual', Icons.timeline);
    }

    final mostrarData =
        _evolucion.where((d) => d.ventas > 0 || d.gastos > 0).toList();
    final maxValue = [
      ...mostrarData.map((d) => d.ventas),
      ...mostrarData.map((d) => d.gastos),
    ].reduce((a, b) => a > b ? a : b).toDouble();

    return _buildCard(
      title: 'Evolución Mensual (Cierres vs Gastos)',
      icon: Icons.timeline,
      iconColor: primaryColor,
      child: SizedBox(
        height: 280,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) => Text(
                      '\$${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < mostrarData.length) {
                      return Text(mostrarData[index].mes,
                          style: const TextStyle(fontSize: 10));
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            minX: 0,
            maxX: mostrarData.length - 1,
            minY: 0,
            maxY: maxValue * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: mostrarData
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.ventas))
                    .toList(),
                isCurved: true,
                color: successColor,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                    show: true, color: successColor.withOpacity(0.1)),
              ),
              LineChartBarData(
                spots: mostrarData
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.gastos))
                    .toList(),
                isCurved: true,
                color: dangerColor,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                    show: true, color: dangerColor.withOpacity(0.1)),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.white,
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                        '\$${s.y.toStringAsFixed(0)}',
                        const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold)))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIngresosPorMaquinaSection() {
    final maquinas = _topFacturacion?.topMaquinas ?? [];
    if (maquinas.isEmpty) {
      return _buildEmptyCard(
          'No hay datos de cierres por máquina', Icons.coffee_maker);
    }

    final totalGeneral = _topFacturacion?.totalGeneral ?? 0;

    return _buildCard(
      title: 'Ingresos por Máquina (Cierres)',
      icon: Icons.bar_chart,
      iconColor: successColor,
      child: Column(
        children: maquinas.take(5).map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                          child: Text('${maquinas.indexOf(m) + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(m.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis)),
                    Text(_formatPeso(m.ventasTotales),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: successColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: m.ventasTotales / totalGeneral,
                          backgroundColor: Colors.grey[200],
                          color: successColor,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        '${((m.ventasTotales / totalGeneral) * 100).toStringAsFixed(1)}%',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGastosCategoriaSection() {
    final categorias = _resumenGastos?.categorias ?? [];
    if (categorias.isEmpty) {
      return _buildEmptyCard('No hay gastos registrados', Icons.pie_chart);
    }

    return _buildCard(
      title: 'Gastos por Categoría',
      icon: Icons.pie_chart,
      iconColor: warningColor,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: categorias
                    .map((c) => PieChartSectionData(
                          value: c.total,
                          title: '${c.porcentaje.toStringAsFixed(0)}%',
                          color: _getColorFromHex(c.color),
                          radius: 70,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ))
                    .toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categorias
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getColorFromHex(c.color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _getColorFromHex(c.color).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: _getColorFromHex(c.color),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(c.categoriaNombre,
                              style: const TextStyle(fontSize: 12)),
                          Text(' (${c.porcentaje.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Gastos:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text(_formatPeso(_resumenGastos?.totalGeneral ?? 0),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: dangerColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGastosTiempoSection() {
    if (_gastos.isEmpty) {
      return _buildEmptyCard(
          'No hay gastos registrados en este período', Icons.money_off);
    }

    final Map<String, double> gastosPorFecha = {};
    for (var gasto in _gastos) {
      gastosPorFecha[gasto.fecha] =
          (gastosPorFecha[gasto.fecha] ?? 0) + gasto.valor;
    }

    final fechasOrdenadas = gastosPorFecha.keys.toList()..sort();
    final maxValue =
        gastosPorFecha.values.reduce((a, b) => a > b ? a : b).toDouble();

    return _buildCard(
      title: 'Evolución de Gastos en el Tiempo',
      icon: Icons.trending_down,
      iconColor: dangerColor,
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) => Text(
                      '\$${(value / 1000).toStringAsFixed(0)}k',
                      style: const TextStyle(fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < fechasOrdenadas.length) {
                      return Text(
                          DateFormat('dd/MM')
                              .format(DateTime.parse(fechasOrdenadas[index])),
                          style: const TextStyle(fontSize: 9));
                    }
                    return const Text('');
                  },
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            minX: 0,
            maxX: fechasOrdenadas.length - 1,
            minY: 0,
            maxY: maxValue * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: fechasOrdenadas
                    .asMap()
                    .entries
                    .map((e) =>
                        FlSpot(e.key.toDouble(), gastosPorFecha[e.value]!))
                    .toList(),
                isCurved: true,
                color: dangerColor,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                    show: true, color: dangerColor.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse(hexColor, radix: 16));
  }
}
