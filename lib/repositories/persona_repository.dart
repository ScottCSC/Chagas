import '../models/persona.dart';

/// Repositorio de personas. Implementación actual: Supabase; interfaz lista para offline/cache.
abstract class PersonaRepository {
  Future<Persona?> get(int idPersona);
  Future<List<Persona>> list({
    List<int>? ids,
    int limit = 200,
  });
  Future<Persona> create(Persona persona);
  Future<void> update(int idPersona, Persona persona);
  /// Cuenta total (para chips/estadísticas). Opcional para implementación offline.
  Future<int> count();
}
