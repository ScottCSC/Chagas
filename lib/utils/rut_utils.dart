class RutUtils {
  /// Limpia: deja solo números y K. Ej: "12.123.456-9" -> "121234569"
  static String limpiar(String rut) {
    return rut.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
  }

  /// Calcula DV (0-9 o K) para el cuerpo numérico
  static String calcularDV(String cuerpoNumerico) {
    int sum = 0;
    int mul = 2;

    for (int i = cuerpoNumerico.length - 1; i >= 0; i--) {
      sum += int.parse(cuerpoNumerico[i]) * mul;
      mul = (mul == 7) ? 2 : mul + 1;
    }

    final res = 11 - (sum % 11);
    if (res == 11) return '0';
    if (res == 10) return 'K';
    return res.toString();
  }

  /// Valida rut completo con DV. Acepta "12123456-9" o "12.123.456-9"
  static bool esValido(String rut) {
    final r = limpiar(rut);
    if (r.length < 2) return false;

    final cuerpo = r.substring(0, r.length - 1);
    final dv = r.substring(r.length - 1);

    if (!RegExp(r'^\d+$').hasMatch(cuerpo)) return false;

    final dvCalc = calcularDV(cuerpo);
    return dv == dvCalc;
  }

  /// Formatea para UI: "12123456-9" -> "12.123.456-9"
  static String formatearParaUI(String rut) {
    final r = limpiar(rut);
    if (r.length < 2) return rut;

    final cuerpo = r.substring(0, r.length - 1);
    final dv = r.substring(r.length - 1);

    final sb = StringBuffer();
    for (int i = 0; i < cuerpo.length; i++) {
      sb.write(cuerpo[i]);
      final idxFromEnd = cuerpo.length - i;
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) sb.write('.');
    }
    return '${sb.toString()}-$dv';
  }

  /// Normaliza para BD: "12.123.456-9" -> "12123456-9"
  static String normalizarParaBD(String rut) {
    final r = limpiar(rut);
    if (r.length < 2) return rut;

    final cuerpo = r.substring(0, r.length - 1);
    final dv = r.substring(r.length - 1);
    return '$cuerpo-$dv';
  }
}
