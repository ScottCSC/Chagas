import 'package:flutter/material.dart';

import '../models/examen.dart';
import '../models/historial_evento.dart';

/// Historial cronológico agregado desde filas ya cargadas (sin nuevas queries).
class HistorialPacienteService {
  const HistorialPacienteService();

  /// Construye eventos ordenados por fecha descendente a partir de listas del detalle.
  List<HistorialEvento> buildFromDatos({
    required List<Examen> examenes,
    required List<Map<String, dynamic>> inasistencias,
    required List<Map<String, dynamic>> bajoControl,
    required List<Map<String, dynamic>> tratamiento,
    required List<Map<String, dynamic>> gestantes,
    required List<Map<String, dynamic>> agudo,
  }) {
    final out = <HistorialEvento>[];

    for (final ex in examenes) {
      final fecha = _firstDate([ex.fechaExamen, ex.creadoEn]);
      if (fecha == null) continue;
      final tipoEx = (ex.tipoExamen ?? 'Examen').trim();
      final res = (ex.resultado ?? '—').trim();
      out.add(HistorialEvento(
        fecha: fecha,
        tipo: 'Examen Chagas',
        detalle: '$tipoEx — $res',
        icono: Icons.science_outlined,
      ));
    }

    for (final row in inasistencias) {
      final fecha = _firstDate([row['fecha_inasistencia'], row['creado_en']]);
      if (fecha == null) continue;
      final tipoCtrl = (row['tipo_control'] ?? 'Control médico').toString().trim();
      out.add(HistorialEvento(
        fecha: fecha,
        tipo: 'Inasistencia',
        detalle: tipoCtrl.isEmpty ? 'Registro de inasistencia' : tipoCtrl,
        icono: Icons.event_busy_outlined,
      ));
    }

    for (final row in bajoControl) {
      final fecha = _firstDate([
        row['ultimo_control'],
        row['fecha_notificacion'],
        row['fecha_confirmacion'],
        row['creado_en'],
      ]);
      if (fecha == null) continue;
      final folio = row['folio']?.toString().trim();
      final obs = row['observaciones']?.toString().trim();
      final buf = <String>[];
      if (folio != null && folio.isNotEmpty) buf.add('Folio $folio');
      if (obs != null && obs.isNotEmpty) {
        buf.add(obs.length > 80 ? '${obs.substring(0, 77)}…' : obs);
      }
      out.add(HistorialEvento(
        fecha: fecha,
        tipo: 'Bajo control',
        detalle: buf.isEmpty ? 'Actualización de seguimiento' : buf.join(' · '),
        icono: Icons.health_and_safety_outlined,
      ));
    }

    for (final row in tratamiento) {
      final fecha = _firstDate([row['fecha_inicio'], row['creado_en']]);
      if (fecha == null) continue;
      final nombre = (row['nombre_tratamiento'] ?? 'Tratamiento').toString().trim();
      final lugar = row['lugar_tratamiento']?.toString().trim();
      out.add(HistorialEvento(
        fecha: fecha,
        tipo: 'Tratamiento',
        detalle: lugar != null && lugar.isNotEmpty ? '$nombre · $lugar' : nombre,
        icono: Icons.medication_outlined,
      ));
    }

    for (final row in gestantes) {
      final fecha = _firstDate([
        row['fecha_ingreso_prenatal'],
        row['creado_en'],
      ]);
      if (fecha == null) continue;
      final parto = row['fecha_parto_aprox']?.toString().trim();
      out.add(HistorialEvento(
        fecha: fecha,
        tipo: 'Gestante / Prenatal',
        detalle: parto != null && parto.isNotEmpty ? 'Parto aprox. $parto' : 'Ingreso prenatal',
        icono: Icons.pregnant_woman_outlined,
      ));
    }

    for (final row in agudo) {
      final fecha = _firstDate([row['fecha_notificacion'], row['creado_en']]);
      if (fecha == null) continue;
      final folio = row['folio']?.toString().trim();
      final obs = row['observacion']?.toString().trim();
      final buf = <String>[];
      if (folio != null && folio.isNotEmpty) buf.add('Folio $folio');
      if (obs != null && obs.isNotEmpty) {
        buf.add(obs.length > 60 ? '${obs.substring(0, 57)}…' : obs);
      }
      out.add(HistorialEvento(
        fecha: fecha,
        tipo: 'Caso agudo',
        detalle: buf.isEmpty ? 'Registro caso agudo' : buf.join(' · '),
        icono: Icons.bolt_outlined,
      ));
    }

    out.sort((a, b) => b.fecha.compareTo(a.fecha));
    return out;
  }

  static DateTime? _firstDate(List<dynamic> candidates) {
    for (final v in candidates) {
      final d = _parseDate(v);
      if (d != null) return d;
    }
    return null;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}
