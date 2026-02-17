/// Repositorio de módulos (bajo_control, gestantes, tratamiento, inasistentes, agudo).
/// Lista ids por tabla y datos por persona para Detalle. Interfaz lista para offline.
abstract class ModulosRepository {
  /// Ids de persona que tienen al menos un registro en la tabla.
  Future<List<int>> listPersonaIds(String table);
  /// Lista de registros (maps) para una persona en la tabla.
  Future<List<Map<String, dynamic>>> listByPersona(String table, int idPersona);
  Future<void> create(String table, Map<String, dynamic> data);
  Future<void> update(String table, String pkColumn, dynamic pkValue, Map<String, dynamic> data);

  /// Filas crudas de chagas_bajo_control (id_persona, ultimo_control, creado_en) para resume.
  Future<List<Map<String, dynamic>>> listBajoControlRaw(List<int> personaIds);

  /// Para cada id_persona, set de códigos de módulo (BC, G, A, T, I, E). Para VerScreen.
  Future<Map<int, Set<String>>> getModulosByPersonaIds(List<int> personaIds);

  /// Grupos/operativos de una persona (persona_grupo + grupo_contacto). Para DetallePersona.
  Future<List<Map<String, dynamic>>> listGruposByPersona(int idPersona);
}
