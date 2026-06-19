import '../models/sector.dart';

/// Sectores territoriales habilitados para registro en Monte Patria.
/// Orden de presentación en formularios y filtros.
const List<String> kSectoresTerritorialesPermitidos = [
  'Chañaral Alto',
  'El Palqui',
  'Monte Patria',
  'Carén',
];

String _claveNombreSector(String nombre) {
  return nombre
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
}

final Set<String> _clavesSectoresPermitidos = {
  for (final n in kSectoresTerritorialesPermitidos) _claveNombreSector(n),
  // Variantes frecuentes en BD legado
  'caren',
};

/// Indica si [nombreSector] corresponde a uno de los sectores territoriales del piloto.
bool esSectorTerritorialPermitido(String nombreSector) {
  return _clavesSectoresPermitidos.contains(_claveNombreSector(nombreSector));
}

int _ordenSector(Sector s) {
  final clave = _claveNombreSector(s.nombreSector);
  for (var i = 0; i < kSectoresTerritorialesPermitidos.length; i++) {
    if (_claveNombreSector(kSectoresTerritorialesPermitidos[i]) == clave) {
      return i;
    }
  }
  // Carén sin tilde u otras variantes ya incluidas en el set
  if (clave == 'caren') return 3;
  return 999;
}

/// Filtra y ordena sectores activos según [kSectoresTerritorialesPermitidos].
List<Sector> filtrarSectoresTerritorialesPermitidos(List<Sector> sectores) {
  final filtrados =
      sectores.where((s) => esSectorTerritorialPermitido(s.nombreSector)).toList();
  filtrados.sort((a, b) => _ordenSector(a).compareTo(_ordenSector(b)));
  return filtrados;
}
