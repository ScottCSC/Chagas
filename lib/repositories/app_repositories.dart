import 'catalogo_repository.dart';
import 'caso_epidemiologico_repository.dart';
import 'profile_repository.dart';
import 'sector_repository.dart';
import 'impl/catalogo_repository_supabase.dart';
import 'impl/caso_epidemiologico_repository_supabase.dart';
import 'impl/profile_repository_supabase.dart';
import 'impl/sector_repository_supabase.dart';

/// Punto único de acceso a repositorios. Cambiar aquí la implementación (Supabase vs offline).
class AppRepositories {
  AppRepositories._();

  static final CasoEpidemiologicoRepository casoEpidemiologico =
      CasoEpidemiologicoRepositorySupabase();
  static final SectorRepository sector = SectorRepositorySupabase();
  static final ProfileRepository profile = ProfileRepositorySupabase();
  static final CatalogoRepository catalogo = CatalogoRepositorySupabase();
}
