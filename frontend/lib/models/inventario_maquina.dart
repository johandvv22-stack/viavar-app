class InventarioMaquina {
  final int id;
  final int maquinaId;
  final String maquinaNombre;
  final int productoId;
  final String productoNombre;
  final String productoCodigo;
  final int stockActual;
  final int stockMaximo;
  final String codigoEspiral;
  final double precioVenta;

  InventarioMaquina({
    required this.id,
    required this.maquinaId,
    required this.maquinaNombre,
    required this.productoId,
    required this.productoNombre,
    required this.productoCodigo,
    required this.stockActual,
    required this.stockMaximo,
    required this.codigoEspiral,
    required this.precioVenta,
  });

  factory InventarioMaquina.fromJson(Map<String, dynamic> json) {
    return InventarioMaquina(
      id: json['id'] ?? 0,
      maquinaId: json['maquina'] ?? 0,
      maquinaNombre: json['maquina_nombre'] ?? '',
      productoId: json['producto'] ?? 0,
      productoNombre: json['producto_nombre'] ?? '',
      productoCodigo: json['producto_codigo'] ?? '',
      stockActual: json['stock_actual'] ?? 0,
      stockMaximo: json['stock_maximo'] ?? 0,
      codigoEspiral: json['codigo_espiral'] ?? '',
      precioVenta: (json['precio_venta'] ?? 0).toDouble(),
    );
  }

  double get porcentajeStock {
    if (stockMaximo == 0) return 100.0;
    return (stockActual / stockMaximo) * 100;
  }

  bool get isCritico => porcentajeStock < 20;
  bool get isMuyCritico => stockActual <= 3;
}
