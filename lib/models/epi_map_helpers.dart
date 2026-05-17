DateTime? parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

int? intOf(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

/// Fecha civil sin hora (p. ej. `fecha_nacimiento` tipo `date` en PostgREST).
DateTime? parseDateOnly(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) {
    return DateTime(v.year, v.month, v.day);
  }
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  final datePart = s.split('T').first;
  final parts = datePart.split('-');
  if (parts.length >= 3) {
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
  }
  final parsed = parseDateTime(v);
  if (parsed == null) return null;
  final l = parsed.toLocal();
  return DateTime(l.year, l.month, l.day);
}
