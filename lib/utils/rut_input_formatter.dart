import 'package:flutter/services.dart';

class RutInputFormatter extends TextInputFormatter {
  static const int maxBodyDigits = 8; // cuerpo
  static const int maxTotal = 9; // cuerpo + DV

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1) Normalizar (K mayúscula)
    var raw = newValue.text.toUpperCase();

    // 2) Dejar solo [0-9K]
    raw = raw.replaceAll(RegExp(r'[^0-9K]'), '');

    // 3) Si hay más de una K, deja solo la primera
    final firstK = raw.indexOf('K');
    if (firstK != -1) {
      raw = raw.replaceAll('K', '');
      raw = raw.substring(0, firstK) + 'K';
    }

    // 4) Si hay K, obligarla a estar al final
    if (raw.contains('K') && !raw.endsWith('K')) {
      raw = raw.replaceAll('K', '') + 'K';
    }

    // 5) Límite duro: máximo 9 chars totales (8 cuerpo + 1 DV)
    if (raw.length > maxTotal) {
      raw = raw.substring(0, maxTotal);
    }

    // 6) El cuerpo no puede pasar de 8 dígitos (si el 9no es K o número = DV)
    //    Si el usuario pega 1234567890, lo cortamos a 9 totales arriba.
    //    Pero si pega 123456789K (10), ya quedó cortado.

    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // 7) Formatear visible
    final formatted = formatRut(raw);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// raw: "12345678K" o "123456789" o "1" etc
  static String formatRut(String raw) {
    if (raw.isEmpty) return '';

    // si aún no hay DV, solo mostrar cuerpo con puntos
    if (raw.length == 1) return raw;

    final dv = raw.substring(raw.length - 1); // último char (0-9 o K)
    final body = raw.substring(0, raw.length - 1);

    final withDots = _addThousandsDots(body);
    return '$withDots-$dv';
  }

  static String _addThousandsDots(String digits) {
    if (digits.isEmpty) return '';
    
    // Dividir en grupos de 3 desde el final del string original
    final parts = <String>[];
    final length = digits.length;
    
    // Procesar desde el final hacia el inicio
    for (int i = length; i > 0; i -= 3) {
      final start = (i - 3 > 0) ? i - 3 : 0;
      parts.insert(0, digits.substring(start, i));
    }
    
    // Unir con puntos
    return parts.join('.');
  }

  /// Para guardar en BD como "12345678K" o "123456789"
  static String clean(String formatted) {
    return formatted.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
  }
}
