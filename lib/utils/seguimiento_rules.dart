// Reglas puras (sin Supabase) para calcular estado de exámenes/controles y semáforo global.

enum Semaforo { verde, amarillo, rojo }

enum EstadoExamen { realizado, pendiente, atrasado, sinRegistro }

enum EstadoControl { alDia, proximo, vencido, sinRegistro }

class SeguimientoConstants {
  // Umbrales de control (días desde el último control)
  static const int controlAlDiaMax = 120; // < 120 días => al día
  static const int controlProximoMax = 180; // 120-180 => próximo (amarillo)
  // > 180 => vencido (rojo)
}

/// Devuelve diferencia en días (hoy - fecha). Positivo = han pasado X días.
/// Si fecha es futura, da negativo.
int diffDaysFromToday(DateTime fecha, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final d = DateTime(fecha.year, fecha.month, fecha.day);
  return today.difference(d).inDays;
}

/// -------- EXÁMENES --------
/// Reglas:
/// - Pendiente si resultado == 'Pendiente' (case-insensitive)
/// - Atrasado si pendiente y fecha_examen < hoy
/// - Realizado si resultado != 'Pendiente' y no está vacío
/// - Sin registro si no hay fecha o no hay datos
EstadoExamen estadoExamen({
  required String? resultado,
  required DateTime? fechaExamen,
  DateTime? now,
}) {
  if (fechaExamen == null) return EstadoExamen.sinRegistro;

  final r = (resultado ?? '').trim().toLowerCase();
  final isPendiente = r == 'pendiente';

  if (!isPendiente && r.isNotEmpty) return EstadoExamen.realizado;
  if (!isPendiente && r.isEmpty) {
    return EstadoExamen.pendiente;
  }

  final days = diffDaysFromToday(fechaExamen, now: now);
  return (days > 0) ? EstadoExamen.atrasado : EstadoExamen.pendiente;
}

Semaforo semaforoPorExamen(EstadoExamen e) {
  switch (e) {
    case EstadoExamen.atrasado:
      return Semaforo.rojo;
    case EstadoExamen.pendiente:
      return Semaforo.amarillo;
    case EstadoExamen.realizado:
    case EstadoExamen.sinRegistro:
      return Semaforo.verde;
  }
}

/// Texto corto para UI
String labelEstadoExamen(EstadoExamen e,
    {DateTime? fechaExamen, DateTime? now}) {
  switch (e) {
    case EstadoExamen.sinRegistro:
      return 'Sin exámenes';
    case EstadoExamen.realizado:
      return 'Realizado';
    case EstadoExamen.pendiente:
      if (fechaExamen == null) return 'Pendiente';
      final days = diffDaysFromToday(fechaExamen, now: now);
      if (days < 0) return 'Vence en ${days.abs()} días';
      return 'Pendiente';
    case EstadoExamen.atrasado:
      if (fechaExamen == null) return 'Atrasado';
      final days = diffDaysFromToday(fechaExamen, now: now);
      return 'Atrasado ${days.abs()} días';
  }
}

/// -------- CONTROL / SEGUIMIENTO --------
EstadoControl estadoControl({
  required DateTime? fechaUltimoControl,
  DateTime? now,
}) {
  if (fechaUltimoControl == null) return EstadoControl.sinRegistro;
  final days = diffDaysFromToday(fechaUltimoControl, now: now);

  if (days < 0) return EstadoControl.alDia;

  if (days < SeguimientoConstants.controlAlDiaMax) return EstadoControl.alDia;
  if (days <= SeguimientoConstants.controlProximoMax) {
    return EstadoControl.proximo;
  }
  return EstadoControl.vencido;
}

Semaforo semaforoPorControl(EstadoControl c) {
  switch (c) {
    case EstadoControl.vencido:
      return Semaforo.rojo;
    case EstadoControl.proximo:
      return Semaforo.amarillo;
    case EstadoControl.alDia:
    case EstadoControl.sinRegistro:
      return Semaforo.verde;
  }
}

String labelEstadoControl(EstadoControl c,
    {DateTime? fecha, DateTime? now}) {
  switch (c) {
    case EstadoControl.sinRegistro:
      return 'Sin control';
    case EstadoControl.alDia:
      return 'Al día';
    case EstadoControl.proximo:
      if (fecha == null) return 'Próximo';
      final days = diffDaysFromToday(fecha, now: now);
      return 'Próximo ($days días)';
    case EstadoControl.vencido:
      if (fecha == null) return 'Vencido';
      final days = diffDaysFromToday(fecha, now: now);
      return 'Vencido ($days días)';
  }
}

/// -------- SEMÁFORO GLOBAL --------
Semaforo semaforoGlobal({
  required Semaforo semExamen,
  required Semaforo semControl,
}) {
  if (semExamen == Semaforo.rojo || semControl == Semaforo.rojo) {
    return Semaforo.rojo;
  }
  if (semExamen == Semaforo.amarillo || semControl == Semaforo.amarillo) {
    return Semaforo.amarillo;
  }
  return Semaforo.verde;
}

String labelSemaforoGlobal(Semaforo s) {
  switch (s) {
    case Semaforo.verde:
      return 'Al día';
    case Semaforo.amarillo:
      return 'Pendiente';
    case Semaforo.rojo:
      return 'Atrasado';
  }
}
