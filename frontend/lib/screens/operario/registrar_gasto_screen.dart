import 'package:flutter/material.dart';
import '../../services/operario_service.dart';
import '../../services/maquinas_service.dart';
import '../../models/maquina.dart';

class RegistrarGastoScreen extends StatefulWidget {
  const RegistrarGastoScreen({super.key});

  @override
  State<RegistrarGastoScreen> createState() => _RegistrarGastoScreenState();
}

class _RegistrarGastoScreenState extends State<RegistrarGastoScreen> {
  final OperarioService _operarioService = OperarioService();
  final MaquinasService _maquinasService = MaquinasService();

  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _valorController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _categoriaSeleccionada = 'transporte'; // Cambiado a valores del modelo
  int? _maquinaIdSeleccionada;
  List<Maquina> _maquinas = [];
  bool _isLoading = false;
  bool _cargandoMaquinas = true;
  String? _errorMessage;

  // Categorías que coinciden con el modelo TIPOS
  final List<Map<String, dynamic>> _categorias = [
    {
      'valor': 'transporte',
      'texto': 'Transporte',
      'icono': Icons.directions_bus
    },
    {'valor': 'operario', 'texto': 'Operario', 'icono': Icons.person},
    {'valor': 'mantenimiento', 'texto': 'Mantenimiento', 'icono': Icons.build},
    {'valor': 'arrendamiento', 'texto': 'Arrendamiento', 'icono': Icons.home},
    {'valor': 'reposicion', 'texto': 'Reposición', 'icono': Icons.inventory},
    {'valor': 'servicios', 'texto': 'Servicios', 'icono': Icons.electric_bolt},
    {'valor': 'otros', 'texto': 'Otros', 'icono': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _cargarMaquinas();
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _valorController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarMaquinas() async {
    try {
      final maquinas = await _maquinasService.getMaquinas();
      setState(() {
        _maquinas = maquinas
            .where((m) => m.estado == 'activa' || m.estado == 'activo')
            .toList();
        _cargandoMaquinas = false;
      });
    } catch (e) {
      setState(() {
        _cargandoMaquinas = false;
        _errorMessage = 'Error al cargar máquinas: $e';
      });
    }
  }

  Future<void> _registrarGasto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final valor = double.parse(_valorController.text);

      print('📦 Intentando registrar gasto:');
      print('   Tipo: $_categoriaSeleccionada');
      print(
          '   Descripción: ${_descripcionController.text.isNotEmpty ? _descripcionController.text : _conceptoController.text}');
      print('   Valor: $valor');
      print('   Máquina ID: $_maquinaIdSeleccionada');

      final resultado = await _operarioService.registrarGasto(
        concepto: _conceptoController.text,
        valor: valor,
        categoria: _categoriaSeleccionada,
        maquinaId: _maquinaIdSeleccionada,
        descripcion: _descripcionController.text.isNotEmpty
            ? _descripcionController.text
            : null,
      );

      print('✅ Gasto registrado: $resultado');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error registrando gasto: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Gasto'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: _cargandoMaquinas
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Título
                    const Text(
                      'Tipo de gasto',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown de categorías (más fácil que chips)
                    DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(_categorias.firstWhere(
                          (c) => c['valor'] == _categoriaSeleccionada,
                          orElse: () => _categorias.last,
                        )['icono']),
                      ),
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria['valor'],
                          child: Row(
                            children: [
                              Icon(categoria['icono'],
                                  size: 20, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Text(categoria['texto']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _categoriaSeleccionada = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Concepto (se usará como respaldo si no hay descripción)
                    TextFormField(
                      controller: _conceptoController,
                      decoration: InputDecoration(
                        labelText: 'Concepto',
                        hintText: 'Ej: Gasolina, Almuerzo, Repuesto...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un concepto';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Valor
                    TextFormField(
                      controller: _valorController,
                      decoration: InputDecoration(
                        labelText: 'Valor',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese el valor';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Ingrese un número válido';
                        }
                        if (double.parse(value) <= 0) {
                          return 'El valor debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Máquina (opcional)
                    DropdownButtonFormField<int?>(
                      value: _maquinaIdSeleccionada,
                      decoration: InputDecoration(
                        labelText: 'Máquina (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            const Icon(Icons.settings_applications_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('-- Seleccionar máquina --'),
                        ),
                        ..._maquinas.map((maquina) {
                          return DropdownMenuItem<int?>(
                            value: maquina.id,
                            child:
                                Text('${maquina.nombre} (${maquina.codigo})'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _maquinaIdSeleccionada = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Descripción (opcional)
                    TextFormField(
                      controller: _descripcionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Detalles adicionales...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // Botón registrar
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registrarGasto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'REGISTRAR GASTO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
