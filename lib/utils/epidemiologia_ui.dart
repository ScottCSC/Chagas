import 'package:flutter/material.dart';

/// Utilidades solo-UI para el enfoque de "casos epidemiológicos" sin tocar backend.
class EpidemiologiaUi {
  EpidemiologiaUi._();

  /// Alinea `estado_caso_enum` o variantes a clave de UI: nuevo | reingreso | tratado.
  static String claveEstadoCaso(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    if (s.isEmpty) return 'nuevo';
    if (s.contains('tratad')) return 'tratado';
    if (s.contains('reingres')) return 'reingreso';
    if (s.contains('nuevo') || s == 'n' || s == 'caso_nuevo') return 'nuevo';
    if (s == 'reingreso' || s == 'tratado' || s == 'nuevo') return s;
    return s;
  }

  static Color getEstadoCasoColor(String estado) {
    final k = claveEstadoCaso(estado);
    switch (k) {
      case 'nuevo':
        return const Color(0xFF1565C0);
      case 'reingreso':
        return const Color(0xFFF9A825);
      case 'tratado':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  static String getEstadoCasoLabel(String estado) {
    final k = claveEstadoCaso(estado);
    switch (k) {
      case 'nuevo':
        return 'Caso nuevo';
      case 'reingreso':
        return 'Reingreso';
      case 'tratado':
        return 'Tratado';
      default:
        return 'No informado';
    }
  }

  static String generoLabelEpi(String? genero) {
    final s = (genero ?? '').toLowerCase().trim();
    switch (s) {
      case 'f':
      case 'femenino':
        return 'Femenino';
      case 'm':
      case 'masculino':
        return 'Masculino';
      case 'ni':
      case 'no_informado':
      case 'no_informa':
        return 'No informa';
      default:
        if (s.isEmpty) return '—';
        return (genero ?? '—');
    }
  }

  /// Cabecera de tarjeta (lista): siempre Masculino / Femenino / No informa (orientación TENS).
  static String generoTituloLista(String? genero) {
    final s = (genero ?? '').toLowerCase().trim();
    if (s.isEmpty ||
        s == 'ni' ||
        s.contains('no_inf') ||
        s.contains('no inform')) {
      return 'No informa';
    }
    if (s == 'f' || s.contains('femen') || s.contains('mujer')) {
      return 'Femenino';
    }
    if (s == 'm' || s.contains('mascul')) {
      return 'Masculino';
    }
    final fallback = generoLabelEpi(genero);
    if (fallback == '—') return 'No informa';
    return fallback;
  }
}
