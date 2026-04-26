import 'dart:convert';

import 'package:http/http.dart' as http;

class OsmPlace {
  final String displayName;
  final double lat;
  final double lon;
  final String? road;
  final String? houseNumber;
  final String? city;
  final String? town;
  final String? village;
  final String? state;
  final String? county;
  final String? suburb;

  OsmPlace({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.road,
    this.houseNumber,
    this.city,
    this.town,
    this.village,
    this.state,
    this.county,
    this.suburb,
  });

  factory OsmPlace.fromJson(Map<String, dynamic> j) {
    final a = (j['address'] ?? {}) as Map<String, dynamic>;
    return OsmPlace(
      displayName: (j['display_name'] ?? '') as String,
      lat: double.tryParse(j['lat']?.toString() ?? '') ?? 0,
      lon: double.tryParse(j['lon']?.toString() ?? '') ?? 0,
      road: a['road']?.toString(),
      houseNumber: a['house_number']?.toString(),
      city: a['city']?.toString(),
      town: a['town']?.toString(),
      village: a['village']?.toString(),
      state: a['state']?.toString(),
      county: a['county']?.toString(),
      suburb: a['suburb']?.toString(),
    );
  }

  String toDireccionBonita() {
    final parts = <String>[];
    if (road != null) parts.add(road!);
    if (houseNumber != null) parts.add(houseNumber!);
    if (suburb != null) parts.add(suburb!);
    return parts.isEmpty ? displayName : parts.join(' ');
  }

  String? toComuna() => city ?? town ?? village ?? suburb;
  String? toProvincia() => state ?? county;
}

class OsmSearchService {
  static Future<List<OsmPlace>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'json',
      'addressdetails': '1',
      'limit': '5',
      'countrycodes': 'cl', // Restringir a Chile para resultados más relevantes
    });

    final res = await http.get(
      uri,
      headers: {
        'User-Agent': 'chagas_app/1.0 (contact: dev@local)',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as List;
    return data
        .map((e) => OsmPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Geocodificación inversa (Nominatim). Respetar uso razonable (debounce en UI).
  static Future<OsmPlace?> reverse(double lat, double lon) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'json',
      'addressdetails': '1',
    });

    final res = await http.get(
      uri,
      headers: {
        'User-Agent': 'chagas_app/1.0 (contact: dev@local)',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body);
    if (j is! Map<String, dynamic>) return null;
    return OsmPlace.fromJson(j);
  }
}
