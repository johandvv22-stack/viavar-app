import 'package:flutter/material.dart';
import '../../services/operario_service.dart';
import '../../services/maquinas_service.dart';
import '../../models/maquina.dart';

class ReportarProblemaScreen extends StatefulWidget {
  const ReportarProblemaScreen({super.key});

  @override
  State<ReportarProblemaScreen> createState() => _ReportarProblemaScreenState();
}

class _ReportarProblemaScreenState extends State<ReportarProblemaScreen> {
  final OperarioService _operarioService = OperarioService();
  final MaquinasService _maquinasService = MaquinasService();

  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();

  int? _maquinaIdSeleccionada;
  List<Maquina> _maquinas = [];
  bool _cargandoMaquinas = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarMaquinas();
  }

  @override
  void dispose() {
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
      });
    }
  }

  Future<void> _enviarReporte() async {
    if (!_formKey.currentState!.validate()) return;
    if (_maquinaIdSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una máquina'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _operarioService.reportarProblema(
        maquinaId: _maquinaIdSeleccionada!,
        descripcion: _descripcionController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Problema reportado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Error al enviar reporte');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Problema'),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: _cargandoMaquinas
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Selección de máquina
                  DropdownButtonFormField<int?>(
                    value: _maquinaIdSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Máquina con problema',
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
                          child: Text('${maquina.nombre} (${maquina.codigo})'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _maquinaIdSeleccionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Seleccione una máquina';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Descripción del problema
                  TextFormField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción del problema',
                      hintText:
                          'Ej: La máquina no entrega producto, pantalla en blanco, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Describa el problema';
                      }
                      if (value.length < 10) {
                        return 'Sea más específico (mínimo 10 caracteres)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Botón de enviar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _enviarReporte,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
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
                            'ENVIAR REPORTE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
