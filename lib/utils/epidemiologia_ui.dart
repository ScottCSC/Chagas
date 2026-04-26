import 'package:flutter/material.dart';

/// Utilidades solo-UI para el enfoque de "casos epidemiológicos" sin tocar backend.
class EpidemiologiaUi {
  EpidemiologiaUi._();

  /// Código visible estilo CHG-2026-0001 basado en `idPersona` (temporal hasta tener tabla propia).
  static String codigoCaso({
    required int idPersona,
    DateTime? createdAt,
  }) {
    final year = (createdAt ?? DateTime.now()).year;
    final n = idPersona.toString().padLeft(4, '0');
    return 'CHG-$year-$n';
  }

  /// Estado epidemiológico derivado (heurística temporal).
  /// - tratado: si tiene módulo Tratamiento
  /// - reingreso: si tiene Bajo control
  /// - nuevo: por defecto
  static String estadoCasoFromModulos(Set<String> modulos) {
    if (modulos.contains('T')) return 'tratado';
    if (modulos.contains('BC')) return 'reingreso';
    return 'nuevo';
  }

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
        return 'No informado';
      default:
        if (s.isEmpty) return '—';
        return (genero ?? '—');
    }
  }

  static String rangoEdadFromEdad(int? edad) {
    if (edad == null) return 'No informado';
    if (edad < 0) return 'No informado';
    if (edad <= 9) return '0–9';
    if (edad <= 19) return '10–19';
    if (edad <= 29) return '20–29';
    if (edad <= 39) return '30–39';
    if (edad <= 49) return '40–49';
    if (edad <= 59) return '50–59';
    if (edad <= 69) return '60–69';
    return '70+';
  }

  static String sexoLabelFromCodigo(String? sexo) {
    final s = (sexo ?? '').trim().toUpperCase();
    switch (s) {
      case 'F':
        return 'Femenino';
      case 'M':
        return 'Masculino';
      case 'NI':
        return 'No informado';
      default:
        return 'No informado';
    }
  }
}

