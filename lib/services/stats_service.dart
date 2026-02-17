import 'package:supabase_flutter/supabase_flutter.dart';

/// KPIs para Home. Si la tabla persona no tiene creado_en, hoy/semana serán 0.
class StatsService {
  static final _sb = Supabase.instance.client;

  static Future<Map<String, int>> getHomeStats() async {
    int total = 0;
    int hoy = 0;
    int semana = 0;
    int operativos = 0;

    try {
      final totalRows = await _sb.from('persona').select('id_persona');
      total = (totalRows as List).length;
    } catch (_) {}

    try {
      final hoyDate = DateTime.now();
      final startHoy = DateTime(hoyDate.year, hoyDate.month, hoyDate.day).toUtc().toIso8601String();
      final hoyRows = await _sb.from('persona').select('id_persona').gte('creado_en', startHoy);
      hoy = (hoyRows as List).length;
    } catch (_) {}

    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final startWeek = DateTime(weekAgo.year, weekAgo.month, weekAgo.day).toUtc().toIso8601String();
      final semanaRows = await _sb.from('persona').select('id_persona').gte('creado_en', startWeek);
      semana = (semanaRows as List).length;
    } catch (_) {}

    try {
      final operRows = await _sb.from('grupo_contacto').select('id_grupo');
      operativos = (operRows as List).length;
    } catch (_) {}

    int sinControl = 0;
    int examenesPendientes = 0;
    int examenesAtrasados = 0;
    try {
      final ina = await _sb.from('chagas_inasistentes').select('id');
      sinControl = (ina as List).length;
    } catch (_) {}
    try {
      // Pendientes: resultado ilike 'pendiente'
      final hoy = DateTime.now();
      final hoyStr =
          DateTime(hoy.year, hoy.month, hoy.day).toIso8601String().split('T')[0];

      final examPend = await _sb
          .from('examen_chagas')
          .select('id, fecha_examen')
          .ilike('resultado', 'pendiente');
      final pendList = (examPend as List);
      examenesPendientes = pendList.length;

      final atras = pendList.where((e) {
        final f = e['fecha_examen']?.toString();
        if (f == null || f.isEmpty) return false;
        return f.compareTo(hoyStr) < 0;
      }).toList();
      examenesAtrasados = atras.length;
    } catch (_) {}

    return {
      'total': total,
      'hoy': hoy,
      'semana': semana,
      'operativos': operativos,
      'sinControl': sinControl,
      'examenesPendientes': examenesPendientes,
      'examenesAtrasados': examenesAtrasados,
    };
  }
}
