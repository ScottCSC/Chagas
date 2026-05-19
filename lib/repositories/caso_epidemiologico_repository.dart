import '../models/caso_epidemiologico.dart';
import '../models/historial_estado_caso.dart';

abstract class CasoEpidemiologicoRepository {
  Future<List<CasoEpidemiologico>> getCasos({int limit = 500});

  Future<CasoEpidemiologico?> getCasoById(int idCaso);

  Future<CasoEpidemiologico> createCaso(CasoEpidemiologico caso);

  Future<void> updateCaso(CasoEpidemiologico caso);

  /// Actualiza solo `estado_actual`; el trigger `trg_historial_estado` registra el cambio.
  Future<CasoEpidemiologico> updateEstadoCaso({
    required int idCaso,
    required String estadoActual,
  });

  /// Actualiza solo `observacion_general`; pasar `null` para limpiar.
  Future<CasoEpidemiologico> updateObservacionCaso({
    required int idCaso,
    required String? observacionGeneral,
  });

  /// Actualiza datos epidemiológicos editables (no toca estado ni observación; no dispara historial).
  Future<CasoEpidemiologico> updateDatosCaso({
    required int idCaso,
    required String identificadorParcial,
    required String genero,
    required DateTime fechaNacimiento,
    required String? ocupacion,
    required int numeroContactos,
  });

  Future<void> deleteCaso(int idCaso);

  Future<List<HistorialEstadoCaso>> getHistorialEstado(int idCaso);

  /// Posibles duplicados por identificador parcial + fecha nacimiento + género + sector.
  /// Requiere columnas en Supabase (`identificador_parcial`, `fecha_nacimiento`); activar flags en [epi_db_constants].
  Future<List<CasoEpidemiologico>> buscarPosiblesDuplicados({
    required String identificadorParcial,
    required DateTime fechaNacimiento,
    required String genero,
    required int idSector,
  });
}
