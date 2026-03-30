import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import 'package:intl/intl.dart';
import '../../services/maquinas_service.dart';
import '../../models/maquina.dart';
import '../../models/dashboard_data.dart';

// Widgets de gráficas
import '../../widgets/charts/sales_line_chart.dart'
    show SalesLineChart, VentaChartData;
import '../../widgets/charts/machines_bar_chart.dart';
import '../../widgets/charts/top_products_bar_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final MaquinasService _maquinasService = MaquinasService();

  // ========== ESTADOS ==========
  bool _isLoading = true;
  String? _error;
  DashboardData? _dashboardData;
  List<Maquina> _maquinas = [];
  List<VentaDiaria> _ventasPorDia = [];
  List<MaquinaVentas> _ventasPorMaquina = [];
  List<TopProductoChartData> _productosTop = [];

  // ========== FECHAS ==========
  DateTime _startDate = DateTime.now()
      .subtract(const Duration(days: 7)); // Cambiado a 7 días por defecto
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = '7d';

  // ========== COLORES CORPORATIVOS ==========
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF2563EB);
  static const Color accentColor = Color(0xFF7C3AED);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ========== CARGA DE DATOS ==========
  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print(
          '🟢 Cargando dashboard desde ${_startDate.toIso8601String()} hasta ${_endDate.toIso8601String()}');

      final results = await Future.wait([
        _dashboardService.getDashboardData(
          startDate: _startDate,
          endDate: _endDate,
        ),
        _dashboardService.getVentasPorDia(
          startDate: _startDate,
          endDate: _endDate,
        ),
        _dashboardService.getVentasPorMaquina(
          startDate: _startDate,
          endDate: _endDate,
        ),
        _dashboardService.getVentasPorProducto(
          startDate: _startDate,
          endDate: _endDate,
        ),
        _maquinasService.getMaquinas(),
      ]);

      if (!mounted) return;

      setState(() {
        _dashboardData = results[0] as DashboardData;
        _ventasPorDia = results[1] as List<VentaDiaria>;
        _ventasPorMaquina = results[2] as List<MaquinaVentas>;
        _productosTop = results[3] as List<TopProductoChartData>;
        _maquinas = results[4] as List<Maquina>;
        _isLoading = false;
      });

      print('✅ Dashboard cargado correctamente');
      print('📊 Ventas por día: ${_ventasPorDia.length} días');
      print('📊 Ventas por máquina: ${_ventasPorMaquina.length} máquinas');
      print('📊 Productos top: ${_productosTop.length} productos');
    } catch (e) {
      print('❌ Error cargando dashboard: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ========== CAMBIO DE FECHAS ==========
  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();

      switch (period) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case '7d':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case '30d':
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
        case '90d':
          _startDate = now.subtract(const Duration(days: 90));
          _endDate = now;
          break;
        case 'custom':
          _showDatePicker();
          return;
      }
      print('📅 Período cambiado a: $_selectedPeriod');
    });
    _loadAllData();
  }

  Future<void> _showDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
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
      _loadAllData();
    }
  }

  // ========== CONVERSIONES ==========
  List<VentaChartData> _convertToVentaChartData(List<VentaDiaria> ventas) {
    return ventas.map((venta) {
      return VentaChartData(
        fecha: venta.fecha,
        venta: venta.venta,
        label: '\$${venta.venta.toStringAsFixed(0)}',
      );
    }).toList();
  }

  List<MaquinaChartData> _convertToMaquinaChartData(
      List<MaquinaVentas> ventas) {
    return ventas.map((venta) {
      return MaquinaChartData(
        nombre: venta.nombre,
        ventas: venta.ventas,
        ganancia: venta.ganancia,
      );
    }).toList();
  }

  // ========== FUNCIONES DE CÁLCULO ==========
  double _calcularTrend(double actual, double anterior) {
    if (anterior == 0) return 0;
    return ((actual - anterior) / anterior) * 100;
  }

  // ========== BUILD PRINCIPAL ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingScreen()
          : _error != null
              ? _buildErrorScreen()
              : _dashboardData == null
                  ? _buildEmptyState(
                      'No hay datos disponibles', Icons.dashboard)
                  : _buildDashboardContent(),
    );
  }

  // ========== APP BAR ==========
  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dashboard_customize, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Dashboard Viavar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      backgroundColor: primaryColor,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _loadAllData,
          tooltip: 'Actualizar datos',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildFilterBar(),
      ),
    );
  }

  // ========== FILTROS ==========
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Período',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Hoy', 'today', Icons.today),
                const SizedBox(width: 8),
                _buildFilterChip('7 días', '7d', Icons.date_range),
                const SizedBox(width: 8),
                _buildFilterChip('30 días', '30d', Icons.calendar_month),
                const SizedBox(width: 8),
                _buildFilterChip('90 días', '90d', Icons.calendar_view_month),
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
                          color: Colors.grey[700],
                        ),
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
              color: isSelected ? primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
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

  // ========== SECCIÓN DE KPIS ==========
  Widget _buildKpiSection() {
    if (_dashboardData == null) return const SizedBox();

    final data = _dashboardData!;
    final totalVentasPeriodo =
        _ventasPorDia.fold<double>(0, (sum, item) => sum + item.venta);
    final maquinasCriticas =
        _maquinas.where((m) => m.porcentajeSurtido < 30).length;

    // Calcular ventas de ayer
    final ayer = DateTime.now().subtract(const Duration(days: 1));

    double ventasAyer = 0;
    try {
      final ventaAyer = _ventasPorDia.firstWhere(
        (v) =>
            v.fecha.year == ayer.year &&
            v.fecha.month == ayer.month &&
            v.fecha.day == ayer.day,
      );
      ventasAyer = ventaAyer.venta;
    } catch (e) {
      ventasAyer = 0;
    }

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width < 800 ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildEnhancedKpiCard(
          title: 'Ventas Hoy',
          value: _formatPeso(data.resumenHoy.ventas),
          icon: Icons.trending_up,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          subtitle: '${data.resumenHoy.cantidad} unidades',
          trend: _calcularTrend(data.resumenHoy.ventas, ventasAyer),
        ),
        _buildEnhancedKpiCard(
          title: 'Período',
          value: _formatPeso(totalVentasPeriodo),
          icon: Icons.calendar_month,
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          subtitle:
              'Promedio ${_formatPeso(_ventasPorDia.isNotEmpty ? totalVentasPeriodo / _ventasPorDia.length : 0)}/día',
        ),
        _buildEnhancedKpiCard(
          title: 'Máquinas',
          value: '${data.maquinasActivas}',
          icon: Icons.coffee_maker,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          subtitle: '${_ventasPorMaquina.length} con ventas',
        ),
        _buildEnhancedKpiCard(
          title: 'Stock Crítico',
          value: '$maquinasCriticas',
          icon: Icons.warning_amber,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          subtitle: 'Requieren visita',
          showAlert: maquinasCriticas > 0,
        ),
      ],
    );
  }

  Widget _buildEnhancedKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required String subtitle,
    double? trend,
    bool showAlert = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 16),
                    ),
                    const Spacer(),
                    if (showAlert)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.priority_high,
                            size: 12, color: dangerColor),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (trend != null && trend != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: trend >= 0
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trend >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${trend.abs().toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== SECCIÓN DE VENTAS ==========
  Widget _buildSalesSection() {
    if (_ventasPorDia.isEmpty) {
      return _buildEmptyChart('No hay datos de ventas en este período');
    }

    final totalVentas =
        _ventasPorDia.fold<double>(0, (sum, item) => sum + item.venta);
    final mejorDia = _ventasPorDia.reduce((a, b) => a.venta > b.venta ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
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
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.show_chart, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Análisis de Ventas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_ventasPorDia.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: successColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Mejor día: ${DateFormat('dd/MM').format(mejorDia.fecha)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: _ventasPorDia.isNotEmpty
                ? SalesLineChart(
                    ventasData: _convertToVentaChartData(_ventasPorDia),
                    title: '',
                  )
                : _buildEmptyState('No hay datos de ventas', Icons.show_chart),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSalesStat(
                label: 'Total Período',
                value: _formatPeso(totalVentas),
                icon: Icons.attach_money,
                color: primaryColor,
              ),
              _buildSalesStat(
                label: 'Promedio Diario',
                value: _formatPeso(_ventasPorDia.isNotEmpty
                    ? totalVentas / _ventasPorDia.length
                    : 0),
                icon: Icons.calculate,
                color: successColor,
              ),
              _buildSalesStat(
                label: 'Días con Ventas',
                value: '${_ventasPorDia.length}',
                icon: Icons.calendar_today,
                color: accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ========== SECCIÓN DE PRODUCTOS ==========
  Widget _buildProductsSection() {
    if (_productosTop.isEmpty) {
      return _buildEmptyState('No hay datos de productos', Icons.shopping_bag);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
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
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.stars, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Top Productos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_productosTop.length} productos',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: TopProductsBarChart(
              productosData: _productosTop,
              title: '',
            ),
          ),
          const SizedBox(height: 16),
          ..._productosTop.take(5).map((producto) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        producto.nombre,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${_formatPeso(producto.ventas)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: successColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ========== SECCIÓN DE MÁQUINAS ==========
  Widget _buildMachinesSection() {
    if (_ventasPorMaquina.isEmpty) {
      return _buildEmptyState('No hay datos de máquinas', Icons.pie_chart);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: _buildMachinesChart(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: _buildMachinesCritical(),
        ),
      ],
    );
  }

  Widget _buildMachinesChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
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
                  color: secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.pie_chart, color: secondaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ventas por Máquina',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: _ventasPorMaquina.isNotEmpty
                ? MachinesBarChart(
                    maquinasData: _convertToMaquinaChartData(_ventasPorMaquina),
                    title: '',
                  )
                : _buildEmptyState('No hay datos de máquinas', Icons.pie_chart),
          ),
        ],
      ),
    );
  }

  Widget _buildMachinesCritical() {
    if (_maquinas.isEmpty) {
      return _buildEmptyState('Cargando máquinas...', Icons.local_cafe);
    }

    final maquinasCriticas = _maquinas
        .where((m) => m.porcentajeSurtido < 30)
        .toList()
      ..sort((a, b) => a.porcentajeSurtido.compareTo(b.porcentajeSurtido));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
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
                  color: dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning, color: dangerColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Stock Crítico',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (maquinasCriticas.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${maquinasCriticas.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: dangerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (maquinasCriticas.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 40, color: successColor),
                  const SizedBox(height: 8),
                  Text(
                    'Todas las máquinas están bien',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ...maquinasCriticas
                .take(5)
                .map((maquina) => _buildCriticalMachineItem(maquina)),
          if (maquinasCriticas.length > 5) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '+ ${maquinasCriticas.length - 5} máquinas más',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCriticalMachineItem(Maquina maquina) {
    Color color = maquina.porcentajeSurtido < 10
        ? dangerColor
        : maquina.porcentajeSurtido < 20
            ? warningColor
            : Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.coffee_maker, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maquina.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (maquina.porcentajeSurtido / 100)
                                .clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${maquina.porcentajeSurtido.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== DASHBOARD CONTENIDO ==========
  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // SECCIÓN 1: KPIS
                _buildKpiSection(),
                const SizedBox(height: 24),

                // SECCIÓN 2: GRÁFICA DE VENTAS
                _buildSalesSection(),
                const SizedBox(height: 24),

                // SECCIÓN 3: TOP PRODUCTOS
                _buildProductsSection(),
                const SizedBox(height: 24),

                // SECCIÓN 4: MÁQUINAS
                _buildMachinesSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ========== ESTADOS DE UI ==========
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando dashboard...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: dangerColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Error desconocido',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ========== UTILIDADES ==========
  String _formatPeso(double number) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }
}
