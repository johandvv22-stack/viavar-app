import 'package:flutter/material.dart';

class Esp32Estado {
  final int id;
  final int maquinaId;
  final String? ultimaConexion;
  final String estado;
  final int memoriaOcupada;
  final String? firmwareVersion;
  final int intervaloActual;
  final int batchPendientes;
  final String? ultimaAlerta;
  final bool online;

  Esp32Estado({
    required this.id,
    required this.maquinaId,
    this.ultimaConexion,
    required this.estado,
    required this.memoriaOcupada,
    this.firmwareVersion,
    required this.intervaloActual,
    required this.batchPendientes,
    this.ultimaAlerta,
    required this.online,
  });

  factory Esp32Estado.fromJson(Map<String, dynamic> json) {
    return Esp32Estado(
      id: json['id'] ?? 0,
      maquinaId: json['maquina'] ?? 0,
      ultimaConexion: json['ultima_conexion'],
      estado: json['estado'] ?? 'offline',
      memoriaOcupada: json['memoria_ocupada'] ?? 0,
      firmwareVersion: json['firmware_version'],
      intervaloActual: json['intervalo_actual'] ?? 900,
      batchPendientes: json['batch_pendientes'] ?? 0,
      ultimaAlerta: json['ultima_alerta'],
      online: json['estado'] == 'online' ||
          json['estado'] == 'sending' ||
          json['estado'] == 'reading',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maquina': maquinaId,
      'ultima_conexion': ultimaConexion,
      'estado': estado,
      'memoria_ocupada': memoriaOcupada,
      'firmware_version': firmwareVersion,
      'intervalo_actual': intervaloActual,
      'batch_pendientes': batchPendientes,
      'ultima_alerta': ultimaAlerta,
    };
  }

  bool get isOnline => online;

  String get estadoTexto {
    switch (estado) {
      case 'online':
        return 'En línea';
      case 'offline':
        return 'Desconectada';
      case 'storage':
        return 'Almacenando localmente';
      case 'reading':
        return 'Leyendo sensores';
      case 'sending':
        return 'Enviando datos';
      case 'error':
        return 'Error';
      default:
        return estado;
    }
  }

  Color get estadoColor {
    switch (estado) {
      case 'online':
      case 'sending':
      case 'reading':
        return Colors.green;
      case 'storage':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'offline':
      default:
        return Colors.grey;
    }
  }

  IconData get estadoIcon {
    switch (estado) {
      case 'online':
        return Icons.check_circle;
      case 'offline':
        return Icons.offline_bolt;
      case 'storage':
        return Icons.sd_storage;
      case 'reading':
        return Icons.sensors;
      case 'sending':
        return Icons.cloud_upload;
      case 'error':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}

// Modelo para bandeja (esclava)
class Esp32Slave {
  final int id;
  final int maquinaId;
  final String posicion;
  final String? codigoProducto;
  final String firmwareVersion;
  final DateTime? ultimaConexion;
  final String estado;
  final String? errorMensaje;
  final double distanciaMin;
  final double distanciaMax;
  final List<String> posiciones;
  final Map<String, dynamic> ultimaLectura;
  final DateTime? ultimaLecturaFecha;

  Esp32Slave({
    required this.id,
    required this.maquinaId,
    required this.posicion,
    this.codigoProducto,
    required this.firmwareVersion,
    this.ultimaConexion,
    required this.estado,
    this.errorMensaje,
    required this.distanciaMin,
    required this.distanciaMax,
    required this.posiciones,
    required this.ultimaLectura,
    this.ultimaLecturaFecha,
  });

  factory Esp32Slave.fromJson(Map<String, dynamic> json) {
    return Esp32Slave(
      id: json['id'] ?? 0,
      maquinaId: json['maquina'] ?? 0,
      posicion: json['posicion'] ?? '',
      codigoProducto: json['codigo_producto'],
      firmwareVersion: json['firmware_version'] ?? 'v1.0',
      ultimaConexion: json['ultima_conexion'] != null
          ? DateTime.parse(json['ultima_conexion'])
          : null,
      estado: json['estado'] ?? 'offline',
      errorMensaje: json['error_mensaje'],
      distanciaMin: (json['distancia_min'] ?? 0).toDouble(),
      distanciaMax: (json['distancia_max'] ?? 200).toDouble(),
      posiciones: List<String>.from(json['posiciones'] ?? []),
      ultimaLectura: json['ultima_lectura'] ?? {},
      ultimaLecturaFecha: json['ultima_lectura_fecha'] != null
          ? DateTime.parse(json['ultima_lectura_fecha'])
          : null,
    );
  }

  // Métodos de utilidad
  bool get isOnline => estado == 'online';
  bool get isReading => estado == 'reading';
  bool get hasError => estado == 'error';
  bool get isCalibrating => estado == 'calibrating';

  Color get estadoColor {
    switch (estado) {
      case 'online':
        return Colors.green;
      case 'reading':
        return Colors.blue;
      case 'calibrating':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get estadoIcon {
    switch (estado) {
      case 'online':
        return Icons.check_circle;
      case 'reading':
        return Icons.sensors;
      case 'calibrating':
        return Icons.tune;
      case 'error':
        return Icons.error;
      default:
        return Icons.offline_bolt;
    }
  }

  String get estadoTexto {
    switch (estado) {
      case 'online':
        return 'En línea';
      case 'reading':
        return 'Leyendo sensores';
      case 'calibrating':
        return 'Calibrando';
      case 'error':
        return 'Error';
      default:
        return 'Desconectada';
    }
  }

  // Calcular porcentaje de surtido total de la bandeja
  double get porcentajeSurtido {
    if (posiciones.isEmpty || ultimaLectura.isEmpty) return 0;

    int totalActual = 0;
    int totalMaximo =
        posiciones.length * 20; // Asumiendo 20 productos por espiral

    for (var pos in posiciones) {
      final valor = ultimaLectura[pos];
      if (valor != null) {
        totalActual += valor is int ? valor : (valor as num).toInt();
      }
    }

    if (totalMaximo == 0) return 0;
    return (totalActual / totalMaximo) * 100;
  }

  String get porcentajeSurtidoTexto {
    return '${porcentajeSurtido.toStringAsFixed(0)}%';
  }
}

// Modelo para logs
class Esp32Log {
  final int id;
  final int maquinaId;
  final int? slaveId;
  final DateTime timestamp;
  final String nivel;
  final String mensaje;
  final Map<String, dynamic> datosExtra;

  Esp32Log({
    required this.id,
    required this.maquinaId,
    this.slaveId,
    required this.timestamp,
    required this.nivel,
    required this.mensaje,
    required this.datosExtra,
  });

  factory Esp32Log.fromJson(Map<String, dynamic> json) {
    return Esp32Log(
      id: json['id'] ?? 0,
      maquinaId: json['maquina'] ?? 0,
      slaveId: json['slave'],
      timestamp: DateTime.parse(json['timestamp']),
      nivel: json['nivel'] ?? 'INFO',
      mensaje: json['mensaje'] ?? '',
      datosExtra: json['datos_extra'] ?? {},
    );
  }

  Color get nivelColor {
    switch (nivel) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData get nivelIcon {
    switch (nivel) {
      case 'ERROR':
        return Icons.error;
      case 'WARNING':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String get nivelTexto {
    switch (nivel) {
      case 'ERROR':
        return 'Error';
      case 'WARNING':
        return 'Advertencia';
      default:
        return 'Info';
    }
  }
}
