import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/operario_service.dart';
import '../../models/maquina.dart';
import 'visita_detalle_screen.dart';

class RutaScreen extends StatefulWidget {
  const RutaScreen({super.key});

  @override
  State<RutaScreen> createState() => _RutaScreenState();
}

class _RutaScreenState extends State<RutaScreen> {
  final OperarioService _operarioService = OperarioService();
  List<MaquinaRuta> _maquinas = [];
  bool _isLoading = true;
  String? _error;
  String _filtro = 'todas'; // 'todas', 'pendientes', 'completadas'

  @override
  void initState() {
    super.initState();
    _cargarRuta();
  }

  Future<void> _cargarRuta() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final maquinas = await _operarioService.getRuta();
      setState(() {
        _maquinas = maquinas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirEnMaps(MaquinaRuta maquina) async {
    final url = maquina.mapsUrl;

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Abriendo Maps..."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Copiar al portapapeles si no se puede abrir
        await Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("URL copiada al portapapeles: ${maquina.ubicacion}"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("URL copiada al portapapeles: ${maquina.ubicacion}"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _iniciarVisita(MaquinaRuta maquina) async {
    if (!maquina.activa) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('No se puede iniciar visita en máquina ${maquina.estado}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print(
        '🟢 Intentando iniciar visita para máquina: ${maquina.id} - ${maquina.nombre}');

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitaDetalleScreen(maquina: maquina),
        ),
      );

      if (result == true) {
        _cargarRuta();
      }
    } catch (e) {
      print('❌ Error al navegar a visita: $e');
    }
  }

  List<MaquinaRuta> get _maquinasFiltradas {
    switch (_filtro) {
      case 'pendientes':
        return _maquinas.where((m) => m.necesitaVisita).toList();
      case 'completadas':
        return _maquinas.where((m) => !m.necesitaVisita).toList();
      default:
        return _maquinas;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarRuta,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_maquinas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              '¡Todo está al día!',
              style: TextStyle(fontSize: 20, color: Colors.green[800]),
            ),
            const SizedBox(height: 8),
            const Text('No hay máquinas asignadas'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarRuta,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[50],
          child: Row(
            children: [
              const Text(
                'Mostrar:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'todas',
                      label: Text('Todas'),
                      icon: Icon(Icons.list),
                    ),
                    ButtonSegment(
                      value: 'pendientes',
                      label: Text('Pendientes'),
                      icon: Icon(Icons.priority_high),
                    ),
                    ButtonSegment(
                      value: 'completadas',
                      label: Text('Completadas'),
                      icon: Icon(Icons.check),
                    ),
                  ],
                  selected: {_filtro},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _filtro = selection.first;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // Contador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              Text(
                '${_maquinasFiltradas.length} máquina${_maquinasFiltradas.length != 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '${_maquinas.where((m) => m.necesitaVisita).length} pendientes',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarRuta,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _maquinasFiltradas.length,
              itemBuilder: (context, index) {
                final maquina = _maquinasFiltradas[index];
                return _buildMaquinaCard(maquina);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaquinaCard(MaquinaRuta maquina) {
    final necesitaVisita = maquina.necesitaVisita;
    final stockColor = necesitaVisita ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: necesitaVisita ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: necesitaVisita
            ? BorderSide(color: Colors.orange[400]!, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con nombre, estado y prioridad
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maquina.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${maquina.codigo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: maquina.activa ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: maquina.activa ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    maquina.activa ? 'ACTIVA' : 'INACTIVA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          maquina.activa ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
                if (necesitaVisita) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[400]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.priority_high,
                            size: 12, color: Colors.orange[800]),
                        const SizedBox(width: 4),
                        Text(
                          'URGENTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Ubicación
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    maquina.ubicacion,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Porcentaje de stock con barra
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock disponible',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${maquina.porcentajeSurtido.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maquina.porcentajeSurtido / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Última visita
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  maquina.ultimaVisita != null
                      ? 'Última visita: ${_formatearFecha(maquina.ultimaVisita)}'
                      : 'Sin visitas previas',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirEnMaps(maquina),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Cómo llegar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[800],
                      side: BorderSide(color: Colors.blue[200]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        maquina.activa ? () => _iniciarVisita(maquina) : null,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Iniciar visita'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          maquina.activa ? Colors.green[700] : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String? fechaStr) {
    if (fechaStr == null) return 'Desconocida';
    try {
      final fecha = DateTime.parse(fechaStr);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fecha);

      if (diferencia.inDays == 0) {
        return 'Hoy';
      } else if (diferencia.inDays == 1) {
        return 'Ayer';
      } else if (diferencia.inDays < 7) {
        return 'Hace ${diferencia.inDays} días';
      } else {
        return '${fecha.day}/${fecha.month}';
      }
    } catch (e) {
      return fechaStr;
    }
  }
}
