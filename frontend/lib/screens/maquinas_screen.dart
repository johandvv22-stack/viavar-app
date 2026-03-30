import "dart:async";
import 'package:url_launcher/url_launcher.dart';
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "../services/maquinas_service.dart";
import "../services/esp32_service.dart"; // AÑADIDO
import "../models/maquina.dart";
import "../models/esp32_estado.dart"; // AÑADIDO
import '../screens/admin/esp32_config_screen.dart';
//import '../services/operario_service.dart'; // NUEVO
import '../screens/operario/visita_detalle_screen.dart'; // NUEVO

class MaquinasScreen extends StatefulWidget {
  const MaquinasScreen({super.key});

  @override
  State<MaquinasScreen> createState() => _MaquinasScreenState();
}

class _MaquinasScreenState extends State<MaquinasScreen> {
  final MaquinasService _maquinasService = MaquinasService();
  final Esp32Service _esp32Service = Esp32Service(); // AÑADIDO
  List<Maquina> _maquinas = [];
  List<Maquina> _maquinasFiltradas = [];
  Map<int, Esp32Estado?> _estadosEsp32 = {}; // AÑADIDO
  bool _isLoading = false;
  bool _cargandoEstados = false; // AÑADIDO
  String? _error;
  String _searchQuery = "";
  String _estadoFiltro = "todos";
  Timer? _searchDebounce;

  final List<String> _estados = [
    "todos",
    "Activo",
    "Inactivo",
    "Mantenimiento"
  ];

