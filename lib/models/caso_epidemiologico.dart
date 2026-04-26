import 'epi_map_helpers.dart';

class CasoEpidemiologico {
  final int? idCaso;
  final String? codigoCaso;
  final DateTime? fechaRegistro;
  final String? genero;
  final int? edad;
  final int? idSector;
  final String? ocupacion;
  final String? estadoActual;
  final bool? contactoDisponible;
  final String? tipoContacto;
  final String? observacionGeneral;
  final String? creadoPor;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const CasoEpidemiologico({
    this.idCaso,
    this.codigoCaso,
    this.fechaRegistro,
    this.genero,
    this.edad,
    this.idSector,
    this.ocupacion,
    this.estadoActual,
    this.contactoDisponible,
    this.tipoContacto,
    this.observacionGeneral,
    this.creadoPor,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory CasoEpidemiologico.fromMap(Map<String, dynamic> m) {
    return CasoEpidemiologico(
      idCaso: intOf(m['id_caso']),
      codigoCaso: m['codigo_caso']?.toString(),
      fechaRegistro: parseDateTime(m['fecha_registro']),
      genero: m['genero']?.toString(),
      edad: intOf(m['edad']),
      idSector: intOf(m['id_sector']),
      ocupacion: m['ocupacion']?.toString(),
      estadoActual: m['estado_actual']?.toString(),
      contactoDisponible: m['contacto_disponible'] is bool
          ? m['contacto_disponible'] as bool
          : (m['contacto_disponible'] == true || m['contacto_disponible'] == 1),
      tipoContacto: m['tipo_contacto']?.toString(),
      observacionGeneral: m['observacion_general']?.toString(),
      creadoPor: m['creado_por']?.toString(),
      creadoEn: parseDateTime(m['creado_en']),
      actualizadoEn: parseDateTime(m['actualizado_en']),
    );
  }

  /// [codigoCaso] no se envía si es null; [creado_por] en repositorio; [fecha_registro] opcional.
  Map<String, dynamic> toInsertMap() {
    final m = <String, dynamic>{};
    // codigo_caso lo genera Supabase; no enviar en alta.
    if (genero != null) m['genero'] = genero;
    if (edad != null) m['edad'] = edad;
    if (idSector != null) m['id_sector'] = idSector;
    if (ocupacion != null && ocupacion!.trim().isNotEmpty) m['ocupacion'] = ocupacion!.trim();
    if (estadoActual != null) m['estado_actual'] = estadoActual;
    if (contactoDisponible != null) m['contacto_disponible'] = contactoDisponible;
    if (tipoContacto != null && tipoContacto!.isNotEmpty) m['tipo_contacto'] = tipoContacto;
    if (observacionGeneral != null && observacionGeneral!.trim().isNotEmpty) {
      m['observacion_general'] = observacionGeneral!.trim();
    }
    if (fechaRegistro != null) m['fecha_registro'] = fechaRegistro!.toIso8601String();
    return m;
  }

  Map<String, dynamic> toUpdateMap() {
    final m = toInsertMap();
    m.remove('creado_por');
    m.remove('codigo_caso');
    m.remove('fecha_registro');
    m.remove('creado_en');
    return m;
  }
}
