import '../models/sector.dart';

abstract class SectorRepository {
  Future<List<Sector>> getSectoresActivos({int limit = 500});

  Future<Sector?> getSectorById(int idSector);

  /// Para desplegar nombres en listados aunque el sector quede inactivo después.
  Future<List<Sector>> getSectoresByIds(List<int> ids);
}
