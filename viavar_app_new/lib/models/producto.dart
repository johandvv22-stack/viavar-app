import "package:flutter/material.dart";

class Producto {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String categoria;
  final double precioCompra;
  final double precioVentaSugerido;
  final double gananciaUnitaria;
  final String? imagen;
  final bool estado;
  final DateTime fechaCreacion;

  Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.categoria,
    required this.precioCompra,
    required this.precioVentaSugerido,
    required this.gananciaUnitaria,
    this.imagen,
    required this.estado,
    required this.fechaCreacion,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      categoria: json['categoria'],
      precioCompra: double.parse(json['precio_compra'].toString()),
      precioVentaSugerido: double.parse(json['precio_venta_sugerido'].toString()),
      gananciaUnitaria: (json['ganancia_unitaria'] ?? 0).toDouble(),
      imagen: json['imagen'],
      estado: json['estado'] ?? true,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'precio_compra': precioCompra,
      'precio_venta_sugerido': precioVentaSugerido,
      'ganancia_unitaria': gananciaUnitaria,
      'imagen': imagen,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  // Métodos helper
  String get nombreCategoria {
    final categorias = {
      'paquete_grande': 'Paquete Grande',
      'paquete_pequeno': 'Paquete Pequeño',
      'liquido_grande': 'Líquido Grande',
      'liquido_pequeno': 'Líquido Pequeño',
      'snack': 'Snack',
      'bebida': 'Bebida',
      'cafe': 'Café',
      'dulce': 'Dulce',
    };
    return categorias[categoria] ?? categoria;
  }

  String get estadoTexto => estado ? 'Activo' : 'Inactivo';
  Color get estadoColor => estado ? Colors.green : Colors.red;
  IconData get estadoIcono => estado ? Icons.check_circle : Icons.cancel;

  // Método para calcular margen de ganancia en porcentaje
  double get margenGanancia {
    if (precioCompra == 0) return 0;
    return ((precioVentaSugerido - precioCompra) / precioCompra * 100);
  }

  // Método para obtener color según margen
  Color get colorMargen {
    if (margenGanancia >= 100) return Colors.green[800]!;
    if (margenGanancia >= 50) return Colors.green;
    if (margenGanancia >= 20) return Colors.blue;
    if (margenGanancia >= 0) return Colors.orange;
    return Colors.red;
  }

  // Método para obtener ícono según categoría
  IconData get iconoCategoria {
    switch (categoria.toLowerCase()) {
      case 'cafe':
      case 'café':
        return Icons.coffee;
      case 'bebida':
      case 'liquido_grande':
      case 'liquido_pequeno':
        return Icons.local_drink;
      case 'snack':
      case 'paquete_grande':
      case 'paquete_pequeno':
      case 'dulce':
        return Icons.fastfood;
      default:
        return Icons.inventory;
    }
  }
}
