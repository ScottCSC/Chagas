import 'package:supabase_flutter/supabase_flutter.dart';

import '../modulos_repository.dart';

class ModulosRepositorySupabase implements ModulosRepository {
  final _sb = Supabase.instance.client;

  @override
  Future<List<int>> listPersonaIds(String table) async {
    final res = await _sb.from(table).select('id_persona');
    return (res as List).map((e) => e['id_persona'] as int).toSet().toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listByPersona(String table, int idPersona) async {
    final res = await _sb.from(table).select().eq('id_persona', idPersona);
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> create(String table, Map<String, dynamic> data) async {
    await _sb.from(table).insert(data);
  }

  @override
  Future<void> update(String table, String pkColumn, dynamic pkValue, Map<String, dynamic> data) async {
    await _sb.from(table).update(data).eq(pkColumn, pkValue);
  }

  @override
  Future<List<Map<String, dynamic>>> listBajoControlRaw(List<int> personaIds) async {
    if (personaIds.isEmpty) return [];
    final res = await _sb.from('chagas_bajo_control').select('id_persona,ultimo_control,creado_en').inFilter('id_persona', personaIds);
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static const _tablas = ['chagas_bajo_control', 'chagas_gestantes', 'chagas_agudo', 'chagas_tratamiento', 'chagas_inasistentes', 'examen_chagas'];
  static const _modulos = ['BC', 'G', 'A', 'T', 'I', 'E'];

  @override
  Future<Map<int, Set<String>>> getModulosByPersonaIds(List<int> personaIds) async {
    if (personaIds.isEmpty) return {};
    final out = <int, Set<String>>{};
    final results = await Future.wait(
      _tablas.map((t) => _sb.from(t).select('id_persona').inFilter('id_persona', personaIds)),
    );
    for (var i = 0; i < results.length; i++) {
      for (final row in results[i] as List) {
        final id = row['id_persona'] as int;
        out.putIfAbsent(id, () => <String>{}).add(_modulos[i]);
      }
    }
    return out;
  }

  @override
  Future<List<Map<String, dynamic>>> listGruposByPersona(int idPersona) async {
    final res = await _sb
        .from('persona_grupo')
        .select('id, id_grupo, grupo_contacto(nombre_grupo, fecha_operativo)')
        .eq('id_persona', idPersona);
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
