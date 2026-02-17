/// Estadísticas para Home. Implementación actual: Supabase.
abstract class StatsRepository {
  Future<Map<String, int>> getHomeStats();
}
