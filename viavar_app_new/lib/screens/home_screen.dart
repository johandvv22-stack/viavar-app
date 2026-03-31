import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../services/auth_service.dart";
//import "../screens/login_screen.dart";
import "../screens/admin/admin_dashboard_screen.dart";
import "../screens/maquinas_screen.dart";
import "../screens/admin/productos_screen.dart";
import "../screens/operario_route_screen.dart";
import "../screens/admin/finanzas/finanzas_screen.dart";
import "../screens/admin/perfil_screen.dart";
import '../services/notification_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

Future<void> _checkNotifications() async {
  await NotificationManager().checkAndNotify();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Pantallas para ADMIN
  final List<Widget> _adminScreens = [
    const AdminDashboardScreen(),
    const MaquinasScreen(),
    const ProductosScreen(),
    const FinanzasScreen(),
    const PerfilScreen(),
  ];

  // Pantallas para OPERARIO
  final List<Widget> _operarioScreens = [
    const OperarioRouteScreen(),
    _buildPlaceholder(icon: Icons.work, title: "Visitas"),
    _buildPlaceholder(icon: Icons.inventory, title: "Productos"),
    _buildPlaceholder(icon: Icons.person, title: "Perfil"),
  ];

  // Títulos para el BottomNavigationBar
  final List<String> _adminTitles = [
    "Inicio",
    "Máquinas",
    "Productos",
    "Finanzas",
    "Perfil"
  ];

  final List<String> _operarioTitles = [
    "Ruta",
    "Visitas",
    "Productos",
    "Perfil"
  ];

  // Íconos para ADMIN
  final List<IconData> _adminIcons = [
    Icons.dashboard_outlined,
    Icons.settings_applications_rounded,
    Icons.inventory_2_outlined,
    Icons.attach_money_outlined,
    Icons.person_outlined,
  ];

  // Íconos para OPERARIO
  final List<IconData> _operarioIcons = [
    Icons.route_outlined,
    Icons.work_outline,
    Icons.inventory_2_outlined,
    Icons.person_outline,
  ];

  static Widget _buildPlaceholder(
      {required IconData icon, required String title}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            "Pantalla en desarrollo",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isAdmin = user?.isAdmin ?? false;

    final currentScreens = isAdmin ? _adminScreens : _operarioScreens;
    final currentTitles = isAdmin ? _adminTitles : _operarioTitles;
    final currentIcons = isAdmin ? _adminIcons : _operarioIcons;

    return Scaffold(
      // SIN APPBAR - eliminado completamente
      body: currentScreens[_selectedIndex],

      // Solo BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: isAdmin ? Colors.blue[800] : Colors.green[800],
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        items: List.generate(currentIcons.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(currentIcons[index]),
            label: currentTitles[index],
          );
        }),
      ),
    );
  }
}
