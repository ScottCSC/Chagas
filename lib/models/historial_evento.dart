import 'package:flutter/material.dart';

/// Un renglón del historial clínico agregado (solo lectura, sin cambiar schema).
class HistorialEvento {
  final DateTime fecha;
  final String tipo;
  final String detalle;
  final IconData icono;

  const HistorialEvento({
    required this.fecha,
    required this.tipo,
    required this.detalle,
    required this.icono,
  });
}
