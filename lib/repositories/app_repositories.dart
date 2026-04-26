import 'caso_epidemiologico_repository.dart';
import 'examen_repository.dart';
import 'modulos_repository.dart';
import 'persona_repository.dart';
import 'sector_repository.dart';
import 'stats_repository.dart';
import 'impl/caso_epidemiologico_repository_supabase.dart';
import 'impl/examen_repository_supabase.dart';
import 'impl/modulos_repository_supabase.dart';
import 'impl/persona_repository_supabase.dart';
import 'impl/sector_repository_supabase.dart';
import 'impl/stats_repository_supabase.dart';

/// Punto único de acceso a repositorios. Cambiar aquí la implementación (Supabase vs offline).
class AppRepositories {
  AppRepositories._();

  static final PersonaRepository persona = PersonaRepositorySupabase();
  static final ExamenRepository examen = ExamenRepositorySupabase();
  static final ModulosRepository modulos = ModulosRepositorySupabase();
  static final StatsRepository stats = StatsRepositorySupabase();
  static final CasoEpidemiologicoRepository casoEpidemiologico = CasoEpidemiologicoRepositorySupabase();
  static final SectorRepository sector = SectorRepositorySupabase();
}