  @override
  void initState() {
    super.initState();
    _loadMaquinas();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMaquinas() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final maquinas = await _maquinasService.getMaquinas();

      if (!mounted) return;

      setState(() {
        _maquinas = maquinas;
        _maquinasFiltradas = maquinas;
        _isLoading = false;
      });

      // Cargar estados ESP32 después de cargar máquinas
      _cargarEstadosEsp32();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // NUEVO: Cargar estados ESP32 para todas las máquinas
  Future<void> _cargarEstadosEsp32() async {
    if (_cargandoEstados) return;

    setState(() {
      _cargandoEstados = true;
    });

    try {
      final Map<int, Esp32Estado?> estados = {};

      for (var maquina in _maquinas) {
        try {
          final estado = await _esp32Service.getEstado(maquina.id);
          estados[maquina.id] = estado;
        } catch (e) {
          // Si hay error, dejar como null (sin ESP32)
          estados[maquina.id] = null;
        }
      }

      if (mounted) {
        setState(() {
          _estadosEsp32 = estados;
          _cargandoEstados = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoEstados = false;
        });
      }
    }
  }

  void _aplicarFiltros() {
    List<Maquina> filtradas = _maquinas;

    // Filtrar por estado
    if (_estadoFiltro != "todos") {
      filtradas = filtradas.where((m) {
        final estadoMaquina = m.estado.toLowerCase();
        final estadoFiltro = _estadoFiltro.toLowerCase();

        // Mapear "Activo" a "activa" y "Inactivo" a "inactiva" si es necesario
        if (estadoFiltro == "activo" &&
            (estadoMaquina == "activo" || estadoMaquina == "activa")) {
          return true;
        }
        if (estadoFiltro == "inactivo" &&
            (estadoMaquina == "inactivo" || estadoMaquina == "inactiva")) {
          return true;
        }
        if (estadoFiltro == "mantenimiento" &&
            estadoMaquina == "mantenimiento") {
          return true;
        }
        return false;
      }).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtradas = filtradas
          .where((m) =>
              m.nombre.toLowerCase().contains(query) ||
              m.codigo.toLowerCase().contains(query) ||
              m.ubicacion.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _maquinasFiltradas = filtradas;
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;

    // Debounce para no hacer muchas llamadas
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _aplicarFiltros();
    });
  }

  void _onEstadoFiltroChanged(String? value) {
    if (value != null) {
      setState(() {
        _estadoFiltro = value;
      });
      _aplicarFiltros();
    }
  }

  Future<void> _abrirEnMaps(Maquina maquina) async {
    final url = maquina.mapsUrl;

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay URL disponible para esta máquina"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Para web, abrir en nueva pestaña usando window.open
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir el mapa: $url';
      }

      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Abriendo Maps en nueva pestaña..."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print(" Error abriendo Maps: $e");

      // Mostrar mensaje alternativo con la URL para copiar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("No se pudo abrir Maps automáticamente"),
              const SizedBox(height: 4),
              Text(
                "URL: $url",
                style: const TextStyle(fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: "Copiar",
            onPressed: () {
              // Copiar al portapapeles
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("URL copiada al portapapeles"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // MODIFICADO: Ahora muestra menú con opciones incluyendo ESP32
  void _mostrarMenuOpciones(Maquina maquina) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('Ver detalles completos'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDetallesMaquina(maquina);
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.green),
                title: const Text('Abrir en Maps'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirEnMaps(maquina);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.rate_review_rounded, color: Colors.green),
                title: const Text('Iniciar Visita'),
                onTap: () {
                  Navigator.pop(context);
                  _iniciarVisita(maquina);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sensors, color: Colors.orange),
                title: const Text('Configurar ESP32'),
                subtitle: const Text('Estado, intervalo, forzar conteo'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Esp32ConfigScreen(maquina: maquina),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDetallesMaquina(Maquina maquina) {
    final estadoEsp = _estadosEsp32[maquina.id];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(maquina.nombre),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow("Código:", maquina.codigo),
                _buildInfoRow("Ubicación:", maquina.ubicacion),
                _buildInfoRow("Estado:", maquina.estado),
                _buildInfoRow("Porcentaje surtido:",
                    "${maquina.porcentajeSurtido.toStringAsFixed(1)}%"),
                _buildInfoRow(
                    "Ventas hoy:", "\$${maquina.ventasHoy.toStringAsFixed(0)}"),
                _buildInfoRow("Ganancia hoy:",
                    "\$${maquina.gananciaHoy.toStringAsFixed(0)}"),
                _buildInfoRow(
                    "Capacidad total:", "${maquina.capacidadTotal} productos"),
                _buildInfoRow("Fecha instalación:",
                    "${maquina.fechaInstalacion.day}/${maquina.fechaInstalacion.month}/${maquina.fechaInstalacion.year}"),

                const SizedBox(height: 16),

                if (maquina.tieneCoordenadas)
                  Text(
                    "Coordenadas: ${maquina.latitud!.toStringAsFixed(6)}, ${maquina.longitud!.toStringAsFixed(6)}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Información ESP32
                Text(
                  "ESP32",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 8),

                if (estadoEsp != null) ...[
                  _buildInfoRow("Estado:", estadoEsp.estadoTexto),
                  _buildInfoRow("Última conexión:",
                      _formatearFecha(estadoEsp.ultimaConexion)),
                  _buildInfoRow("Intervalo:",
                      "${estadoEsp.intervaloActual ~/ 60} minutos"),
                ] else ...[
                  const Text("Sin ESP32 configurada"),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
            if (estadoEsp != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Esp32ConfigScreen(maquina: maquina),
                    ),
                  );
                },
                child: const Text("Configurar ESP32"),
              ),
          ],
        );
      },
    );
  }

  void _iniciarVisita(Maquina maquina) async {
    // Crear un objeto MaquinaRuta para usar con VisitaDetalleScreen
    final maquinaRuta = MaquinaRuta(
      id: maquina.id,
      nombre: maquina.nombre,
      ubicacion: maquina.ubicacion,
      porcentajeSurtido: maquina.porcentajeSurtido,
      estado: maquina.estado,
      codigo: maquina.codigo,
      ultimaVisita: maquina.ultimaVisita,
    );

    // Navegar a la pantalla de visita (reutilizando la del operario)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitaDetalleScreen(maquina: maquinaRuta),
      ),
    );

