import 'package:flutter/services.dart';

/// Inserta el guion tras 3 dígitos y limita a `NNN-DV` (máx. 5 caracteres visibles).
/// Solo permite dígitos y `K` como dígito verificador.
class IdentificadorParcialInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = newValue.text.toUpperCase();

    raw = raw.replaceAll(RegExp(r'[^0-9K]'), '');

    if (raw.length > 4) {
      raw = raw.substring(0, 4);
    }

    var numeros = '';
    var dv = '';

    for (final char in raw.split('')) {
      if (numeros.length < 3) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          numeros += char;
        }
      } else {
        if (RegExp(r'[0-9K]').hasMatch(char)) {
          dv = char;
          break;
        }
      }
    }

    var formatted = numeros;
    if (numeros.length == 3 && dv.isNotEmpty) {
      formatted = '$numeros-$dv';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
