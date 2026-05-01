import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/examen.dart';
import '../repositories/app_repositories.dart';
import '../services/network_service.dart';
import '../utils/toast.dart';
import '../widgets/status_badge.dart';

/// Filtro por chip: Todos, Pendientes, Atrasados (desde Home: pending → pendientes, overdue → atrasados).
enum FiltroExamen { todos, pendientes, atrasados }

/// Helper: pendiente si resultado == 'pendiente' (case-insensitive, trim).
bool _isPendiente(dynamic resultado) =>
    (resultado ?? '').toString().trim().toLowerCase() == 'pendiente';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

/// Días hasta la fecha: positivo = futuro, negativo = pasado.
int _daysDiff(DateTime date) {
  final now = DateTime.now();
  final a = DateTime(now.year, now.month, now.day);
  final b = DateTime(date.year, date.month, date.day);
  return b.difference(a).inDays;
}

({String label, StatusTone tone}) _badgeForExam(Map<String, dynamic> e) {
  final resultado = (e['resultado'] ?? '').toString().trim();
  final pendiente = _isPendiente(resultado);

  if (!pendiente) {
    final label = resultado.isEmpty ? 'Realizado' : 'Realizado · $resultado';
    return (label: label, tone: StatusTone.success);
  }

  final fecha = _parseDate(e['fecha_examen']);
  if (fecha == null) {
    return (label: 'Pendiente', tone: StatusTone.warning);
  }

  final diff = _daysDiff(fecha);

  if (diff < 0) {
    return (label: 'Atrasado ${diff.abs()} días', tone: StatusTone.danger);
  }
  if (diff <= 6) {
    return (label: 'Próximo · $diff días', tone: StatusTone.warning);
  }
  return (label: 'Programado · $diff días', tone: StatusTone.neutral);
}

class ExamenesListScreen extends StatefulWidget {
  /// Si se pasa, el chip correspondiente viene activo al abrir (ej. desde Home).
  /// 'pending' → pendientes, 'overdue' → atrasados, null/'all' → todos.
  final String? initialFilter;

  const ExamenesListScreen({super.key, this.initialFilter = 'all'});

  @override
  State<ExamenesListScreen> createState() => _ExamenesListScreenState();
}

class _ExamenesListScreenState extends State<ExamenesListScreen> {
  bool cargando = true;
  List<Examen> registros = [];
  String filtro = '';
  late FiltroExamen _chipFiltro;
  final _examenRepo = AppRepositories.examen;

  @override
  void initState() {
    super.initState();
    switch (widget.initialFilter) {
      case 'pending':
        _chipFiltro = FiltroExamen.pendientes;
        break;
      case 'overdue':
        _chipFiltro = FiltroExamen.atrasados;
        break;
      default:
        _chipFiltro = FiltroExamen.todos;
    }
    cargarRegistros();
  }

