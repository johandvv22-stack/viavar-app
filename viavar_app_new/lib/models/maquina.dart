import "package:flutter/material.dart";

class Maquina {
  final int id;
  final String nombre;
  final String codigo;
  final String ubicacion;
  final double? latitud;
  final double? longitud;
  final double porcentajeSurtido;
  final double ventasHoy;
  final double gananciaHoy;
  final int capacidadTotal;
  final String estado;
  final DateTime fechaInstalacion;
  final DateTime fechaCreacion;
  final DateTime? ultimaVenta;
  final String? ultimaVisita;

  Maquina({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.ubicacion,
    this.latitud,
    this.longitud,
    required this.porcentajeSurtido,
    required this.ventasHoy,
    required this.gananciaHoy,
    required this.capacidadTotal,
    required this.estado,
    required this.fechaInstalacion,
    required this.fechaCreacion,
    this.ultimaVenta,
    this.ultimaVisita,
  });

  factory Maquina.fromJson(Map<String, dynamic> json) {
    return Maquina(
      id: json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
      ubicacion: json['ubicacion'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      porcentajeSurtido: (json['porcentaje_surtido'] ?? 0).toDouble(),
      ventasHoy: (json['ventas_hoy'] ?? 0).toDouble(),
      gananciaHoy: (json['ganancia_hoy'] ?? 0).toDouble(),
      capacidadTotal: json['capacidad_total'] ?? 0,
      estado: json['estado'],
      fechaInstalacion: DateTime.parse(json['fecha_instalacion']),
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      ultimaVenta: json['ultima_venta'] != null
          ? DateTime.parse(json['ultima_venta'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'ubicacion': ubicacion,
      'latitud': latitud,
      'longitud': longitud,
      'porcentaje_surtido': porcentajeSurtido,
      'ventas_hoy': ventasHoy,
      'ganancia_hoy': gananciaHoy,
      'capacidad_total': capacidadTotal,
      'estado': estado,
      'fecha_instalacion': fechaInstalacion.toIso8601String().split('T')[0],
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  // Método para obtener color según estado
  String get estadoColor {
    switch (estado.toLowerCase()) {
      case 'activa':
      case 'activo':
        return 'green';
      case 'inactiva':
      case 'inactivo':
        return 'red';
      case 'mantenimiento':
        return 'orange';
      default:
        return 'gray';
    }
  }

  // Método para obtener ícono según estado
  String get estadoIcono {
    switch (estado.toLowerCase()) {
      case 'activa':
      case 'activo':
        return 'check_circle';
      case 'inactiva':
      case 'inactivo':
        return 'cancel';
      case 'mantenimiento':
        return 'build';
      default:
        return 'help';
    }
  }

  // Método para verificar si tiene coordenadas para Maps
  bool get tieneCoordenadas {
    return latitud != null && longitud != null;
  }

  // Método para generar URL de Google Maps
  String get mapsUrl {
    if (tieneCoordenadas) {
      return "https://www.google.com/maps?q=$latitud,$longitud";
    } else {
      // Usar la ubicación como búsqueda
      return "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(ubicacion)}";
    }
  }
}

// ========== CLASE PARA VISITAS (COMPATIBLE CON OPERARIO) ==========
class MaquinaRuta {
  final int id;
  final String codigo;
  final String nombre;
  final String ubicacion;
  final double porcentajeSurtido;
  final String estado;
  final String? ultimaVisita;

// Propiedades computadas
  bool get activa =>
      estado.toLowerCase() == 'activa' || estado.toLowerCase() == 'activo';
  bool get necesitaVisita => porcentajeSurtido < 30;

  MaquinaRuta({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.ubicacion,
    required this.porcentajeSurtido,
    required this.estado,
    this.ultimaVisita,
  });

  // Método para obtener color según estado (para la UI)
  Color get estadoColor {
    switch (estado.toLowerCase()) {
      case 'activa':
      case 'activo':
        return Colors.green;
      case 'inactiva':
      case 'inactivo':
        return Colors.red;
      case 'mantenimiento':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Método para obtener ícono según estado
  IconData get estadoIcono {
    switch (estado.toLowerCase()) {
      case 'activa':
      case 'activo':
        return Icons.check_circle;
      case 'inactiva':
      case 'inactivo':
        return Icons.cancel;
      case 'mantenimiento':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  // Método para generar URL de Google Maps
  String get mapsUrl {
    return "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(ubicacion)}";
  }
}
