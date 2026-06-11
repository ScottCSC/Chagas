class OcupacionCatalogo {
  final int idOcupacion;
  final String? codigo;
  final String nombre;
  final String? descripcion;
  final int orden;

  const OcupacionCatalogo({
    required this.idOcupacion,
    this.codigo,
    required this.nombre,
    this.descripcion,
    this.orden = 0,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  /// Mapeo 1:1 con columnas de `public.catalogo_ocupaciones` (PostgREST).
  factory OcupacionCatalogo.fromMap(Map<String, dynamic> m) {
    final idRaw = m['id_ocupacion'];
    if (idRaw == null) {
      throw FormatException(
        'OcupacionCatalogo.fromMap: falta id_ocupacion en $m',
      );
    }
    return OcupacionCatalogo(
      idOcupacion: _toInt(idRaw),
      codigo: m['codigo']?.toString(),
      nombre: m['nombre']?.toString() ?? '',
      descripcion: m['descripcion']?.toString(),
      orden: _toInt(m['orden']),
    );
  }
}
