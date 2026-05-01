import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/sector.dart';
import '../sector_repository.dart';

class SectorRepositorySupabase implements SectorRepository {
  final _sb = Supabase.instance.client;

  @override
  Future<List<Sector>> getSectoresActivos({int limit = 500}) async {
    final res = await _sb
        .from('sectores')
        .select(
          'id_sector, nombre_sector, comuna, latitud_centroide, longitud_centroide, activo',
        )
        .eq('activo', true)
        .order('nombre_sector')
        .limit(limit)
        .timeout(const Duration(seconds: 15));
    return (res as List)
        .map((e) => Sector.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Sector?> getSectorById(int idSector) async {
    final res = await _sb.from('sectores').select().eq('id_sector', idSector).maybeSingle();
    if (res == null) return null;
    return Sector.fromMap(Map<String, dynamic>.from(res));
  }

  @override
  Future<List<Sector>> getSectoresByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final res = await _sb.from('sectores').select().inFilter('id_sector', ids);
    return (res as List)
        .map((e) => Sector.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
