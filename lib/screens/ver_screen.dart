import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/paciente_resume.dart';
import '../repositories/app_repositories.dart';
import '../services/network_service.dart';
import '../services/pacientes_resume_service.dart';
import '../utils/debouncer.dart';
import '../utils/nav.dart';
import '../utils/rut_utils.dart';
import '../utils/seguimiento_rules.dart';
import '../utils/toast.dart';
import '../widgets/states.dart';
import 'detalle_persona_screen.dart';
import 'editar_persona_screen.dart';
import 'examenes_list_screen.dart';
import 'grupos_list_screen.dart';

enum FiltroVer { todos, gestantes, bajoControl, agudo, tratamiento, inasistentes }

class VerScreen extends StatefulWidget {
  const VerScreen({super.key});

  @override
  State<VerScreen> createState() => _VerScreenState();
}

class _VerScreenState extends State<VerScreen> {
  final _modulosRepo = AppRepositories.modulos;
  final _personaRepo = AppRepositories.persona;
  final _qCtrl = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);

  bool _loading = true;
  String _query = '';
  FiltroVer _filtro = FiltroVer.todos;
  List<PacienteResume> _resumes = [];
  Map<int, Set<String>> _modulosPorPersona = {};
  final _resumeService = PacientesResumeService();
  Map<FiltroVer, int> _contadoresFiltros = {};
  bool _animatedOnce = false;

  @override
  void initState() {
    super.initState();
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

      final idsPersona = list.map((r) => r.idPersona).toList();
      await _cargarModulos(idsPersona);

      if (!mounted) return;
      setState(() {
        _resumes = list;
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
        'Error cargando pacientes: $e',
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    }
  }

  void _limpiar() {
    setState(() {
      _query = '';
      _filtro = FiltroVer.todos;
      _qCtrl.clear();
    });
    _load();
  }

  bool get _tieneFiltros => _query.isNotEmpty || _filtro != FiltroVer.todos;

  @override
  void dispose() {
    _qCtrl.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final personasFiltradas = _resumes.length;
    
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
        children: [
          // Header con contador y botón limpiar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Mostrando $personasFiltradas ${personasFiltradas == 1 ? 'paciente' : 'pacientes'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_tieneFiltros)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpiar'),
                    onPressed: _limpiar,
                  ),
              ],
            ),
          ),
          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _qCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar por nombre o RUT',
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Chips con contadores
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _loading
                  ? const AppLoading(key: ValueKey('loading'))
                  : _resumes.isEmpty
                      ? const AppEmptyState(key: ValueKey('empty'), text: 'Sin resultados')
                      : RefreshIndicator(
                          key: const ValueKey('list'),
                          onRefresh: () async {
                            if (!NetworkService.instance.isOnline) return;
                            HapticFeedback.lightImpact();
                            await _load();
                            if (mounted) showOk(context, 'Actualizado');
                          },
                          child: ListView.separated(
                            itemCount: _resumes.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final r = _resumes[i];
                              final rutFormateado = (r.rut ?? '').trim().isEmpty
                                  ? ''
                                  : RutUtils.formatearParaUI(r.rut!);
                              final comuna = r.comuna ?? '';
                              final subtitulo = rutFormateado.isNotEmpty
                                  ? (comuna.isNotEmpty ? '$rutFormateado • $comuna' : rutFormateado)
                                  : (comuna.isNotEmpty ? comuna : 'Sin RUT');
                              final lastExamLine = 'Últ. examen: ${_formatDate(r.lastExamDate)} · ${r.lastExamLabel ?? '—'}';
                              final lastControlLine = 'Últ. control: ${_formatDate(r.lastControlDate)}';
                              final modulos = _modulosPorPersona[r.idPersona] ?? <String>{};
                              
                              final tile = _PersonaTile(
                                nombre: r.nombre,
                                subtitulo: subtitulo,
                                lastExamLine: lastExamLine,
                                lastControlLine: lastControlLine,
                                overallStatus: r.overallStatus,
                                overallLabel: r.overallLabel,
                                modulos: modulos,
                                telefono: r.telefono ?? '',
                                idPersona: r.idPersona,
                                onTap: () async {
                                        HapticFeedback.selectionClick();
                                        final _ = await pushSharedAxis(
                                          context,
                                          DetallePersonaScreen(idPersona: r.idPersona),
                                        );
                                        _load();
                                      },
                                onEditar: () async {
                                        HapticFeedback.selectionClick();
                                        final _ = await pushSharedAxis(
                                          context,
                                          EditarPersonaScreen(idPersona: r.idPersona),
                                        );
                                        _load();
                                      },
                                onLlamar: (r.telefono ?? '').isNotEmpty
                                    ? () async {
                                        HapticFeedback.selectionClick();
                                        final uri = Uri.parse('tel:${r.telefono}');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          showErr(context, 'No se puede realizar la llamada');
                                        }
                                      }
                                    : null,
                              );
                              
                              if (_animatedOnce) return tile;
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(milliseconds: 180 + (i.clamp(0, 8) * 20)),
                                builder: (_, v, child) => Opacity(
                                  opacity: v,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - v) * 8),
                                    child: child,
                                  ),
                                ),
                                child: tile,
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
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() {
            _filtro = f;
            _load();
          });
        },
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected 
              ? Theme.of(context).colorScheme.onPrimaryContainer 
              : null,
        ),
      ),
    );
  }
}

