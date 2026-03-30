import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/esp32_service.dart';
import '../../models/maquina.dart';
import '../../models/esp32_estado.dart';

class Esp32ConfigScreen extends StatefulWidget {
  final Maquina maquina;

  const Esp32ConfigScreen({
    Key? key,
    required this.maquina,
  }) : super(key: key);

  @override
  State<Esp32ConfigScreen> createState() => _Esp32ConfigScreenState();
}

class _Esp32ConfigScreenState extends State<Esp32ConfigScreen>
    with SingleTickerProviderStateMixin {
  late Esp32Service _esp32Service;
  late TabController _tabController;

  Esp32Estado? _estadoMaestro;
  List<Esp32Slave> _slaves = [];
  List<Esp32Log> _logs = [];
  bool _isLoading = true;
  // ignore: unused_field
  bool _isSaving = false;
  int _intervaloSeleccionado = 900;
  String? _errorMessage;
  String? _filtroLogNivel;
  int? _filtroLogSlave;

  final List<Map<String, dynamic>> opcionesIntervalo = [
    {'valor': 300, 'texto': '5 minutos'},
    {'valor': 600, 'texto': '10 minutos'},
    {'valor': 900, 'texto': '15 minutos'},
    {'valor': 1800, 'texto': '30 minutos'},
    {'valor': 3600, 'texto': '1 hora'},
  ];

  final List<Map<String, dynamic>> comandosDisponibles = [
    {
      'comando': 'leer_todo',
      'texto': 'Leer todas las posiciones',
      'icon': Icons.sensors,
      'color': const Color(0xFF3B82F6)
    },
    {
      'comando': 'leer_bandeja',
      'texto': 'Leer bandeja completa',
      'icon': Icons.view_list,
      'color': const Color(0xFF10B981)
    },
    {
      'comando': 'leer_posicion',
      'texto': 'Leer posición específica',
      'icon': Icons.location_on,
      'color': const Color(0xFFF59E0B)
    },
    {
      'comando': 'calibrar',
      'texto': 'Calibrar sensores',
      'icon': Icons.tune,
      'color': const Color(0xFF8B5CF6)
    },
    {
      'comando': 'test',
      'texto': 'Prueba de hardware',
      'icon': Icons.science,
      'color': const Color(0xFF14B8A6)
    },
    {
      'comando': 'reiniciar',
      'texto': 'Reiniciar esclava',
      'icon': Icons.restart_alt,
      'color': const Color(0xFFEF4444)
    },
  ];

  @override
  void initState() {
    super.initState();
    _esp32Service = Esp32Service();
    _tabController = TabController(length: 3, vsync: this);
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
      _errorMessage = null;
    });

    try {
      final estado = await _esp32Service.getEstado(widget.maquina.id);
      final slaves = await _esp32Service.getSlaves(widget.maquina.id);
      final logs = await _esp32Service.getLogs(
        maquinaId: widget.maquina.id,
        nivel: _filtroLogNivel,
        slaveId: _filtroLogSlave,
        limit: 100,
      );

      setState(() {
        _estadoMaestro = estado;
        _slaves = slaves;
        _logs = logs;
        _intervaloSeleccionado = _estadoMaestro?.intervaloActual ?? 900;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarIntervalo() async {
    setState(() => _isSaving = true);
    try {
      await _esp32Service.configurarIntervalo(
        widget.maquina.id,
        _intervaloSeleccionado,
      );
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _forzarConteo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forzar conteo'),
        content: Text(
            '¿Ordenar a ${widget.maquina.nombre} realizar un conteo inmediato?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Forzar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await _esp32Service.forzarConteo(widget.maquina.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Comando enviado a la ESP32'),
              backgroundColor: Colors.orange),
        );
      }
      Future.delayed(const Duration(seconds: 2), _cargarDatos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _enviarComandoBandeja(
      Esp32Slave slave, Map<String, dynamic> comandoInfo) async {
    Map<String, dynamic>? parametros;

    if (comandoInfo['comando'] == 'leer_posicion') {
      final posicion = await _mostrarSelectorPosicion(slave);
      if (posicion == null) return;
      parametros = {'posicion': posicion};
    } else if (comandoInfo['comando'] == 'leer_bandeja') {
      parametros = {'bandeja': slave.posicion};
    } else if (comandoInfo['comando'] == 'calibrar') {
      parametros = {'bandeja': slave.posicion};
    } else if (comandoInfo['comando'] == 'test') {
      parametros = {'tipo': 'motor'};
    } else if (comandoInfo['comando'] == 'reiniciar') {
      parametros = {'bandeja': slave.posicion};
    }

    setState(() => _isSaving = true);
    try {
      await _esp32Service.enviarComando(
        slave.id,
        comandoInfo['comando'],
        parametros: parametros ?? {},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Comando "${comandoInfo['texto']}" enviado a bandeja ${slave.posicion}'),
            backgroundColor: Colors.green,
          ),
        );
      }
      Future.delayed(const Duration(seconds: 2), _cargarDatos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _enviarComandoBroadcast(String comando, String texto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(texto),
        content: Text(
            '¿Enviar comando a todas las bandejas de ${widget.maquina.nombre}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      final resultados = await _esp32Service.enviarComandoBroadcast(
        widget.maquina.id,
        comando,
      );

      final exitosos = resultados.where((r) => r['success'] == true).length;
      final fallidos = resultados.where((r) => r['success'] == false).length;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Comando "$texto" enviado: $exitosos exitosos, $fallidos fallidos'),
            backgroundColor: fallidos > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
      Future.delayed(const Duration(seconds: 2), _cargarDatos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _mostrarSelectorPosicion(Esp32Slave slave) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar posición - Bandeja ${slave.posicion}'),
        content: SizedBox(
          width: 200,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: slave.posiciones.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(slave.posiciones[index]),
                onTap: () => Navigator.pop(context, slave.posiciones[index]),
              );
            },
          ),
        ),
      ),
    );
  }

  void _mostrarFiltrosLogs() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtrar Logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _filtroLogNivel,
              decoration: const InputDecoration(
                  labelText: 'Nivel', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                const DropdownMenuItem(value: 'INFO', child: Text('Info')),
                const DropdownMenuItem(
                    value: 'WARNING', child: Text('Advertencia')),
                const DropdownMenuItem(value: 'ERROR', child: Text('Error')),
              ],
              onChanged: (value) => setState(() => _filtroLogNivel = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _filtroLogSlave,
              decoration: const InputDecoration(
                  labelText: 'Bandeja', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._slaves.map((slave) => DropdownMenuItem(
                    value: slave.id, child: Text('Bandeja ${slave.posicion}'))),
              ],
              onChanged: (value) => setState(() => _filtroLogSlave = value),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _filtroLogNivel = null;
                        _filtroLogSlave = null;
                      });
                      _cargarDatos();
                      Navigator.pop(context);
                    },
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _cargarDatos();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A)),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Nunca';
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'Hace unos segundos';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return DateFormat('dd/MM/yy HH:mm').format(fecha);
  }

  String _formatearFechaString(String? fechaStr) {
    if (fechaStr == null) return 'Nunca';
    try {
      final fecha = DateTime.parse(fechaStr);
      return _formatearFecha(fecha);
    } catch (e) {
      return fechaStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configuración ESP32'),
            Text(
              '${widget.maquina.codigo} - ${widget.maquina.nombre}',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1E3A8A),
          indicatorWeight: 3,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.sensors), text: 'Estado'),
            Tab(icon: Icon(Icons.grid_view), text: 'Bandejas'),
            Tab(icon: Icon(Icons.history), text: 'Logs'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEstadoTab(),
                    _buildBandejasTab(),
                    _buildLogsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Error al cargar estado',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMaestroCard(),
          const SizedBox(height: 16),
          _buildIntervaloCard(),
          const SizedBox(height: 16),
          _buildAccionesCard(),
        ],
      ),
    );
  }

  Widget _buildMaestroCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('ESP32 Maestro',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _estadoMaestro!.estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _estadoMaestro!.estadoColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_estadoMaestro!.estadoIcon,
                      color: _estadoMaestro!.estadoColor, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estadoMaestro!.estadoTexto,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _estadoMaestro!.estadoColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _estadoMaestro!.isOnline
                              ? 'Conectado'
                              : 'Desconectado',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (_estadoMaestro!.batchPendientes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${_estadoMaestro!.batchPendientes} pendientes',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              children: [
                _buildInfoItem(Icons.access_time, 'Última conexión',
                    _formatearFechaString(_estadoMaestro!.ultimaConexion)),
                _buildInfoItem(Icons.memory, 'Memoria',
                    '${_estadoMaestro!.memoriaOcupada} bytes'),
                _buildInfoItem(Icons.sd_storage, 'Batch pendientes',
                    _estadoMaestro!.batchPendientes.toString()),
                _buildInfoItem(Icons.update, 'Firmware',
                    _estadoMaestro!.firmwareVersion ?? 'v1.0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervaloCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Intervalo de lectura',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            DropdownButtonFormField<int>(
              value: _intervaloSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Frecuencia de conteo',
                border: OutlineInputBorder(),
              ),
              items: opcionesIntervalo.map<DropdownMenuItem<int>>((op) {
                return DropdownMenuItem<int>(
                  value: op['valor'] as int,
                  child: Text(op['texto'] as String),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _intervaloSeleccionado = value!),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardarIntervalo,
                icon: const Icon(Icons.save),
                label: const Text('Guardar configuración'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_arrow, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Acciones globales',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _forzarConteo,
                icon: const Icon(Icons.sensors),
                label: const Text('Forzar conteo ahora'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAccionChip(
                    'Leer todas las bandejas',
                    Icons.sensors,
                    () => _enviarComandoBroadcast(
                        'leer_todo', 'Leer todas las bandejas')),
                _buildAccionChip(
                    'Calibrar todas',
                    Icons.tune,
                    () =>
                        _enviarComandoBroadcast('calibrar', 'Calibrar todas')),
                _buildAccionChip('Test hardware', Icons.science,
                    () => _enviarComandoBroadcast('test', 'Test hardware')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionChip(String label, IconData icon, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onPressed: onPressed,
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildBandejasTab() {
    if (_slaves.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_off, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No hay bandejas configuradas para esta máquina'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _slaves.length,
      itemBuilder: (context, index) {
        final slave = _slaves[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: slave.estadoColor.withOpacity(0.2),
              child: Icon(slave.estadoIcon, color: slave.estadoColor),
            ),
            title: Row(
              children: [
                Text('Bandeja ${slave.posicion}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: slave.estadoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(slave.estadoTexto,
                      style: TextStyle(fontSize: 11, color: slave.estadoColor)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slave.codigoProducto != null)
                  Text('Producto: ${slave.codigoProducto}',
                      style: const TextStyle(fontSize: 12)),
                Text('Firmware: ${slave.firmwareVersion}',
                    style: const TextStyle(fontSize: 12)),
                Text(
                    'Última conexión: ${_formatearFecha(slave.ultimaConexion)}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            children: [
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Posiciones:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slave.posiciones
                          .map((pos) => Chip(
                              label: Text(pos),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Comandos:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: comandosDisponibles.map((cmd) {
                        return ElevatedButton.icon(
                          onPressed: () => _enviarComandoBandeja(slave, cmd),
                          icon: Icon(cmd['icon'], size: 18),
                          label: Text(cmd['texto']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (cmd['color'] as Color).withOpacity(0.1),
                            foregroundColor: cmd['color'],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        );
                      }).toList(),
                    ),
                    if (slave.ultimaLectura.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Última lectura:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: slave.ultimaLectura.entries.map((e) {
                            final valor = e.value;
                            final cantidad =
                                valor is int ? valor : (valor as num).toInt();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text('${e.key}: ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  Text('$cantidad unidades'),
                                  const Spacer(),
                                  SizedBox(
                                    width: 60,
                                    child: LinearProgressIndicator(
                                      value: cantidad / 20,
                                      backgroundColor: Colors.grey[200],
                                      color: cantidad >= 15
                                          ? Colors.green
                                          : cantidad >= 8
                                              ? Colors.orange
                                              : Colors.red,
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    if (_logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No hay logs registrados'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Barra de filtros
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _mostrarFiltrosLogs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _filtroLogNivel != null || _filtroLogSlave != null
                                ? 'Filtros activos'
                                : 'Filtrar logs',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_filtroLogNivel != null || _filtroLogSlave != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _filtroLogNivel = null;
                      _filtroLogSlave = null;
                    });
                    _cargarDatos();
                  },
                  tooltip: 'Limpiar filtros',
                ),
            ],
          ),
        ),
        // Lista de logs
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: log.nivelColor.withOpacity(0.2),
                    child: Icon(log.nivelIcon, color: log.nivelColor, size: 20),
                  ),
                  title: Text(log.mensaje,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yy HH:mm:ss').format(log.timestamp)}${log.slaveId != null ? ' • Bandeja ${_getPosicionBandeja(log.slaveId!)}' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: log.nivelColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      log.nivel,
                      style: TextStyle(
                          fontSize: 10,
                          color: log.nivelColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () => _mostrarDetalleLog(log),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDetalleLog(Esp32Log log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(log.nivelIcon, color: log.nivelColor),
            const SizedBox(width: 8),
            Text('Detalle del Log'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mensaje:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(log.mensaje),
              const SizedBox(height: 8),
              Text('Fecha:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp)),
              if (log.slaveId != null) ...[
                const SizedBox(height: 8),
                Text('Bandeja:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Bandeja ${_getPosicionBandeja(log.slaveId!)}'),
              ],
              if (log.datosExtra.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Datos adicionales:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: log.datosExtra.entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('${e.key}: ${e.value}'),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getPosicionBandeja(int slaveId) {
    final slave = _slaves.firstWhere(
      (s) => s.id == slaveId,
      orElse: () => Esp32Slave(
        id: 0,
        maquinaId: 0,
        posicion: '?',
        firmwareVersion: '',
        estado: '',
        distanciaMin: 0,
        distanciaMax: 0,
        posiciones: [],
        ultimaLectura: {},
      ),
    );
    return slave.posicion;
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
