import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/caso_epidemiologico.dart';
import '../repositories/app_repositories.dart';
import '../services/network_service.dart';
import '../utils/debouncer.dart';
import '../utils/epidemiologia_ui.dart';
import '../utils/nav.dart';
import '../utils/toast.dart';
import '../widgets/states.dart';
import 'detalle_caso_screen.dart';
import 'grupos_list_screen.dart';

enum FiltroVer { todos, nuevo, reingreso, tratado }

class VerScreen extends StatefulWidget {
  final String initialFilter; // all | today | last7

  const VerScreen({super.key, this.initialFilter = 'all'});

  @override
  State<VerScreen> createState() => _VerScreenState();
}

class _VerScreenState extends State<VerScreen> {
  final _casoRepo = AppRepositories.casoEpidemiologico;
  final _sectorRepo = AppRepositories.sector;

  final _qCtrl = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);
  final _scrollController = ScrollController();

  bool _loading = true;
  String _query = '';
  FiltroVer _filtro = FiltroVer.todos;
  String _dateFilter = 'all';
  List<CasoEpidemiologico> _casos = [];
  Map<int, String> _sectorNombrePorId = {};
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
        });
        _recalcularDesdeCache();
      });
    });
  }

  void _recalcularDesdeCache() {
    // solo filtro cliente; datos ya en _casos
    setState(() {});
  }

  Map<FiltroVer, int> _contadoresFrom(List<CasoEpidemiologico> base) {
    final contadores = <FiltroVer, int>{};
    for (final filtro in FiltroVer.values) {
      if (filtro == FiltroVer.todos) {
        contadores[filtro] = base.length;
      } else {
        final clave = switch (filtro) {
          FiltroVer.nuevo => 'nuevo',
          FiltroVer.reingreso => 'reingreso',
          FiltroVer.tratado => 'tratado',
          FiltroVer.todos => '',
        };
        contadores[filtro] = base
            .where((c) => EpidemiologiaUi.claveEstadoCaso(c.estadoActual) == clave)
            .length;
      }
    }
    return contadores;
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (!NetworkService.instance.isOnline) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);

    try {
      final list = await _casoRepo.getCasos();
      final ids = list.map((c) => c.idSector).whereType<int>().toSet().toList();
      final sectores = await _sectorRepo.getSectoresByIds(ids);
      final map = {for (final s in sectores) s.idSector: s.nombreSector};

      if (!mounted) return;
      final contadores = _contadoresFrom(list);
      setState(() {
        _casos = list;
        _sectorNombrePorId = map;
        _contadoresFiltros = contadores;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _animatedOnce = true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _casos = [];
      });
      showErrWithAction(
        context,
        'Error cargando casos: $e',
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
  }

  bool get _tieneFiltros =>
      _query.isNotEmpty || _filtro != FiltroVer.todos || _dateFilter != 'all';

  List<CasoEpidemiologico> get _baseFiltrada {
    var out = _applyDateFilter(_casos);

    if (_filtro != FiltroVer.todos) {
      final clave = switch (_filtro) {
        FiltroVer.nuevo => 'nuevo',
        FiltroVer.reingreso => 'reingreso',
        FiltroVer.tratado => 'tratado',
        FiltroVer.todos => '',
      };
      out = out
          .where((c) => EpidemiologiaUi.claveEstadoCaso(c.estadoActual) == clave)
          .toList();
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((c) {
        final code = (c.codigoCaso ?? '').toLowerCase();
        final sec = (_sectorNombrePorId[c.idSector] ?? '').toLowerCase();
        final oc = (c.ocupacion ?? '').toLowerCase();
        final idStr = c.idCaso?.toString() ?? '';
        return code.contains(q) || sec.contains(q) || oc.contains(q) || idStr.contains(q);
      }).toList();
    }
    return out;
  }

  static String _normalizeDateFilter(String raw) {
    if (raw == 'today' || raw == 'last7' || raw == 'all') return raw;
    return 'all';
  }

  List<CasoEpidemiologico> _applyDateFilter(List<CasoEpidemiologico> list) {
    if (_dateFilter == 'all') return list;
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    if (_dateFilter == 'today') {
      return list.where((c) {
        final t = c.fechaRegistro ?? c.creadoEn;
        if (t == null) return false;
        final local = t.toLocal();
        final d = DateTime(local.year, local.month, local.day);
        return !d.isBefore(startToday);
      }).toList();
    }
    final since = startToday.subtract(const Duration(days: 6));
    return list.where((c) {
      final t = c.fechaRegistro ?? c.creadoEn;
      if (t == null) return false;
      final local = t.toLocal();
      final d = DateTime(local.year, local.month, local.day);
      return !d.isBefore(since);
    }).toList();
  }

  String _dateFilterLabel() {
    switch (_dateFilter) {
      case 'today':
        return 'Hoy';
      case 'last7':
        return 'Últimos 7 días';
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

  @override
  Widget build(BuildContext context) {
    final filtrados = _baseFiltrada;
    final n = filtrados.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver casos', style: TextStyle(fontSize: 20)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'grupos') {
                pushFade(context, GruposListScreen());
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'grupos', child: Text('Ver grupos / operativos')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Mostrando $n ${n == 1 ? "caso" : "casos"}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_dateFilter != 'all')
                    Chip(
                      avatar: const Icon(Icons.calendar_today, size: 14),
                      label: Text(_dateFilterLabel()),
                      visualDensity: VisualDensity.compact,
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _qCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar por código, sector u ocupación',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _chip('Todos', FiltroVer.todos),
                _chip('Caso nuevo', FiltroVer.nuevo),
                _chip('Reingreso', FiltroVer.reingreso),
                _chip('Tratado', FiltroVer.tratado),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _loading
                  ? const AppLoading(key: ValueKey('loading'))
                  : filtrados.isEmpty
                      ? const AppEmptyState(key: ValueKey('empty'), text: 'Sin resultados')
                      : RefreshIndicator(
                          key: const ValueKey('list'),
                          onRefresh: () async {
                            if (!NetworkService.instance.isOnline) return;
                            HapticFeedback.lightImpact();
                            await _load();
                            if (!context.mounted) return;
                            showOk(context, 'Actualizado');
                          },
                          child: ListView.separated(
                            key: const PageStorageKey<String>('ver_screen_list'),
                            controller: _scrollController,
                            itemCount: filtrados.length,
                            separatorBuilder: (context, _) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final c = filtrados[i];
                              final idCaso = c.idCaso;
                              if (idCaso == null) return const SizedBox.shrink();

                              final sec = c.idSector != null
                                  ? (_sectorNombrePorId[c.idSector!] ?? '—')
                                  : '—';
                              final tile = _CasoTile(
                                codigo: c.codigoCaso ?? '—',
                                estadoKey: c.estadoActual,
                                sector: sec,
                                edad: c.edad,
                                genero: EpidemiologiaUi.generoLabelEpi(c.genero),
                                ocupacion: (c.ocupacion == null || c.ocupacion!.isEmpty) ? '—' : c.ocupacion!,
                                idCaso: idCaso,
                                onTap: () async {
                                  HapticFeedback.selectionClick();
                                  final r = await pushSharedAxis<bool>(
                                    context,
                                    DetalleCasoScreen(idCaso: idCaso),
                                  );
                                  if (!mounted) return;
                                  if (r == true) _load();
                                },
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
          setState(() => _filtro = f);
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

class _CasoTile extends StatelessWidget {
  final String codigo;
  final String? estadoKey;
  final String sector;
  final int? edad;
  final String genero;
  final String ocupacion;
  final int idCaso;
  final VoidCallback? onTap;

  const _CasoTile({
    required this.codigo,
    required this.estadoKey,
    required this.sector,
    required this.edad,
    required this.genero,
    required this.ocupacion,
    required this.idCaso,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final k = EpidemiologiaUi.claveEstadoCaso(estadoKey);
    final color = EpidemiologiaUi.getEstadoCasoColor(k);
    final label = EpidemiologiaUi.getEstadoCasoLabel(k);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(
          codigo,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              const SizedBox(height: 8),
              Text('📍 Sector: $sector'),
              Text('Edad: ${edad != null ? "$edad" : "—"}'),
              Text('Género: $genero'),
              Text('Ocupación: $ocupacion'),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
