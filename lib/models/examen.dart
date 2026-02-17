/// Modelo de examen (tabla examen_chagas). fromJson/toJson para repos y futura capa offline.
class Examen {
  final int? id;
  final int? idPersona;
  final String? fechaExamen;
  final String? tipoExamen;
  final String? resultado;
  final String? laboratorio;
  final String? observacion;
  final String? creadoEn;
  /// Datos anidados de persona (cuando el listado trae persona(nombre, rut)).
  final Map<String, dynamic>? persona;

  const Examen({
    this.id,
    this.idPersona,
    this.fechaExamen,
    this.tipoExamen,
    this.resultado,
    this.laboratorio,
    this.observacion,
    this.creadoEn,
    this.persona,
  });

  factory Examen.fromJson(Map<String, dynamic> json) {
    return Examen(
      id: json['id'] as int?,
      idPersona: json['id_persona'] as int?,
      fechaExamen: json['fecha_examen']?.toString(),
      tipoExamen: json['tipo_examen']?.toString(),
      resultado: json['resultado']?.toString(),
      laboratorio: json['laboratorio']?.toString(),
      observacion: json['observacion']?.toString(),
      creadoEn: json['creado_en']?.toString(),
      persona: json['persona'] != null
          ? Map<String, dynamic>.from(json['persona'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (idPersona != null) 'id_persona': idPersona,
      if (fechaExamen != null) 'fecha_examen': fechaExamen,
      if (tipoExamen != null) 'tipo_examen': tipoExamen,
      if (resultado != null) 'resultado': resultado,
      if (laboratorio != null) 'laboratorio': laboratorio,
      if (observacion != null) 'observacion': observacion,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (persona != null) 'persona': persona,
    };
  }

  Map<String, dynamic> toPayload() {
    return {
      if (idPersona != null) 'id_persona': idPersona,
      if (fechaExamen != null) 'fecha_examen': fechaExamen,
      if (tipoExamen != null) 'tipo_examen': tipoExamen,
      if (resultado != null) 'resultado': resultado,
      if (laboratorio != null) 'laboratorio': laboratorio,
      if (observacion != null) 'observacion': observacion,
    };
  }
}
