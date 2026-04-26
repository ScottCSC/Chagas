import 'package:supabase_flutter/supabase_flutter.dart';

import '../stats_repository.dart';

class StatsRepositorySupabase implements StatsRepository {
  final _sb = Supabase.instance.client;

  @override
  Future<Map<String, int>> getHomeStats() async {
    int total = 0, hoy = 0, semana = 0, operativos = 0, sectoresActivos = 0;
    int sinControl = 0, examenesPendientes = 0, examenesAtrasados = 0;

    // KPIs de casos epidemiológicos (tabla real; si falla RLS/typo, queda 0)
    try {
      final totalRows = await _sb.from('casos_epidemiologicos').select('id_caso');
      total = (totalRows as List).length;
    } catch (_) {}

    try {
      final hoyDate = DateTime.now();
      final startHoy = DateTime(hoyDate.year, hoyDate.month, hoyDate.day).toUtc().toIso8601String();
      final hoyRows = await _sb
          .from('casos_epidemiologicos')
          .select('id_caso')
          .gte('fecha_registro', startHoy);
      hoy = (hoyRows as List).length;
    } catch (_) {}

    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final startWeek = DateTime(weekAgo.year, weekAgo.month, weekAgo.day).toUtc().toIso8601String();
      final semanaRows = await _sb
          .from('casos_epidemiologicos')
          .select('id_caso')
          .gte('fecha_registro', startWeek);
      semana = (semanaRows as List).length;
    } catch (_) {}

    // Compat: operativos (grupos) + sectores activos
    try {
      final operRows = await _sb.from('grupo_contacto').select('id_grupo');
      operativos = (operRows as List).length;
    } catch (_) {}

    try {
      final sec = await _sb.from('sectores').select('id_sector').eq('activo', true);
      sectoresActivos = (sec as List).length;
    } catch (_) {}

    try {
      final ina = await _sb.from('chagas_inasistentes').select('id');
      sinControl = (ina as List).length;
    } catch (_) {}

    try {
      final examPend = await _sb.from('examen_chagas').select('id, fecha_examen').ilike('resultado', 'pendiente');
      final pendList = examPend as List;
      examenesPendientes = pendList.length;
      final hoyStr = DateTime.now().toIso8601String().split('T')[0];
      examenesAtrasados = pendList.where((e) {
        final f = e['fecha_examen']?.toString();
        return f != null && f.isNotEmpty && f.compareTo(hoyStr) < 0;
      }).length;
    } catch (_) {}

    return {
      'total': total,
      'hoy': hoy,
      'semana': semana,
      'operativos': operativos,
      'sectoresActivos': sectoresActivos,
      'sinControl': sinControl,
      'examenesPendientes': examenesPendientes,
      'examenesAtrasados': examenesAtrasados,
    };
  }
}
