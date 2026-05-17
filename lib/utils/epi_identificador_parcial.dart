/// Normaliza el identificador parcial (últimos 3 dígitos del RUT + DV), sin almacenar RUT completo.
/// Solo uso epidemiológico para posible detección de duplicados.
String normalizarIdentificadorParcial(String input) {
  var value = input.trim().toUpperCase();
  value = value.replaceAll('.', '').replaceAll(' ', '');
  value = value.replaceAll(RegExp(r'\s+'), '');

  if (!value.contains('-') && value.length == 4) {
    value = '${value.substring(0, 3)}-${value.substring(3)}';
  }

  return value;
}

String? validarIdentificadorParcial(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Ingrese identificador parcial';
  }

  final regex = RegExp(r'^\d{3}-[\dK]$');

  if (!regex.hasMatch(value.trim().toUpperCase())) {
    return 'Formato esperado: 123-4 o 123-K';
  }

  return null;
}
