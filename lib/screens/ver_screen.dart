import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/paciente_resume.dart';
import '../repositories/app_repositories.dart';
import '../utils/seguimiento_rules.dart';
import '../services/network_service.dart';
import '../services/pacientes_resume_service.dart';
import '../utils/app_messages.dart';
import '../utils/debouncer.dart';
import '../utils/nav.dart';
import '../utils/rut_utils.dart';
import '../utils/toast.dart';
import '../widgets/clinical_list_ui.dart';
import '../widgets/patient_clinical_list_card.dart';
import '../widgets/states.dart';
import 'detalle_persona_screen.dart';
import 'editar_persona_screen.dart';
import 'examenes_list_screen.dart';
import 'grupos_list_screen.dart';

enum FiltroVer { todos, gestantes, bajoControl, agudo, tratamiento, inasistentes }

class VerScreen extends StatefulWidget {
  final String initialFilter; // all | today | last7

  const VerScreen({super.key, this.initialFilter = 'all'});

  @override
  State<VerScreen> createState() => _VerScreenState();
}

class _VerScreenState extends State<VerScreen> {
  final _modulosRepo = AppRepositories.modulos;
  final _personaRepo = AppRepositories.persona;
  final _qCtrl = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);
  final _scrollController = ScrollController();

  bool _loading = true;
  String _query = '';
  FiltroVer _filtro = FiltroVer.todos;
  String _dateFilter = 'all';
  List<PacienteResume> _resumes = [];
  Map<int, Set<String>> _modulosPorPersona = {};
  final _resumeService = PacientesResumeService();
  Map<FiltroVer, int> _contadoresFiltros = {};
  bool _animatedOnce = false;

  @override
  void initState() {
    super.initState();
    _dateFilter = _normalizeDateFilter(widget.initialFilter);
    _load();
    _qCtrl.addListener(() {
      _debouncer.run(() {
        if (!mounted) return;
        setState(() {
          _query = _qCtrl.text.trim();
          _load();
        });
      });
    });
  }

  Future<List<int>> _idsPorFiltro(FiltroVer f) async {
    String table;
    switch (f) {
      case FiltroVer.gestantes:
        table = 'chagas_gestantes';
        break;
      case FiltroVer.bajoControl:
        table = 'chagas_bajo_control';
        break;
      case FiltroVer.agudo:
        table = 'chagas_agudo';
        break;
      case FiltroVer.tratamiento:
        table = 'chagas_tratamiento';
        break;
      case FiltroVer.inasistentes:
        table = 'chagas_inasistentes';
        break;
      case FiltroVer.todos:
        return [];
    }
    return _modulosRepo.listPersonaIds(table);
  }

  Future<void> _cargarContadores() async {
    try {
      final contadores = <FiltroVer, int>{};
      for (final filtro in FiltroVer.values) {
        if (filtro == FiltroVer.todos) {
          contadores[filtro] = await _personaRepo.count();
        } else {
          final ids = await _idsPorFiltro(filtro);
          contadores[filtro] = ids.length;
        }
      }
      if (mounted) {
        setState(() => _contadoresFiltros = contadores);
      }
    } catch (_) {}
  }

  Future<void> _cargarModulos(List<int> idsPersona) async {
    if (idsPersona.isEmpty) {
      setState(() => _modulosPorPersona = {});
      return;
    }
    try {
      final modulosMap = await _modulosRepo.getModulosByPersonaIds(idsPersona);
      if (mounted) setState(() => _modulosPorPersona = modulosMap);
    } catch (_) {}
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (!NetworkService.instance.isOnline) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);

    try {
      _cargarContadores();

      final ids = await _idsPorFiltro(_filtro);
      final list = await _resumeService.fetchResumes(
        query: _query.isEmpty ? null : _query,
        idPersonasFilter: ids.isEmpty ? null : ids,
      );
      final filteredByDate = _applyDateFilter(list);

      final idsPersona = filteredByDate.map((r) => r.idPersona).toList();
      await _cargarModulos(idsPersona);

      if (!mounted) return;
      setState(() {
        _resumes = filteredByDate;
        _loading = false;
      });
      // Marcar que ya mostramos lista una vez; próximos refresh/filtro no re-animan.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _animatedOnce = true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _resumes = [];
      });
      showErrWithAction(
        context,
        AppMessages.errorCargar,
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    }
  }

  void _limpiar() {
    setState(() {
      _query = '';
      _filtro = FiltroVer.todos;
      _dateFilter = 'all';
      _qCtrl.clear();
    });
    _load();
  }

  bool get _tieneFiltros =>
      _query.isNotEmpty || _filtro != FiltroVer.todos || _dateFilter != 'all';

  static String _normalizeDateFilter(String raw) {
    if (raw == 'today' || raw == 'last7' || raw == 'all') return raw;
    return 'all';
  }

  List<PacienteResume> _applyDateFilter(List<PacienteResume> list) {
    if (_dateFilter == 'all') return list;
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    if (_dateFilter == 'today') {
      return list.where((r) {
        final created = r.createdAt;
        return created != null && !created.isBefore(startToday);
      }).toList();
    }
    final since = startToday.subtract(const Duration(days: 6));
    return list.where((r) {
      final created = r.createdAt;
      return created != null && !created.isBefore(since);
    }).toList();
  }

  String _dateFilterLabel() {
    switch (_dateFilter) {
      case 'today':
        return 'Hoy';
      case 'last7':
        return '7 días';
      default:
        return 'Todos';
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _scrollController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  int get _atrasadosCount =>
      _resumes.where((r) => r.overallStatus == Semaforo.rojo).length;

  PatientVisualStatus _visualStatus(Semaforo s) {
    switch (s) {
      case Semaforo.verde:
        return PatientVisualStatus.upToDate;
      case Semaforo.amarillo:
        return PatientVisualStatus.upcoming;
      case Semaforo.rojo:
        return PatientVisualStatus.overdue;
    }
  }

  String _controlLineFor(PacienteResume r) {
    switch (r.lastControlStatus) {
      case EstadoControl.sinRegistro:
        return 'Últ. control: —';
      case EstadoControl.alDia:
        final d = r.lastControlDate;
        return d == null ? 'Últ. control: —' : 'Últ. control: ${_formatDate(d)}';
      case EstadoControl.proximo:
        final d = r.lastControlDate;
        return d == null ? 'Próximo control: —' : 'Próximo control: ${_formatDate(d)}';
      case EstadoControl.vencido:
        return 'Control atrasado';
    }
  }

  String _examLineFor(PacienteResume r) {
    if (r.lastExamStatus == EstadoExamen.sinRegistro) return 'Sin exámenes';
    return 'Últ. examen: ${_formatDate(r.lastExamDate)} · ${r.lastExamLabel}';
  }

  PatientCardData _cardDataFor(PacienteResume r, Set<String> modulos) {
    final rutRaw = (r.rut ?? '').trim();
    final rutFormateado =
        rutRaw.isEmpty ? '' : RutUtils.formatearParaUI(r.rut!);
    return PatientCardData(
      name: r.nombre,
      rut: rutFormateado.isEmpty ? null : rutFormateado,
      location: (r.comuna ?? '').trim().isEmpty ? null : r.comuna!.trim(),
      controlText: _controlLineFor(r),
      examText: _examLineFor(r),
      status: _visualStatus(r.overallStatus),
      modulos: modulos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final personasFiltradas = _resumes.length;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver pacientes', style: TextStyle(fontSize: 20)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'grupos') {
                pushFade(context, GruposListScreen());
              } else if (value == 'examenes') {
                pushFade(context, const ExamenesListScreen());
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'grupos', child: Text('Ver grupos / operativos')),
              const PopupMenuItem(value: 'examenes', child: Text('Ver exámenes')),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Mostrando $personasFiltradas ${personasFiltradas == 1 ? 'paciente' : 'pacientes'}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                if (_dateFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: const Icon(Icons.calendar_today, size: 14),
                      label: Text(_dateFilterLabel()),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (_tieneFiltros)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpiar'),
                    onPressed: _limpiar,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _qCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar paciente (nombre o RUT)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _qCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _qCtrl.clear();
                          setState(() => _query = '');
                          _load();
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip('Todos', FiltroVer.todos),
                _chip('Gestantes', FiltroVer.gestantes),
                _chip('Bajo control', FiltroVer.bajoControl),
                _chip('Agudo', FiltroVer.agudo),
                _chip('Tratamiento', FiltroVer.tratamiento),
                _chip('Inasistentes', FiltroVer.inasistentes),
              ],
            ),
          ),
          ClinicalListAlertBanner(
            text: _loading || _atrasadosCount <= 0
                ? ''
                : '$_atrasadosCount ${_atrasadosCount == 1 ? 'paciente con' : 'pacientes con'} control atrasado',
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _loading
                  ? const AppLoading(key: ValueKey('loading'))
                  : _resumes.isEmpty
                      ? const AppEmptyState(
                          key: ValueKey('empty'),
                          text: 'Sin resultados',
                          subtitle:
                              'Prueba otra búsqueda, un filtro distinto o limpia los filtros.',
                          icon: Icons.people_outline,
                          useLottie: true,
                        )
                      : RefreshIndicator(
                          key: const ValueKey('list'),
                          onRefresh: () async {
                            if (!NetworkService.instance.isOnline) return;
                            HapticFeedback.lightImpact();
                            await _load();
                            if (!context.mounted) return;
                            showOk(context, AppMessages.listaActualizada);
                          },
                          child: ListView.builder(
                            key: const PageStorageKey<String>('ver_screen_list'),
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 4, bottom: 16),
                            itemCount: _resumes.length,
                            itemBuilder: (_, i) {
                              final r = _resumes[i];
                              final modulos =
                                  _modulosPorPersona[r.idPersona] ?? <String>{};
                              final data = _cardDataFor(r, modulos);

                              void onTap() async {
                                HapticFeedback.selectionClick();
                                final result = await pushSharedAxis<bool>(
                                  context,
                                  DetallePersonaScreen(idPersona: r.idPersona),
                                );
                                if (result == true && mounted) _load();
                              }

                              Future<void> onEditar() async {
                                HapticFeedback.selectionClick();
                                final result = await pushSharedAxis<bool>(
                                  context,
                                  EditarPersonaScreen(idPersona: r.idPersona),
                                );
                                if (result == true && mounted) _load();
                              }

                              Future<void> onLlamar() async {
                                HapticFeedback.selectionClick();
                                final uri = Uri.parse('tel:${r.telefono}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  if (!context.mounted) return;
                                  showErr(
                                      context, 'No se pudo iniciar la llamada');
                                }
                              }

                              final card = PatientListCard(
                                data: data,
                                onTap: onTap,
                              );

                              final wrapped = (r.telefono ?? '').isNotEmpty
                                  ? Dismissible(
                                      key: Key('persona_${r.idPersona}'),
                                      direction: DismissDirection.horizontal,
                                      background: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        padding:
                                            const EdgeInsets.only(left: 20),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.phone,
                                                color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(
                                              'Llamar',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      secondaryBackground: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade600,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 20),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Editar contacto',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.edit,
                                                color: Colors.white),
                                          ],
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        if (direction ==
                                            DismissDirection.startToEnd) {
                                          await onLlamar();
                                          return false;
                                        }
                                        if (direction ==
                                            DismissDirection.endToStart) {
                                          await onEditar();
                                          return false;
                                        }
                                        return false;
                                      },
                                      child: card,
                                    )
                                  : Dismissible(
                                      key: Key('persona_${r.idPersona}'),
                                      direction: DismissDirection.endToStart,
                                      // Obligatorio si hay secondaryBackground (API de Dismissible).
                                      background: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                      secondaryBackground: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade600,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 20),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Editar contacto',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.edit,
                                                color: Colors.white),
                                          ],
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        if (direction ==
                                            DismissDirection.endToStart) {
                                          await onEditar();
                                          return false;
                                        }
                                        return false;
                                      },
                                      child: card,
                                    );

                              if (_animatedOnce) return wrapped;
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(
                                    milliseconds:
                                        180 + (i.clamp(0, 8) * 20)),
                                builder: (_, v, child) => Opacity(
                                  opacity: v,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - v) * 10),
                                    child: child,
                                  ),
                                ),
                                child: wrapped,
                              );
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, FiltroVer f) {
    final selected = _filtro == f;
    final count = _contadoresFiltros[f] ?? 0;
    final label = count > 0 ? '$text ($count)' : text;
    return clinicalFilterChip(
      context: context,
      label: label,
      selected: selected,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _filtro = f;
          _load();
        });
      },
    );
  }
}
