import '../services/osm_search_service.dart';

/// Ubicación confirmada en el formulario (estado local hasta guardar el paciente).
class SelectedLocation {
  final String address;
  final double latitude;
  final double longitude;
  final String? comuna;
  final String? provincia;
  final String? region;

  const SelectedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.comuna,
    this.provincia,
    this.region,
  });

  factory SelectedLocation.fromOsmPlace(OsmPlace p) {
    final line = p.displayName.trim().isNotEmpty
        ? p.displayName.trim()
        : _fallbackAddressLine(p);
    return SelectedLocation(
      address: line,
      latitude: p.lat,
      longitude: p.lon,
      comuna: p.toComuna(),
      provincia: p.toProvincia(),
      region: p.state,
    );
  }

  static String _fallbackAddressLine(OsmPlace p) {
    final parts = <String>[];
    final calle = p.toDireccionBonita().trim();
    if (calle.isNotEmpty) parts.add(calle);
    final c = p.toComuna();
    if (c != null && c.isNotEmpty) parts.add(c);
    return parts.isEmpty ? '${p.lat}, ${p.lon}' : parts.join(', ');
  }
}
