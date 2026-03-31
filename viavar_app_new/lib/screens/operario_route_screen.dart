import "package:flutter/material.dart";

class OperarioRouteScreen extends StatelessWidget {
  const OperarioRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ruta Operario"),
        backgroundColor: Colors.green[800],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text("PANEL DE OPERARIO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Gestión de visitas a máquinas", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 30),
            Text("Funciones disponibles:", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text(" Ver ruta de máquinas"),
            Text(" Registrar visitas"),
            Text(" Actualizar precios"),
            Text(" Registrar gastos"),
          ],
        ),
      ),
    );
  }
}
