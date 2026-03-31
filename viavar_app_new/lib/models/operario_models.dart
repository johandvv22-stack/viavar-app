// Modelo para historial de visitas
class VisitaHistorial {
  final int id;
  final String maquinaNombre;
  final DateTime fecha;
  final String estado;
  final int productosSurtidos;
  final double ventasGeneradas;

  VisitaHistorial({
    required this.id,
    required this.maquinaNombre,
    required this.fecha,
    required this.estado,
    required this.productosSurtidos,
    required this.ventasGeneradas,
  });

  factory VisitaHistorial.fromJson(Map<String, dynamic> json) {
    return VisitaHistorial(
      id: json['id'] ?? 0,
      maquinaNombre: json['maquina_nombre'] ??
          json['maquina']?.toString() ??
          'Desconocida',
      fecha: DateTime.parse(json['fecha_fin'] ??
          json['fecha_inicio'] ??
          DateTime.now().toIso8601String()),
      estado: json['estado'] ?? 'completada',
      productosSurtidos: json['productos_surtidos'] ?? 0,
      ventasGeneradas: (json['ventas_generadas'] ?? 0).toDouble(),
    );
  }
}

// Modelo para producto en inventario (basado en /api/inventario/?maquina=X)
class ProductoInventario {
  final int id;
  final int productoId;
  final String codigo;
  final String nombre;
  final String? categoria;
  final int stockActual;
  final int stockMaximo;
  final int cantidadFaltante;
  final String? codigoEspiral;
  final double precioVenta;
  bool surtido;

  ProductoInventario({
    required this.id,
    required this.productoId,
    required this.codigo,
    required this.nombre,
    this.categoria,
    required this.stockActual,
    required this.stockMaximo,
    required this.cantidadFaltante,
    this.codigoEspiral,
    required this.precioVenta,
    this.surtido = false,
  });

  factory ProductoInventario.fromJson(Map<String, dynamic> json) {
    print('📦 Parseando ProductoInventario: $json');

    // Obtener el faltante - puede venir como 'faltante' o 'cantidad_faltante'
    int faltante = 0;
    if (json['faltante'] != null) {
      faltante = (json['faltante'] is int)
          ? json['faltante']
          : int.tryParse(json['faltante'].toString()) ?? 0;
    } else if (json['cantidad_faltante'] != null) {
      faltante = (json['cantidad_faltante'] is int)
          ? json['cantidad_faltante']
          : int.tryParse(json['cantidad_faltante'].toString()) ?? 0;
    } else {
      // Calcular faltante si no viene
      final stockActual = (json['stock_actual'] ?? 0).toInt();
      final stockMaximo = (json['stock_maximo'] ?? 0).toInt();
      faltante = (stockMaximo - stockActual).clamp(0, stockMaximo);
    }

    // Obtener precio venta
    double precio = 0;
    if (json['precio_venta'] != null) {
      precio = (json['precio_venta'] is num)
          ? (json['precio_venta'] as num).toDouble()
          : double.tryParse(json['precio_venta'].toString()) ?? 0;
    }

    return ProductoInventario(
      id: json['id'] ?? 0,
      productoId: json['producto_id'] ?? 0,
      codigo: json['producto_codigo'] ?? json['codigo'] ?? '',
      nombre: json['producto_nombre'] ?? json['nombre'] ?? '',
      categoria: json['categoria'],
      stockActual: (json['stock_actual'] ?? 0).toInt(),
      stockMaximo: (json['stock_maximo'] ?? 0).toInt(),
      cantidadFaltante: faltante,
      codigoEspiral: json['codigo_espiral'] ?? json['posicion'],
      precioVenta: precio,
    );
  }

  // Propiedad para saber si necesita surtir
  bool get necesitaSurtir => cantidadFaltante > 0;
}
