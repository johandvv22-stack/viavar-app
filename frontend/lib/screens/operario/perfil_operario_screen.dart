import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/operario_service.dart';
import '../login_screen.dart'; // Asegúrate de importar

class PerfilOperarioScreen extends StatefulWidget {
  const PerfilOperarioScreen({super.key});

  @override
  State<PerfilOperarioScreen> createState() => _PerfilOperarioScreenState();
}

class _PerfilOperarioScreenState extends State<PerfilOperarioScreen> {
  final OperarioService _operarioService = OperarioService();
  Map<String, dynamic>? _resumen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    try {
      final resumen = await _operarioService.getResumenVisitas();
      setState(() {
        _resumen = resumen;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return ListView(
      children: [
        // Cabecera con foto de perfil
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.green[800],
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text(
                  user?.username.substring(0, 1).toUpperCase() ?? 'O',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.username ?? 'Operario',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Sin email',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // Estadísticas rápidas
        if (!_isLoading && _resumen != null)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Visitas',
                        _resumen!['total_visitas'].toString(),
                        Icons.history,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Completadas',
                        _resumen!['completadas'].toString(),
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const Divider(),

        // Opciones del perfil
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Información personal'),
          subtitle: const Text('Ver y editar tus datos'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función próximamente'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Historial de actividades'),
          subtitle: const Text('Todas tus acciones'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función próximamente'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Configuración'),
          subtitle: const Text('Preferencias de la app'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función próximamente'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Ayuda'),
          subtitle: const Text('Preguntas frecuentes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función próximamente'),
              ),
            );
          },
        ),
        const Divider(),

        // LOGOUT - AGREGADO
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(color: Colors.red),
          ),
          onTap: _cerrarSesion,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.green[800]),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
