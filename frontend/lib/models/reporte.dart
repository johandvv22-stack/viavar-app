class Reporte {
  final int id;
  final int maquinaId;
  final String maquinaNombre;
  final String descripcion;
  final String? foto;
  final DateTime fecha;
  final String estado;

  Reporte({
    required this.id,
    required this.maquinaId,
    required this.maquinaNombre,
    required this.descripcion,
    this.foto,
    required this.fecha,
    required this.estado,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      id: json['id'] ?? 0,
      maquinaId: json['maquina'] ?? 0,
      maquinaNombre: json['maquina_nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      foto: json['foto'],
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      estado: json['estado'] ?? 'pendiente',
    );
  }
}
