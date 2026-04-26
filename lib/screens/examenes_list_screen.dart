import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/examen.dart';
import '../repositories/app_repositories.dart';
import '../services/network_service.dart';
import '../utils/app_messages.dart';
import '../utils/nav.dart';
import '../utils/rut_utils.dart';
import '../utils/toast.dart';
import '../widgets/clinical_list_ui.dart';
import '../widgets/patient_clinical_list_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/states.dart';
import 'detalle_persona_screen.dart';

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

int? _idPersonaFromMap(Map<String, dynamic> persona) {
  final v = persona['id_persona'];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

PatientVisualStatus _toneToPatientVisual(StatusTone t) {
  switch (t) {
    case StatusTone.danger:
      return PatientVisualStatus.overdue;
    case StatusTone.warning:
      return PatientVisualStatus.upcoming;
    case StatusTone.success:
      return PatientVisualStatus.upToDate;
    case StatusTone.neutral:
      return PatientVisualStatus.upToDate;
  }
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
  final _searchCtrl = TextEditingController();
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      showErr(context, AppMessages.errorCargar);
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
    final q = _searchCtrl.text.trim().toLowerCase();
    // 1) Filtro por texto (nombre, RUT, tipo, resultado)
    var filtrados = registros.where((r) {
      if (q.isNotEmpty) {
        final persona = r.persona ?? {};
        final nombre = persona['nombre'] ?? '';
        final rut = persona['rut'] ?? '';
        final texto = '${nombre} ${rut} ${r.tipoExamen ?? ''} ${r.resultado ?? ''}'.toLowerCase();
        if (!texto.contains(q)) return false;
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

    final atrasadosLista = filtrados.where((r) {
      final meta = _badgeForExam(r.toJson());
      return meta.tone == StatusTone.danger;
    }).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Exámenes de Chagas')),
      body: cargando
          ? const AppLoading(compact: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Mostrando ${filtrados.length} ${filtrados.length == 1 ? 'examen' : 'exámenes'}',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClinicalSearchField(
                    controller: _searchCtrl,
                    hintText: 'Buscar (nombre, RUT, tipo, resultado)',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      clinicalFilterChip(
                        context: context,
                        label: 'Todos',
                        selected: _chipFiltro == FiltroExamen.todos,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _chipFiltro = FiltroExamen.todos);
                        },
                      ),
                      clinicalFilterChip(
                        context: context,
                        label: 'Pendientes',
                        selected: _chipFiltro == FiltroExamen.pendientes,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _chipFiltro = FiltroExamen.pendientes);
                        },
                      ),
                      clinicalFilterChip(
                        context: context,
                        label: 'Atrasados',
                        selected: _chipFiltro == FiltroExamen.atrasados,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _chipFiltro = FiltroExamen.atrasados);
                        },
                      ),
                    ],
                  ),
                ),
                ClinicalListAlertBanner(
                  text: atrasadosLista <= 0
                      ? ''
                      : '$atrasadosLista ${atrasadosLista == 1 ? 'examen atrasado' : 'exámenes atrasados'} en esta vista',
                ),
                Expanded(
                  child: filtrados.isEmpty
                      ? AppEmptyState(
                          text: registros.isEmpty
                              ? 'No hay exámenes registrados'
                              : 'Sin resultados con los filtros actuales',
                          subtitle: registros.isEmpty
                              ? 'Los exámenes aparecerán aquí cuando se registren.'
                              : 'Ajusta la búsqueda o los chips de arriba.',
                          icon: Icons.science_outlined,
                          useLottie: true,
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (!NetworkService.instance.isOnline) return;
                            await cargarRegistros();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final r = filtrados[index];
                              final persona = r.persona ?? {};
                              final nombre =
                                  (persona['nombre'] ?? 'Sin nombre').toString();
                              final rutRaw =
                                  (persona['rut'] ?? '').toString().trim();
                              final rutSmall = rutRaw.isEmpty
                                  ? null
                                  : RutUtils.formatearParaUI(rutRaw);
                              final tipo = (r.tipoExamen ?? '—').toString();
                              final fechaStr =
                                  (r.fechaExamen ?? '—').toString();
                              final laboratorio =
                                  (r.laboratorio ?? '').toString();
                              final observacion =
                                  (r.observacion ?? '').toString();
                              final idExamen = r.id;
                              int? idPersona = r.idPersona;
                              idPersona ??= _idPersonaFromMap(persona);

                              final meta = _badgeForExam(r.toJson());
                              final res =
                                  (r.resultado ?? '').toString().trim().toLowerCase();
                              final pendiente = res == 'pendiente';
                              final accionPendiente =
                                  pendiente && idExamen != null;

                              final dir =
                                  (persona['direccion'] ?? '').toString().trim();
                              final line2 = [
                                'Tipo: $tipo',
                                if (laboratorio.isNotEmpty) 'Lab: $laboratorio',
                                if (observacion.isNotEmpty)
                                  'Obs: ${observacion.length > 48 ? '${observacion.substring(0, 48)}…' : observacion}',
                              ].join(' · ');

                              return PatientListCard(
                                data: PatientCardData(
                                  name: nombre,
                                  rut: rutSmall,
                                  location: dir.isEmpty ? null : dir,
                                  controlText: 'Fecha: $fechaStr',
                                  examText: line2,
                                  eventRowIcon: Icons.event_outlined,
                                  detailRowIcon: Icons.science_outlined,
                                  status: _toneToPatientVisual(meta.tone),
                                  statusLabelOverride: meta.label,
                                ),
                                onTap: idPersona == null
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        pushFade(
                                          context,
                                          DetallePersonaScreen(
                                              idPersona: idPersona!),
                                        );
                                      },
                                footer: accionPendiente
                                    ? Align(
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
                                      )
                                    : null,
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
      showOk(context, AppMessages.examenActualizado);
    }
    await onRefresh();
  } catch (e) {
    if (context.mounted) {
      showErr(context, AppMessages.errorExamenActualizar);
    }
  }
}
