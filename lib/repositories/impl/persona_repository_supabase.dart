import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/persona.dart';
import '../persona_repository.dart';

class PersonaRepositorySupabase implements PersonaRepository {
  final _sb = Supabase.instance.client;

  @override
  Future<Persona?> get(int idPersona) async {
    final res = await _sb
        .from('persona')
        .select()
        .eq('id_persona', idPersona)
        .maybeSingle();
    if (res == null) return null;
    return Persona.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<List<Persona>> list({List<int>? ids, int limit = 200}) async {
    var q = _sb.from('persona').select();
    if (ids != null && ids.isNotEmpty) {
      q = q.inFilter('id_persona', ids);
    }
    final res = await q.order('actualizado_en', ascending: false, nullsFirst: false).order('creado_en', ascending: false, nullsFirst: false).order('id_persona', ascending: false).limit(limit).timeout(const Duration(seconds: 10));
    return (res as List).map((e) => Persona.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<Persona> create(Persona persona) async {
    final res = await _sb.from('persona').insert(persona.toPayload()).select().single();
    return Persona.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<void> update(int idPersona, Persona persona) async {
    await _sb.from('persona').update(persona.toPayload()).eq('id_persona', idPersona);
  }

  @override
  Future<int> count() async {
    final res = await _sb.from('persona').select('id_persona').limit(500);
    return (res as List).length;
  }
}
