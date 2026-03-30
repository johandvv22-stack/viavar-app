import 'package:flutter/material.dart';

class Gasto {
  final int id;
  final String categoria; // backend: 'tipo'
  final double monto; // backend: 'valor'
  final DateTime fecha;
  final String? descripcion;

  // Relaciones
  final int? maquinaId;
  final String? maquinaNombre;
  final String? maquinaCodigo;
  final int? usuarioId;
  final String? usuarioNombre;

  Gasto({
    required this.id,
    required this.categoria,
    required this.monto,
    required this.fecha,
    this.descripcion,
    this.maquinaId,
    this.maquinaNombre,
    this.maquinaCodigo,
    this.usuarioId,
    this.usuarioNombre,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    // DEBUG
    debugPrint(
        '📦 Gasto.fromJson - valor: ${json['valor']} (${json['valor'].runtimeType})');

    // 1. Obtener el monto del campo 'valor'
    double monto = 0;
    try {
      final valorStr = json['valor']?.toString() ?? '0';
      monto = double.parse(valorStr);
    } catch (e) {
      debugPrint('❌ Error parseando valor: $e');
      monto = 0;
    }

    return Gasto(
      id: json['id'],
      categoria: json['tipo'] ?? 'Otros', // ✅ Cambiado de 'categoria' a 'tipo'
      monto: monto, // ✅ Cambiado de 'monto' a 'valor'
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      descripcion: json['descripcion'],
      maquinaId: json['maquina'],
      maquinaNombre: json['maquina_nombre'],
      maquinaCodigo: json['maquina_codigo'],
      usuarioId: json['usuario'],
      usuarioNombre: json['usuario_nombre'],
    );
  }

  // Para filtros y categorías predefinidas
  static const List<String> categorias = [
    'transporte',
    'mantenimiento',
    'reposicion',
    'operario',
    'otros'
  ];

  String get categoriaDisplay {
    switch (categoria) {
      case 'transporte':
        return 'Transporte';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'reposicion':
        return 'Reposición';
      case 'operario':
        return 'Operario';
      default:
        return 'Otros';
    }
  }

  Color get color {
    switch (categoria) {
      case 'transporte':
        return Colors.blue;
      case 'mantenimiento':
        return Colors.orange;
      case 'reposicion':
        return Colors.green;
      case 'operario':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData get icono {
    switch (categoria) {
      case 'transporte':
        return Icons.local_shipping;
      case 'mantenimiento':
        return Icons.build;
      case 'reposicion':
        return Icons.inventory;
      case 'operario':
        return Icons.engineering;
      default:
        return Icons.receipt;
    }
  }
}
