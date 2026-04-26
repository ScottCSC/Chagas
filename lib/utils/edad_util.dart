/// Cálculo de edad y utilidades de fecha de nacimiento (sin dependencia de intl).
class EdadUtil {
  EdadUtil._();

  /// Edad en años cumplidos a la fecha de hoy.
  static int calcularEdad(DateTime fechaNacimiento) {
    final hoy = DateTime.now();
    var edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  /// Fecha sin hora (solo día en local).
  static DateTime? parseSoloFecha(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) {
      return DateTime(v.year, v.month, v.day);
    }
    final d = DateTime.tryParse(v.toString());
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }

  static bool mismaFechaCalendario(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// `YYYY-MM-DD` para columnas `date` en Postgres.
  static String? aIsoFecha(DateTime? d) {
    if (d == null) return null;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String formatoDiaMesAnio(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
