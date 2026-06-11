import '../models/ocupacion_catalogo.dart';

abstract class CatalogoRepository {
  Future<List<OcupacionCatalogo>> getOcupacionesActivas();
}
