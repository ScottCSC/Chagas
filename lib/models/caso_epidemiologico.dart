import '../utils/epi_db_constants.dart';
import 'epi_map_helpers.dart';

class CasoEpidemiologico {
  final int? idCaso;
  final String? codigoCaso;
  final DateTime? fechaRegistro;
  final String? genero;
  final DateTime? fechaNacimiento;
  /// Solo UI / derivada de [fechaNacimiento]; **no** existe columna `edad` en Supabase.
  final int? edad;
  /// Texto del rango (p. ej. `1-4`); se persiste como `rango_edad` si está habilitado en Supabase.
  final String? rangoEtario;
  final int? idSector;
  final String? ocupacion;
  final String? estadoActual;
  final int? numeroContactos;
  final String? observacionGeneral;
  final String? creadoPor;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  /// Últimos 3 dígitos del RUT + DV (p. ej. `123-K`); solo duplicados epidemiológicos, no RUT completo.
  final String? identificadorParcial;

  const CasoEpidemiologico({
    this.idCaso,
    this.codigoCaso,
    this.fechaRegistro,
    this.genero,
    this.fechaNacimiento,
    this.edad,
    this.rangoEtario,
    this.idSector,
    this.ocupacion,
    this.estadoActual,
    this.numeroContactos,
    this.observacionGeneral,
    this.creadoPor,
    this.creadoEn,
    this.actualizadoEn,
    this.identificadorParcial,
  });

  factory CasoEpidemiologico.fromMap(Map<String, dynamic> m) {
    return CasoEpidemiologico(
      idCaso: intOf(m['id_caso']),
      codigoCaso: m['codigo_caso']?.toString(),
      fechaRegistro: parseDateTime(m['fecha_registro']),
      genero: m['genero']?.toString(),
      fechaNacimiento: m['fecha_nacimiento'] == null
          ? null
          : (DateTime.tryParse(m['fecha_nacimiento'].toString()) ??
              parseDateOnly(m['fecha_nacimiento'])),
      edad: null,
      rangoEtario: m['rango_edad']?.toString() ?? m['rango_etario']?.toString(),
      idSector: intOf(m['id_sector']),
      ocupacion: m['ocupacion']?.toString(),
      estadoActual: m['estado_actual']?.toString(),
      numeroContactos: intOf(m['numero_contactos']) ?? 0,
      observacionGeneral: m['observacion_general']?.toString(),
      creadoPor: m['creado_por']?.toString(),
      creadoEn: parseDateTime(m['creado_en']),
      actualizadoEn: parseDateTime(m['actualizado_en']),
      identificadorParcial: m['identificador_parcial']?.toString(),
    );
  }

  /// [codigoCaso] no se envía si es null; [creado_por] en repositorio; [fecha_registro] opcional.
  /// No incluye `edad` (no existe en la tabla).
  Map<String, dynamic> toInsertMap() {
    final m = <String, dynamic>{};
    if (genero != null) m['genero'] = genero;
    if (kSupabaseFechaNacimientoColumnEnabled && fechaNacimiento != null) {
      final d = fechaNacimiento!;
      m['fecha_nacimiento'] =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    if (kSupabaseRangoEdadColumnEnabled) {
      final rangoEdad = rangoEtario?.trim();
      if (rangoEdad != null && rangoEdad.isNotEmpty) {
        m['rango_edad'] = rangoEdad;
      }
    }
    if (idSector != null) m['id_sector'] = idSector;
    if (ocupacion != null && ocupacion!.trim().isNotEmpty) m['ocupacion'] = ocupacion!.trim();
    if (estadoActual != null) m['estado_actual'] = estadoActual;
    m['numero_contactos'] = numeroContactos ?? 0;
    if (observacionGeneral != null && observacionGeneral!.trim().isNotEmpty) {
      m['observacion_general'] = observacionGeneral!.trim();
    }
    if (fechaRegistro != null) m['fecha_registro'] = fechaRegistro!.toIso8601String();
    if (kSupabaseIdentificadorParcialColumnEnabled) {
      final idp = identificadorParcial?.trim();
      if (idp != null && idp.isNotEmpty) {
        m['identificador_parcial'] = idp;
      }
    }
    return m;
  }

  /// Actualización parcial; no incluye `edad`.
  Map<String, dynamic> toUpdateMap() {
    final m = <String, dynamic>{};
    if (genero != null) m['genero'] = genero;
    if (kSupabaseFechaNacimientoColumnEnabled && fechaNacimiento != null) {
      final d = fechaNacimiento!;
      m['fecha_nacimiento'] =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    if (kSupabaseIdentificadorParcialColumnEnabled) {
      final idp = identificadorParcial?.trim();
      if (idp != null && idp.isNotEmpty) {
        m['identificador_parcial'] = idp;
      }
    }
    m['numero_contactos'] = numeroContactos ?? 0;
    if (idSector != null) m['id_sector'] = idSector;
    if (ocupacion != null && ocupacion!.trim().isNotEmpty) {
      m['ocupacion'] = ocupacion!.trim();
    }
    if (estadoActual != null) m['estado_actual'] = estadoActual;
    if (observacionGeneral != null && observacionGeneral!.trim().isNotEmpty) {
      m['observacion_general'] = observacionGeneral!.trim();
    }
    if (kSupabaseRangoEdadColumnEnabled) {
      final rangoEdad = rangoEtario?.trim();
      if (rangoEdad != null && rangoEdad.isNotEmpty) {
        m['rango_edad'] = rangoEdad;
      }
    }
    m['actualizado_en'] = DateTime.now().toUtc().toIso8601String();
    return m;
  }
}
