import 'epi_map_helpers.dart';

class Sector {
  final int idSector;
  final String nombreSector;
  final String? comuna;
  final double? latitudCentroide;
  final double? longitudCentroide;
  final bool activo;

  const Sector({
    required this.idSector,
    required this.nombreSector,
    this.comuna,
    this.latitudCentroide,
    this.longitudCentroide,
    this.activo = true,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory Sector.fromMap(Map<String, dynamic> m) {
    return Sector(
      idSector: intOf(m['id_sector'])!,
      nombreSector: (m['nombre_sector'] ?? '').toString(),
      comuna: m['comuna']?.toString(),
      latitudCentroide: _toDouble(m['latitud_centroide']),
      longitudCentroide: _toDouble(m['longitud_centroide']),
      activo: m['activo'] == true || m['activo'] == 1,
    );
  }
}
