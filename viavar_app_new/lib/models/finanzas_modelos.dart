// Modelo para resumen de gastos por categoría
class ResumenGastos {
  final double totalGeneral;
  final List<CategoriaGasto> categorias;
  final Periodo periodo;

  ResumenGastos({
    required this.totalGeneral,
    required this.categorias,
    required this.periodo,
  });

  factory ResumenGastos.fromJson(Map<String, dynamic> json) {
    return ResumenGastos(
      totalGeneral: (json['total_general'] ?? 0).toDouble(),
      categorias: (json['categorias'] as List? ?? [])
          .map((c) => CategoriaGasto.fromJson(c))
          .toList(),
      periodo: Periodo.fromJson(json['periodo'] ?? {}),
    );
  }
}

class CategoriaGasto {
  final String categoria;
  final String categoriaNombre;
  final double total;
  final double porcentaje;
  final String icono;
  final String color;

  CategoriaGasto({
    required this.categoria,
    required this.categoriaNombre,
    required this.total,
    required this.porcentaje,
    required this.icono,
    required this.color,
  });

  factory CategoriaGasto.fromJson(Map<String, dynamic> json) {
    return CategoriaGasto(
      categoria: json['categoria'] ?? '',
      categoriaNombre: json['categoria_nombre'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      porcentaje: (json['porcentaje'] ?? 0).toDouble(),
      icono: json['icono'] ?? 'category',
      color: json['color'] ?? '#6B7280',
    );
  }
}

// Modelo para top facturación de máquinas
class TopFacturacion {
  final double totalGeneral;
  final List<MaquinaTopFacturacion> topMaquinas;
  final Periodo periodo;

  TopFacturacion({
    required this.totalGeneral,
    required this.topMaquinas,
    required this.periodo,
  });

  factory TopFacturacion.fromJson(Map<String, dynamic> json) {
    return TopFacturacion(
      totalGeneral: (json['total_general'] ?? 0).toDouble(),
      topMaquinas: (json['top_maquinas'] as List? ?? [])
          .map((m) => MaquinaTopFacturacion.fromJson(m))
          .toList(),
      periodo: Periodo.fromJson(json['periodo'] ?? {}),
    );
  }
}

class MaquinaTopFacturacion {
  final int id;
  final String codigo;
  final String nombre;
  final double ventasTotales;
  final double gananciasTotales;
  final int unidadesVendidas;
  final double porcentaje;

  MaquinaTopFacturacion({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.ventasTotales,
    required this.gananciasTotales,
    required this.unidadesVendidas,
    required this.porcentaje,
  });

  factory MaquinaTopFacturacion.fromJson(Map<String, dynamic> json) {
    return MaquinaTopFacturacion(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      ventasTotales: (json['ventas_totales'] ?? 0).toDouble(),
      gananciasTotales: (json['ganancias_totales'] ?? 0).toDouble(),
      unidadesVendidas: json['unidades_vendidas'] ?? 0,
      porcentaje: (json['porcentaje'] ?? 0).toDouble(),
    );
  }
}

// Modelo para evolución mensual
class EvolucionMensual {
  final String mes;
  final String fecha;
  final double ventas;
  final double gastos;
  final double utilidad;
  final double margen;

  EvolucionMensual({
    required this.mes,
    required this.fecha,
    required this.ventas,
    required this.gastos,
    required this.utilidad,
    required this.margen,
  });

  factory EvolucionMensual.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return EvolucionMensual(
      mes: json['mes'] ?? '',
      fecha: json['fecha'] ?? '',
      ventas: _toDouble(json['ventas']),
      gastos: _toDouble(json['gastos']),
      utilidad: _toDouble(json['utilidad']),
      margen: _toDouble(json['margen']),
    );
  }
}

// Modelo para cierre mensual (CRUD)
class CierreMensual {
  final int id;
  final int maquinaId;
  final String maquinaNombre;
  final String maquinaCodigo;
  final int mes;
  final int anio;
  final double ventasTotales;
  final double gastosTotales;
  final double gananciaNeta;
  final String? observaciones;
  final String? fechaCierre;
  final int? responsableId; // AGREGAR

  CierreMensual({
    required this.id,
    required this.maquinaId,
    required this.maquinaNombre,
    required this.maquinaCodigo,
    required this.mes,
    required this.anio,
    required this.ventasTotales,
    required this.gastosTotales,
    required this.gananciaNeta,
    this.observaciones,
    this.fechaCierre,
    this.responsableId,
  });

  factory CierreMensual.fromJson(Map<String, dynamic> json) {
    // Función helper para convertir a double
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CierreMensual(
      id: json['id'] ?? 0,
      maquinaId: json['maquina'] ?? 0,
      maquinaNombre: json['maquina_nombre'] ?? '',
      maquinaCodigo: json['maquina_codigo'] ?? '',
      mes: json['mes'] ?? 0,
      anio: json['año'] ?? 0,
      ventasTotales: _toDouble(json['ventas_totales']),
      gastosTotales: _toDouble(json['gastos_totales']),
      gananciaNeta: _toDouble(json['ganancia_neta']),
      observaciones: json['observaciones'],
      fechaCierre: json['fecha_cierre'],
      responsableId: json['responsable'],
    );
  }
}

// Modelo para gasto (CRUD)
class Gasto {
  final int id;
  final String tipo;
  final String descripcion;
  final double valor;
  final String fecha;
  final int? maquinaId;
  final String? maquinaNombre;
  final String usuarioNombre;

  Gasto({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.valor,
    required this.fecha,
    this.maquinaId,
    this.maquinaNombre,
    required this.usuarioNombre,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Gasto(
      id: json['id'] ?? 0,
      tipo: json['tipo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      valor: _toDouble(json['valor']),
      fecha: json['fecha'] ?? '',
      maquinaId: json['maquina'],
      maquinaNombre: json['maquina_nombre'],
      usuarioNombre: json['usuario_nombre'] ?? '',
    );
  }
}

// Helper
class Periodo {
  final String? fechaInicio;
  final String? fechaFin;

  Periodo({this.fechaInicio, this.fechaFin});

  factory Periodo.fromJson(Map<String, dynamic> json) {
    return Periodo(
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
    );
  }
}
