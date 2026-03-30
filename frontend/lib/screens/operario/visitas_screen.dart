import 'package:flutter/material.dart';
import '../../services/operario_service.dart';
import '../../models/operario_models.dart';
//import '../../screens/operario/visita_detalle_screen.dart';

class VisitasScreen extends StatefulWidget {
  const VisitasScreen({super.key});

  @override
  State<VisitasScreen> createState() => _VisitasScreenState();
}

class _VisitasScreenState extends State<VisitasScreen>
    with SingleTickerProviderStateMixin {
  final OperarioService _operarioService = OperarioService();
  late TabController _tabController;

  List<VisitaHistorial> _visitas = [];
  Map<String, dynamic>? _resumen;
  bool _isLoading = true;
  String? _error;

  final List<String> _estados = [
    'todas',
    'completada',
    'en_curso',
    'cancelada'
  ];
  String _estadoSeleccionado = 'todas';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cargar resumen y visitas en paralelo
      final results = await Future.wait([
        _operarioService.getResumenVisitas(),
        _operarioService.getHistorialVisitas(
            estado:
                _estadoSeleccionado == 'todas' ? null : _estadoSeleccionado),
      ]);

      setState(() {
        _resumen = results[0] as Map<String, dynamic>;
        _visitas = results[1] as List<VisitaHistorial>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarVisitasPorEstado(String estado) async {
    setState(() {
      _estadoSeleccionado = estado;
      _isLoading = true;
    });

    try {
      final visitas = await _operarioService.getHistorialVisitas(
          estado: estado == 'todas' ? null : estado);

      setState(() {
        _visitas = visitas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[250],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'RESUMEN', icon: Icon(Icons.pie_chart)),
            Tab(text: 'HISTORIAL', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: _isLoading && _visitas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDatos,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResumenTab(),
                    _buildHistorialTab(),
                  ],
                ),
    );
  }

  Widget _buildResumenTab() {
    if (_resumen == null) return const Center(child: Text('No hay datos'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tarjetas de estadísticas
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total Visitas',
                _resumen!['total_visitas'].toString(),
                Icons.history,
                Colors.blue,
              ),
              _buildStatCard(
                'Completadas',
                _resumen!['completadas'].toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'En Curso',
                _resumen!['en_curso'].toString(),
                Icons.play_circle,
                Colors.orange,
              ),
              _buildStatCard(
                'Canceladas',
                _resumen!['canceladas'].toString(),
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Última visita
          if (_resumen!['ultima_visita'] != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Última Visita',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _formatearFecha(_resumen!['ultima_visita']['fecha']),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _resumen!['ultima_visita']['maquina'] ??
                                'Desconocida',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Botón para recargar
          OutlinedButton.icon(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar datos'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialTab() {
    return Column(
      children: [
        // Filtro por estado
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[50],
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _estados.map((estado) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(estado.toUpperCase()),
                    selected: _estadoSeleccionado == estado,
                    onSelected: (selected) {
                      _cargarVisitasPorEstado(estado);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green[800],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Lista de visitas
        Expanded(
          child: _visitas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay visitas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Las visitas que realices aparecerán aquí',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _cargarVisitasPorEstado(_estadoSeleccionado),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _visitas.length,
                    itemBuilder: (context, index) {
                      final visita = _visitas[index];
                      return _buildVisitaCard(visita);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVisitaCard(VisitaHistorial visita) {
    Color estadoColor;
    IconData estadoIcon;

    switch (visita.estado) {
      case 'completada':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'en_curso':
        estadoColor = Colors.orange;
        estadoIcon = Icons.play_circle;
        break;
      case 'cancelada':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          // TODO: Navegar al detalle de la visita
        },
        leading: CircleAvatar(
          backgroundColor: estadoColor.withOpacity(0.1),
          child: Icon(estadoIcon, color: estadoColor),
        ),
        title: Text(visita.maquinaNombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${visita.productosSurtidos} productos surtidos'),
            if (visita.ventasGeneradas > 0)
              Text('\$${visita.ventasGeneradas.toStringAsFixed(0)} en ventas'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${visita.fecha.day}/${visita.fecha.month}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${visita.fecha.hour}:${visita.fecha.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatearFecha(String? fechaStr) {
    if (fechaStr == null) return 'Desconocida';
    try {
      final fecha = DateTime.parse(fechaStr);
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } catch (e) {
      return fechaStr;
    }
  }
}
