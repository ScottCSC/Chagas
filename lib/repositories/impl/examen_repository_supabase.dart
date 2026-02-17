import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/examen.dart';
import '../examen_repository.dart';

class ExamenRepositorySupabase implements ExamenRepository {
  final _sb = Supabase.instance.client;

  @override
  Future<Examen?> get(int id) async {
    final res = await _sb.from('examen_chagas').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return Examen.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<List<Examen>> list({int? idPersona, int limit = 500}) async {
    var q = _sb.from('examen_chagas').select('''
      id,
      id_persona,
      fecha_examen,
      tipo_examen,
      resultado,
      laboratorio,
      observacion,
      creado_en,
      persona (id_persona, nombre, rut)
    ''');
    if (idPersona != null) {
      q = q.eq('id_persona', idPersona);
    }
    final res = await q.order('fecha_examen', ascending: true).limit(limit);
    return (res as List).map((e) => Examen.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<Examen> create(Examen examen) async {
    final res = await _sb.from('examen_chagas').insert(examen.toPayload()).select().single();
    return Examen.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<void> update(int id, Examen examen) async {
    final payload = <String, dynamic>{
      if (examen.resultado != null) 'resultado': examen.resultado,
      if (examen.laboratorio != null) 'laboratorio': examen.laboratorio,
      if (examen.observacion != null) 'observacion': examen.observacion,
    };
    if (payload.isEmpty) return;
    await _sb.from('examen_chagas').update(payload).eq('id', id);
  }

  @override
  Future<void> updatePartial(int id, Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    await _sb.from('examen_chagas').update(data).eq('id', id);
  }

  @override
  Future<List<Examen>> listPendientes() async {
    final res = await _sb.from('examen_chagas').select('id, fecha_examen, resultado').ilike('resultado', 'pendiente');
    return (res as List).map((e) => Examen.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listRawForPersonaIds(List<int> personaIds) async {
    if (personaIds.isEmpty) return [];
    final res = await _sb.from('examen_chagas').select('id_persona,fecha_examen,resultado,creado_en').inFilter('id_persona', personaIds);
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
