class DashboardData {
  final double ventasTotales;
  final double gananciaTotal;
  final int unidadesVendidas;
  final int maquinasActivas;
  final int stockCritico;
  final int totalMaquinas;
  final List<VentaPorDia> ventasPorDia;
  final List<TopProducto> topProductos;
  final List<VentaPorMaquina> ventasPorMaquina;
  final ResumenHoy resumenHoy;
  final ResumenMes resumenMes;

  DashboardData({
    required this.ventasTotales,
    required this.gananciaTotal,
    required this.unidadesVendidas,
    required this.maquinasActivas,
    required this.stockCritico,
    required this.totalMaquinas,
    required this.ventasPorDia,
    required this.topProductos,
    required this.ventasPorMaquina,
    required this.resumenHoy,
    required this.resumenMes,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      ventasTotales: (json['ventas_totales'] ?? 0).toDouble(),
      gananciaTotal: (json['ganancia_total'] ?? 0).toDouble(),
      unidadesVendidas: json['unidades_vendidas'] ?? 0,
      maquinasActivas: json['maquinas_activas'] ?? 0,
      stockCritico: json['stock_critico'] ?? 0,
      totalMaquinas: json['total_maquinas'] ?? 0,
      ventasPorDia: (json['ventas_por_dia'] as List? ?? [])
          .map((v) => VentaPorDia.fromJson(v))
          .toList(),
      topProductos: (json['top_productos'] as List? ?? [])
          .map((p) => TopProducto.fromJson(p))
          .toList(),
      ventasPorMaquina: (json['ventas_por_maquina'] as List? ?? [])
          .map((m) => VentaPorMaquina.fromJson(m))
          .toList(),
      resumenHoy: ResumenHoy.fromJson(json['resumen_hoy'] ?? {}),
      resumenMes: ResumenMes.fromJson(json['resumen_mes'] ?? {}),
    );
  }
}

class VentaPorDia {
  final String fecha;
  final double total;
  final double ganancia;

  VentaPorDia({
    required this.fecha,
    required this.total,
    required this.ganancia,
  });

  factory VentaPorDia.fromJson(Map<String, dynamic> json) {
    return VentaPorDia(
      fecha: json['fecha'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      ganancia: (json['ganancia'] ?? 0).toDouble(),
    );
  }
}

class TopProducto {
  final String nombre;
  final int cantidad;
  final double ventas;

  TopProducto({
    required this.nombre,
    required this.cantidad,
    required this.ventas,
  });

  factory TopProducto.fromJson(Map<String, dynamic> json) {
    return TopProducto(
      nombre: json['nombre'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      ventas: (json['ventas'] ?? 0).toDouble(),
    );
  }
}

class VentaPorMaquina {
  final String nombre;
  final double ventas;
  final double ganancia;

  VentaPorMaquina({
    required this.nombre,
    required this.ventas,
    required this.ganancia,
  });

  factory VentaPorMaquina.fromJson(Map<String, dynamic> json) {
    return VentaPorMaquina(
      nombre: json['nombre'] ?? '',
      ventas: (json['ventas'] ?? 0).toDouble(),
      ganancia: (json['ganancia'] ?? 0).toDouble(),
    );
  }
}

class ResumenHoy {
  final double ventas;
  final double ganancia;
  final int cantidad;

  ResumenHoy({
    required this.ventas,
    required this.ganancia,
    required this.cantidad,
  });

  factory ResumenHoy.fromJson(Map<String, dynamic> json) {
    return ResumenHoy(
      ventas: (json['ventas'] ?? 0).toDouble(),
      ganancia: (json['ganancia'] ?? 0).toDouble(),
      cantidad: json['cantidad'] ?? 0,
    );
  }
}

class ResumenMes {
  final double ventas;
  final double ganancia;
  final double gastos;
  final double utilidad;

  ResumenMes({
    required this.ventas,
    required this.ganancia,
    required this.gastos,
    required this.utilidad,
  });

  factory ResumenMes.fromJson(Map<String, dynamic> json) {
    return ResumenMes(
      ventas: (json['ventas'] ?? 0).toDouble(),
      ganancia: (json['ganancia'] ?? 0).toDouble(),
      gastos: (json['gastos'] ?? 0).toDouble(),
      utilidad: (json['utilidad'] ?? 0).toDouble(),
    );
  }
}

// Clases para gráficas (se mantienen igual)
class VentaDiaria {
  final DateTime fecha;
  final double venta;

  VentaDiaria({required this.fecha, required this.venta});
}

class MaquinaVentas {
  final String nombre;
  final double ventas;
  final double ganancia;

  MaquinaVentas(
      {required this.nombre, required this.ventas, required this.ganancia});
}
