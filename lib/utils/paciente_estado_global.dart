import '../models/paciente_resume.dart';
import 'seguimiento_rules.dart';

/// Título corto alineado con semáforo global (Al día / Pendiente / Atrasado).
String tituloEstadoGlobal(Semaforo s) => labelSemaforoGlobal(s);

/// Texto clínico adicional según examen + control (reutiliza [PacienteResume]).
String detalleEstadoGlobalClinico(PacienteResume r) {
  final e = r.lastExamStatus;
  final c = r.lastControlStatus;

  if (r.overallStatus == Semaforo.rojo) {
    final parts = <String>[];
    if (e == EstadoExamen.atrasado) parts.add('Examen atrasado');
    if (c == EstadoControl.vencido) parts.add('Control pendiente');
    if (parts.isEmpty) return 'Requiere revisión de seguimiento';
    return parts.join(' · ');
  }

  if (r.overallStatus == Semaforo.amarillo) {
    final parts = <String>[];
    if (e == EstadoExamen.pendiente) parts.add('Examen pendiente');
    if (c == EstadoControl.proximo) parts.add('Control próximo a vencer');
    if (parts.isEmpty) return 'Seguimiento con observación';
    return parts.join(' · ');
  }

  return 'Seguimiento al día';
}
