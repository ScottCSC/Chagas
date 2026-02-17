import '../utils/seguimiento_rules.dart';

/// Resumen clínico por paciente: última acción (examen/control) y semáforo global.
class PacienteResume {
  final int idPersona;
  final String nombre;
  final String? rut;
  final String? comuna;
  final String? provincia;
  final String? telefono;

  final DateTime? lastExamDate;
  final EstadoExamen lastExamStatus;
  final String lastExamLabel;

  final DateTime? lastControlDate;
  final EstadoControl lastControlStatus;
  final String lastControlLabel;

  final Semaforo overallStatus;
  final String overallLabel;

  const PacienteResume({
    required this.idPersona,
    required this.nombre,
    this.rut,
    this.comuna,
    this.provincia,
    this.telefono,
    this.lastExamDate,
    required this.lastExamStatus,
    required this.lastExamLabel,
    this.lastControlDate,
    required this.lastControlStatus,
    required this.lastControlLabel,
    required this.overallStatus,
    required this.overallLabel,
  });
}