class _PersonaTile extends StatelessWidget {
  final String nombre;
  final String subtitulo;
  final String? lastExamLine;
  final String? lastControlLine;
  final Semaforo overallStatus;
  final String? overallLabel;
  final Set<String> modulos;
  final String telefono;
  final int idPersona;
  final VoidCallback? onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onLlamar;

  const _PersonaTile({
    required this.nombre,
    required this.subtitulo,
    this.lastExamLine,
    this.lastControlLine,
    required this.overallStatus,
    this.overallLabel,
    required this.modulos,
    required this.telefono,
    required this.idPersona,
    this.onTap,
    this.onEditar,
    this.onLlamar,
  });

  static Color _colorSemaforo(Semaforo s) {
    switch (s) {
      case Semaforo.rojo:
        return Colors.red;
      case Semaforo.amarillo:
        return Colors.amber;
      case Semaforo.verde:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      title: Text(
        nombre,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subtitulo),
          const SizedBox(height: 2),
          Text(
            lastExamLine ?? 'Últ. examen: —',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Text(
            lastControlLine ?? 'Últ. control: —',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (modulos.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: modulos.map((m) {
                final labels = {
                  'BC': 'BC',
                  'G': 'G',
                  'A': 'A',
                  'T': 'T',
                  'I': 'I',
                  'E': 'E',
                };
                return Chip(
                  label: Text(
                    labels[m] ?? m,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _colorSemaforo(overallStatus).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _colorSemaforo(overallStatus), width: 1),
            ),
            child: Text(
              overallLabel ?? 'Al día',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _colorSemaforo(overallStatus),
              ),
            ),
          ),
          if (modulos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 8),
              child: Wrap(
                spacing: 2,
                children: modulos.map((m) {
                  final colors = {
                    'BC': Colors.blue,
                    'G': Colors.pink,
                    'A': Colors.orange,
                    'T': Colors.green,
                    'I': Colors.red,
                    'E': Colors.purple,
                  };
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors[m] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );

    if (onEditar == null && onLlamar == null) {
      return tile;
    }

    return Dismissible(
      key: Key('persona_$idPersona'),
      direction: onLlamar != null 
          ? DismissDirection.horizontal 
          : DismissDirection.endToStart,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.phone, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Llamar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.blue,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Editar contacto',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.edit, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && onLlamar != null) {
          onLlamar!();
          return false; // No eliminar el tile, solo ejecutar acción
        } else if (direction == DismissDirection.endToStart && onEditar != null) {
          onEditar!();
          return false; // No eliminar el tile, solo ejecutar acción
        }
        return false;
      },
      child: tile,
    );
  }
}