    // Si la visita se completó, refrescar los datos de la máquina
    if (result == true) {
      _loadMaquinas();
    }
  }

  // NUEVO: Formatear fecha para mostrar
  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'Nunca';
    try {
      final datetime = DateTime.parse(fecha);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(datetime);

      if (diferencia.inMinutes < 1) {
        return 'Ahora';
      } else if (diferencia.inMinutes < 60) {
        return 'Hace ${diferencia.inMinutes} min';
      } else if (diferencia.inHours < 24) {
        return 'Hace ${diferencia.inHours} h';
      } else {
        return '${datetime.day}/${datetime.month}';
      }
    } catch (e) {
      return fecha;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // MODIFICADO: Ahora incluye indicador ESP32
  Widget _buildMaquinaCard(Maquina maquina) {
    final estadoEsp = _estadosEsp32[maquina.id];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Código: ${maquina.codigo}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Indicador ESP32 + Estado máquina
                Row(
                  children: [
                    if (estadoEsp != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: estadoEsp.estadoColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: estadoEsp.estadoColor),
                        ),
                        child: Icon(
                          estadoEsp.estadoIcon,
                          size: 18,
                          color: estadoEsp.estadoColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: maquina.estado == "activa" ||
                                maquina.estado == "activo"
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: maquina.estado == "activa" ||
                                  maquina.estado == "activo"
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(
                        maquina.estado.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: maquina.estado == "activa" ||
                                  maquina.estado == "activo"
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Información principal
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    maquina.ubicacion,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Métricas
            Row(
              children: [
                _buildMetricChip(
                  icon: Icons.percent,
                  label: "${maquina.porcentajeSurtido.toStringAsFixed(1)}%",
                  color: maquina.porcentajeSurtido < 30
                      ? Colors.red
                      : maquina.porcentajeSurtido < 70
                          ? Colors.orange
                          : Colors.green,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  icon: Icons.attach_money,
                  label: "\$${maquina.ventasHoy.toStringAsFixed(0)}",
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  icon: Icons.trending_up,
                  label: "\$${maquina.gananciaHoy.toStringAsFixed(0)}",
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barra de progreso de surtido
            LinearProgressIndicator(
              value: maquina.porcentajeSurtido / 100,
              backgroundColor: Colors.grey[200],
              color: maquina.porcentajeSurtido < 30
                  ? Colors.red
                  : maquina.porcentajeSurtido < 70
                      ? Colors.orange
                      : Colors.green,
              minHeight: 6,
            ),

            const SizedBox(height: 12),

            // Botones de acción - MODIFICADO: ahora un solo botón que abre menú
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostrarMenuOpciones(maquina),
                    icon: const Icon(Icons.more_horiz),
                    label: const Text("Opciones"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirEnMaps(maquina),
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text("Maps"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[800],
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

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Máquinas Dispensadoras",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.blue[900],
        actions: [
          // Indicador de carga de estados ESP32
          if (_cargandoEstados)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: _isLoading ? Colors.grey : Colors.white,
            onPressed: _loadMaquinas,
            tooltip: "Recargar máquinas",
          ),
        ],
      ),
      body: _isLoading && _maquinas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _maquinas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text("Error: $_error",
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMaquinas,
                        child: const Text("Reintentar"),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Barra de búsqueda y filtros
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Column(
                        children: [
                          // Barra de búsqueda
                          TextField(
                            decoration: InputDecoration(
                              hintText: "Buscar máquinas...",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: _onSearchChanged,
                          ),

                          const SizedBox(height: 12),

                          // Filtros
                          Row(
                            children: [
                              const Text(
                                "Filtrar por estado:",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _estadoFiltro,
                                  items: _estados.map((estado) {
                                    return DropdownMenuItem(
                                      value: estado,
                                      child: Text(
                                        estado == "todos"
                                            ? "Todos los estados"
                                            : estado,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _onEstadoFiltroChanged,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  isExpanded: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Contador de resultados
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          Text(
                            "${_maquinasFiltradas.length} máquina${_maquinasFiltradas.length != 1 ? 's' : ''} encontrada${_maquinasFiltradas.length != 1 ? 's' : ''}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          if (_maquinasFiltradas.length != _maquinas.length)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = "";
                                  _estadoFiltro = "todos";
                                  _maquinasFiltradas = _maquinas;
                                });
                              },
                              child: const Text("Limpiar filtros"),
                            ),
                        ],
                      ),
                    ),

                    // Lista de máquinas
                    Expanded(
                      child: _maquinasFiltradas.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_cafe,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    "No se encontraron máquinas",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Intenta con otros filtros de búsqueda",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMaquinas,
                              child: ListView.builder(
                                itemCount: _maquinasFiltradas.length,
                                itemBuilder: (context, index) {
                                  return _buildMaquinaCard(
                                      _maquinasFiltradas[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
