import '../models/examen.dart';

/// Repositorio de exámenes (examen_chagas). Interfaz lista para offline/cache.
abstract class ExamenRepository {
  Future<Examen?> get(int id);
  Future<List<Examen>> list({
    int? idPersona,
    int limit = 500,
  });
  Future<Examen> create(Examen examen);
  Future<void> update(int id, Examen examen);
  /// Actualización parcial (solo los campos enviados).
  Future<void> updatePartial(int id, Map<String, dynamic> data);
  /// Exámenes pendientes (resultado = 'pendiente'). Para estadísticas Home.
  Future<List<Examen>> listPendientes();

  /// Filas crudas para agregación (id_persona, fecha_examen, resultado, creado_en). Para resume.
  Future<List<Map<String, dynamic>>> listRawForPersonaIds(List<int> personaIds);
}