  Future<void> cargarRegistros() async {
    if (!NetworkService.instance.isOnline) {
      setState(() => cargando = false);
      return;
    }
    try {
      final data = await _examenRepo.list(limit: 500);
      setState(() {
        registros = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, "Error cargando exámenes: $e");
    }
  }

  DateTime? _parseFecha(dynamic v) => _parseDate(v);

  int _prioridadTone(StatusTone t) {
    switch (t) {
      case StatusTone.danger:
        return 0;
      case StatusTone.warning:
        return 1;
      case StatusTone.neutral:
        return 2;
      case StatusTone.success:
        return 3;
    }
  }

  Widget _buildChip(String label, FiltroExamen value) {
    final selected = _chipFiltro == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _chipFiltro = value);
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  bool _pasaChip(Examen r) {
    final pendiente = _isPendiente(r.resultado);
    final fecha = _parseFecha(r.fechaExamen);
    final hoy = DateTime.now();
    final fechaHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final atrasado = pendiente && fecha != null && fecha.isBefore(fechaHoy);

    switch (_chipFiltro) {
      case FiltroExamen.todos:
        return true;
      case FiltroExamen.pendientes:
        return pendiente;
      case FiltroExamen.atrasados:
        return atrasado;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Filtro por texto (nombre, RUT, tipo, resultado)
    var filtrados = registros.where((r) {
      if (filtro.isNotEmpty) {
        final persona = r.persona ?? {};
        final nombre = persona['nombre'] ?? '';
        final rut = persona['rut'] ?? '';
        final texto = '${nombre} ${rut} ${r.tipoExamen ?? ''} ${r.resultado ?? ''}'.toLowerCase();
        if (!texto.contains(filtro.toLowerCase())) return false;
      }
      return true;
    }).toList();

    // 2) Filtro por chip
    filtrados = filtrados.where(_pasaChip).toList();

    // Orden por prioridad clínica y fecha ascendente
    filtrados.sort((a, b) {
      final metaA = _badgeForExam(a.toJson());
      final metaB = _badgeForExam(b.toJson());
      final pComp = _prioridadTone(metaA.tone).compareTo(_prioridadTone(metaB.tone));
      if (pComp != 0) return pComp;

      final fechaA = _parseFecha(a.fechaExamen);
      final fechaB = _parseFecha(b.fechaExamen);
      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      return fechaA.compareTo(fechaB);
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Exámenes de Chagas")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Chips: Todos | Pendientes | Atrasados
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      _buildChip('Todos', FiltroExamen.todos),
                      const SizedBox(width: 8),
                      _buildChip('Pendientes', FiltroExamen.pendientes),
                      const SizedBox(width: 8),
                      _buildChip('Atrasados', FiltroExamen.atrasados),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar por nombre / RUT / tipo / resultado',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => filtro = value);
                    },
                  ),
                ),
                Expanded(
                  child: filtrados.isEmpty
                      ? const Center(child: Text("No hay exámenes registrados"))
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (!NetworkService.instance.isOnline) return;
                            await cargarRegistros();
                          },
                          child: ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final r = filtrados[index];
                              final persona = r.persona ?? {};
                              final nombre = (persona['nombre'] ?? 'Sin nombre').toString();
                              final rut = (persona['rut'] ?? '-').toString();
                              final tipo = (r.tipoExamen ?? '—').toString();
                              final fechaStr = (r.fechaExamen ?? '—').toString();
                              final laboratorio = (r.laboratorio ?? '').toString();
                              final observacion = (r.observacion ?? '').toString();
                              final idExamen = r.id;

                              final meta = _badgeForExam(r.toJson());
                              final res = (r.resultado ?? '').toString().trim().toLowerCase();
                              final pendiente = res == 'pendiente';
                              final accionPendiente = pendiente && idExamen != null;

                              final badge = StatusBadge(
                                label: meta.label,
                                tone: meta.tone,
                                outlined: true,
                                icon: meta.tone == StatusTone.danger
                                    ? Icons.error_outline
                                    : meta.tone == StatusTone.warning
                                        ? Icons.schedule
                                        : meta.tone == StatusTone.success
                                            ? Icons.check_circle_outline
                                            : Icons.event,
                              );

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            transitionBuilder: (child, anim) =>
                                                FadeTransition(
                                              opacity: anim,
                                              child: child,
                                            ),
                                            child: badge,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'RUT: $rut',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tipo: $tipo',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        'Fecha: $fechaStr',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (laboratorio.isNotEmpty)
                                        Text(
                                          'Lab: $laboratorio',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54),
                                        ),
                                      if (observacion.isNotEmpty)
                                        Text(
                                          'Obs: $observacion',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54),
                                        ),
                                      if (accionPendiente) ...[
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              HapticFeedback.selectionClick();
                                              await _marcarExamenRealizado(
                                                context,
                                                idExamen,
                                                () async {
                                                  await cargarRegistros();
                                                  if (mounted) setState(() {});
                                                },
                                              );
                                            },
                                            child: const Text(
                                                'Marcar como realizado'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

Future<void> _marcarExamenRealizado(
  BuildContext context,
  int examenId,
  Future<void> Function() onRefresh,
) async {
  String resultado = 'Negativo';
  final obsCtrl = TextEditingController();
  final labCtrl = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Marcar como realizado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: resultado,
                decoration: const InputDecoration(labelText: 'Resultado'),
                items: const [
                  DropdownMenuItem(
                    value: 'Negativo',
                    child: Text('Negativo'),
                  ),
                  DropdownMenuItem(
                    value: 'Positivo',
                    child: Text('Positivo'),
                  ),
                  DropdownMenuItem(
                    value: 'Indeterminado',
                    child: Text('Indeterminado'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) resultado = v;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: obsCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observación (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: labCtrl,
                decoration: const InputDecoration(
                  labelText: 'Laboratorio (opcional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );

  if (ok != true) return;

  final obs = obsCtrl.text.trim();
  final lab = labCtrl.text.trim();

  try {
    await AppRepositories.examen.updatePartial(examenId, {
      'resultado': resultado,
      'observacion': obs.isEmpty ? null : obs,
      'laboratorio': lab.isEmpty ? null : lab,
    });

    if (context.mounted) {
      showOk(context, 'Examen actualizado');
    }
    await onRefresh();
  } catch (e) {
    if (context.mounted) {
      showErr(context, 'Error al actualizar examen: $e');
    }
  }
}
