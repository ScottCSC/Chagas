import '../models/caso_epidemiologico.dart';
import '../models/historial_estado_caso.dart';

abstract class CasoEpidemiologicoRepository {
  Future<List<CasoEpidemiologico>> getCasos({int limit = 500});

  Future<CasoEpidemiologico?> getCasoById(int idCaso);

  Future<CasoEpidemiologico> createCaso(CasoEpidemiologico caso);

  Future<void> updateCaso(CasoEpidemiologico caso);

  Future<void> deleteCaso(int idCaso);

  Future<List<HistorialEstadoCaso>> getHistorialEstado(int idCaso);
}
