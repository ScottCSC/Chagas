import 'package:flutter/material.dart';

/// Códigos persistidos en BD (`sexo_enum`: F, M, NI).
class SexoPaciente {
  SexoPaciente._();

  static const String femenino = 'F';
  static const String masculino = 'M';
  static const String noInformado = 'NI';

  /// Código → etiqueta visible en UI.
  static const Map<String, String> etiquetaPorCodigo = {
    femenino: 'F',
    masculino: 'M',
    noInformado: 'No informado (NI)',
  };

  static List<DropdownMenuItem<String?>> get itemsDropdown =>
      etiquetaPorCodigo.entries
          .map(
            (e) => DropdownMenuItem<String?>(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList();

  /// Solo F, M, NI o `null`. Nunca envía la etiqueta visible a la BD.
  static String? codigoParaPayload(String? seleccionOTexto) {
    if (seleccionOTexto == null) return null;
    final trimmed = seleccionOTexto.trim();
    if (trimmed.isEmpty) return null;
    final norm = normalizarDesdeBd(trimmed);
    if (norm != null) return norm;
    for (final e in etiquetaPorCodigo.entries) {
      if (e.value.toLowerCase() == trimmed.toLowerCase()) return e.key;
    }
    return null;
  }

  /// Convierte valor leído de BD al código esperado, o `null` si no coincide.
  static String? normalizarDesdeBd(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().toUpperCase();
    if (s.isEmpty) return null;
    switch (s) {
      case femenino:
        return femenino;
      case masculino:
        return masculino;
      case noInformado:
        return noInformado;
      default:
        return null;
    }
  }
}
