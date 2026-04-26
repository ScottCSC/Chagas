import 'epi_map_helpers.dart';

class HistorialEstadoCaso {
  final int idHistorial;
  final int idCaso;
  final String? estadoAnterior;
  final String? estadoNuevo;
  final DateTime? fechaCambio;
  final String? observacion;
  final String? cambiadoPor;
  final DateTime? creadoEn;

  const HistorialEstadoCaso({
    required this.idHistorial,
    required this.idCaso,
    this.estadoAnterior,
    this.estadoNuevo,
    this.fechaCambio,
    this.observacion,
    this.cambiadoPor,
    this.creadoEn,
  });

  factory HistorialEstadoCaso.fromMap(Map<String, dynamic> m) {
    return HistorialEstadoCaso(
      idHistorial: intOf(m['id_historial'])!,
      idCaso: intOf(m['id_caso'])!,
      estadoAnterior: m['estado_anterior']?.toString(),
      estadoNuevo: m['estado_nuevo']?.toString(),
      fechaCambio: parseDateTime(m['fecha_cambio']),
      observacion: m['observacion']?.toString(),
      cambiadoPor: m['cambiado_por']?.toString(),
      creadoEn: parseDateTime(m['creado_en']),
    );
  }
}
