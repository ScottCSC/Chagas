import '../models/paciente_resume.dart';
import '../repositories/app_repositories.dart';
import '../utils/seguimiento_rules.dart';

/// Servicio que obtiene resúmenes clínicos por paciente (último examen, último control, semáforo)
/// usando repositorios (sin Supabase directo). Agregación en cliente.
class PacientesResumeService {
  final _personaRepo = AppRepositories.persona;
  final _examenRepo = AppRepositories.examen;
  final _modulosRepo = AppRepositories.modulos;

  Future<List<PacienteResume>> fetchResumes({
    String? query,
    List<int>? idPersonasFilter,
  }) async {
    final listPersonas = await _personaRepo.list(
      ids: idPersonasFilter?.isNotEmpty == true ? idPersonasFilter : null,
      limit: 200,
    );
    if (listPersonas.isEmpty) return [];

    final ids = listPersonas.map((p) => p.idPersona).whereType<int>().toList();

    final results = await Future.wait([
      _examenRepo.listRawForPersonaIds(ids),
      _modulosRepo.listBajoControlRaw(ids),
    ]);
    final rawExamenes = results[0];
    final rawBajoControl = results[1];

    final lastExamByPerson = <int, _LastExam>{};
    for (final row in rawExamenes) {
      final id = row['id_persona'] as int?;
      if (id == null) continue;
      final fechaExamen = _parseDate(row['fecha_examen']);
      final creado = _parseDate(row['creado_en']);
      final fecha = fechaExamen ?? creado;
      if (fecha == null) continue;
      final resultado = row['resultado']?.toString();
      final current = lastExamByPerson[id];
      if (current == null || fecha.isAfter(current.fecha)) {
        lastExamByPerson[id] = _LastExam(fecha: fecha, resultado: resultado);
      }
    }

    final lastControlByPerson = <int, DateTime>{};
    for (final row in rawBajoControl) {
      final id = row['id_persona'] as int?;
      if (id == null) continue;
      final ultimo = _parseDate(row['ultimo_control']);
      final creado = _parseDate(row['creado_en']);
      final fecha = ultimo ?? creado;
      if (fecha == null) continue;
      final current = lastControlByPerson[id];
      if (current == null || fecha.isAfter(current)) {
        lastControlByPerson[id] = fecha;
      }
    }

    final now = DateTime.now();
    final resumes = <PacienteResume>[];

    for (final p in listPersonas) {
      final idPersona = p.idPersona;
      if (idPersona == null) continue;

      final nombre = p.nombre ?? '';
      final lastExam = lastExamByPerson[idPersona];
      final fechaExamen = lastExam?.fecha;
      final resultadoExamen = lastExam?.resultado;
      final lastControlDate = lastControlByPerson[idPersona];

      final e = estadoExamen(
        resultado: resultadoExamen,
        fechaExamen: fechaExamen,
        now: now,
      );
      final c = estadoControl(
        fechaUltimoControl: lastControlDate,
        now: now,
      );
      final semE = semaforoPorExamen(e);
      final semC = semaforoPorControl(c);
      final semGlobal = semaforoGlobal(semExamen: semE, semControl: semC);

      resumes.add(PacienteResume(
        idPersona: idPersona,
        nombre: nombre,
        rut: p.rut,
        comuna: p.comuna,
        provincia: p.provincia,
        telefono: p.telefono,
        lastExamDate: fechaExamen,
        lastExamStatus: e,
        lastExamLabel: labelEstadoExamen(e, fechaExamen: fechaExamen, now: now),
        lastControlDate: lastControlDate,
        lastControlStatus: c,
        lastControlLabel: labelEstadoControl(c, fecha: lastControlDate, now: now),
        overallStatus: semGlobal,
        overallLabel: labelSemaforoGlobal(semGlobal),
      ));
    }

    if (query != null && query.trim().isNotEmpty) {
      final qLower = query.trim().toLowerCase();
      return resumes.where((r) {
        final nombre = (r.nombre).toLowerCase();
        final rut = (r.rut ?? '').toLowerCase();
        return nombre.contains(qLower) || rut.contains(qLower);
      }).toList();
    }
    return resumes;
  }

  Future<PacienteResume?> fetchResumeForPerson(int idPersona) async {
    final list = await fetchResumes(idPersonasFilter: [idPersona]);
    return list.isNotEmpty ? list.first : null;
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

class _LastExam {
  final DateTime fecha;
  final String? resultado;
  _LastExam({required this.fecha, this.resultado});
}
