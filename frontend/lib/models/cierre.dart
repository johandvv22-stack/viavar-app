class Cierre {
  final int id;
  final int mes;
  final int anio;
  final double ventasTotales;
  final double gastosTotales;
  final double gananciaNeta;
  final String? observaciones;
  final DateTime fechaCreacion;
  final DateTime? fechaCierre;

  // Relaciones
  final int maquinaId;
  final String maquinaNombre;
  final String maquinaCodigo;
  final int? responsableId;
  final String? responsableNombre;

  Cierre({
    required this.id,
    required this.mes,
    required this.anio,
    required this.ventasTotales,
    required this.gastosTotales,
    required this.gananciaNeta,
    this.observaciones,
    required this.fechaCreacion,
    this.fechaCierre,
    required this.maquinaId,
    required this.maquinaNombre,
    required this.maquinaCodigo,
    this.responsableId,
    this.responsableNombre,
  });

  factory Cierre.fromJson(Map<String, dynamic> json) {
    return Cierre(
      id: json['id'],
      mes: json['mes'] ?? 0,
      anio: json['año'] ?? json['anio'] ?? 0,
      ventasTotales: double.parse(json['ventas_totales']?.toString() ?? '0'),
      gastosTotales: double.parse(json['gastos_totales']?.toString() ?? '0'),
      gananciaNeta: double.parse(json['ganancia_neta']?.toString() ?? '0'),
      observaciones: json['observaciones'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.parse(json['fecha_cierre'])
          : null,
      maquinaId: json['maquina'] ?? 0,
      maquinaNombre: json['maquina_nombre'] ?? 'Sin nombre',
      maquinaCodigo: json['maquina_codigo'] ?? '',
      responsableId: json['responsable'],
      responsableNombre: json['responsable_nombre'],
    );
  }

  String get periodo => '$mes/$anio';

  String get periodoNombre {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return '${meses[mes - 1]} $anio';
  }
}
