import 'package:flutter/foundation.dart';

/// Convierte cualquier error técnico (Supabase, red, RLS, etc.) en un mensaje
/// orientado al usuario final, sin exponer detalles internos.
String mensajeErrorUsuario(Object e) {
  final s = e.toString().toLowerCase();

  if (s.contains('socket') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('clientexception') ||
      s.contains('connection') ||
      s.contains('timeout')) {
    return 'Sin conexión. Revise su internet e intente nuevamente.';
  }

  if (s.contains('jwt') &&
      (s.contains('expired') || s.contains('invalid') || s.contains('malformed'))) {
    return 'Su sesión expiró. Inicie sesión nuevamente.';
  }

  if (s.contains('row-level security') ||
      s.contains(' rls ') ||
      s.contains('permission denied') ||
      s.contains('not authorized') ||
      s.contains('42501')) {
    return 'No tiene permisos para realizar esta acción.';
  }

  if (s.contains('foreign key') || s.contains('23503')) {
    return 'Referencia inválida. Actualice la información e intente de nuevo.';
  }

  if (s.contains('unique') || s.contains('duplicate') || s.contains('23505')) {
    return 'El registro ya existe.';
  }

  debugPrint('mensajeErrorUsuario: $e');
  return 'Ocurrió un error inesperado. Intente nuevamente.';
}

/// Determina si el error proviene de una sesión Supabase expirada o inválida.
bool esSesionExpirada(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('jwt') &&
      (s.contains('expired') || s.contains('invalid') || s.contains('malformed'));
}
