import '../widgets/patient_clinical_list_card.dart';

DateTime? parseClinicalDate(dynamic v) {
  if (v == null) return null;
  try {
    final s = v.toString();
    if (s.length >= 10) {
      return DateTime.parse(s.substring(0, 10));
    }
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

String formatClinicalDay(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Semáforo según fecha de próximo control (bajo control).
PatientVisualStatus statusFromProximoControl(dynamic proximoRaw) {
  final prox = parseClinicalDate(proximoRaw);
  if (prox == null) return PatientVisualStatus.upToDate;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(prox.year, prox.month, prox.day);
  if (d.isBefore(today)) return PatientVisualStatus.overdue;
  if (d.difference(today).inDays <= 14) {
    return PatientVisualStatus.upcoming;
  }
  return PatientVisualStatus.upToDate;
}

PatientVisualStatus statusFromPartoAprox(dynamic partoRaw) {
  final p = parseClinicalDate(partoRaw);
  if (p == null) return PatientVisualStatus.upToDate;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(p.year, p.month, p.day);
  if (d.isBefore(today)) return PatientVisualStatus.overdue;
  if (d.difference(today).inDays <= 30) {
    return PatientVisualStatus.upcoming;
  }
  return PatientVisualStatus.upToDate;
}
