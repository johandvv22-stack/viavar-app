import 'package:flutter/material.dart';
import 'ruta_screen.dart';
import 'visitas_screen.dart';
import 'productos_consulta_screen.dart';
import 'registrar_screen.dart';
import 'perfil_operario_screen.dart';

class OperarioMainScreen extends StatefulWidget {
  const OperarioMainScreen({super.key});

  @override
  State<OperarioMainScreen> createState() => _OperarioMainScreenState();
}

class _OperarioMainScreenState extends State<OperarioMainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;
  late final List<String> _titles;

  @override
  void initState() {
    super.initState();
    print('🟢 ===== OPERARIO MAIN SCREEN INIT =====');
    print('🟢 OperarioMainScreen - initState');

    _screens = [
      const RutaScreen(),
      const VisitasScreen(),
      const ProductosConsultaScreen(),
      const RegistrarScreen(),
      const PerfilOperarioScreen(),
    ];

    _titles = const [
      'Mi Ruta',
      'Mis Visitas',
      'Productos',
      'Registrar',
      'Perfil',
    ];

    print('🟢 Pantallas creadas: ${_screens.length}');
  }

  void _onItemTapped(int index) {
    print('🟢 Cambiando a pestaña: ${_titles[index]} (índice: $index)');
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
        '🟢 OperarioMainScreen - build, pestaña actual: $_selectedIndex (${_titles[_selectedIndex]})');

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Ruta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Visitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Registrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
