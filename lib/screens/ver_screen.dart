import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/caso_epidemiologico.dart';
import '../models/sector.dart';
import '../repositories/app_repositories.dart';
import '../services/network_service.dart';
import '../utils/debouncer.dart';
import '../utils/epi_db_constants.dart';
import '../utils/epi_edad.dart';
import '../utils/epidemiologia_ui.dart';
import '../widgets/hover_scale.dart';
import '../widgets/states.dart' show ShimmerBox;
import '../utils/nav.dart';
import '../utils/responsive_layout.dart';
import '../utils/toast.dart';
import 'detalle_caso_screen.dart';

enum FiltroVer { todos, nuevo, reingreso, tratado }

class _VerAdvFiltrosDraft {
  String? genero;
  int? sectorId;
  DateTime? desde;
  DateTime? hasta;
  String orden;

  _VerAdvFiltrosDraft({
    this.genero,
    this.sectorId,
    this.desde,
    this.hasta,
    this.orden = 'recientes',
  });
}

/// Tokens alineados con Home / Login (Chagas Tracker).
class _VerTokens {
  static const Color bg = Color(0xFFFCF8FF);
  static const Color royalBlue = Color(0xFF493EE5);
  static const Color shark = Color(0xFF1B1B24);
  static const Color gunPowder = Color(0xFF464555);
  static const Color blueHaze = Color(0xFFC7C4D8);
  static const Color paleSky = Color(0xFF6B7280);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color chipSelectedBg = Color(0xFF493EE5);
  static const Color chipSelectedFg = Color(0xFFFCF8FF);

  static const Color estadoNuevo = Color(0xFF1565C0);
  static const Color estadoReingreso = Color(0xFFE65100);
  static const Color estadoTratado = Color(0xFF2E7D32);
}

Color _verEstadoColor(String estado) {
  switch (estado) {
    case 'nuevo':
      return _VerTokens.estadoNuevo;
    case 'reingreso':
      return _VerTokens.estadoReingreso;
    case 'tratado':
      return _VerTokens.estadoTratado;
    default:
      return _VerTokens.paleSky;
  }
}

String _verEstadoLabel(String estado) {
  switch (estado) {
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

String _verSectorEtiquetaOpcion(Sector s) {
  final n = s.nombreSector.trim();
  final c = s.comuna.trim();
  if (c.isEmpty) return n;
  return '$n · $c';
}

DateTime _verSoloDia(DateTime t) {
  final l = t.toLocal();
  return DateTime(l.year, l.month, l.day);
}

DateTime? _verFechaOrdenFiltro(CasoEpidemiologico c) =>
    c.fechaRegistro ?? c.creadoEn;

String _verFmtDiaCorto(DateTime d) {
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  final l = d.toLocal();
  return '${l.day} ${meses[l.month - 1]} ${l.year}';
}

class VerScreen extends StatefulWidget {
  final String initialFilter;
  final String initialSearchQuery;
  final FiltroVer initialEstadoFiltro;
  final bool focusSearchOnOpen;

  const VerScreen({
    super.key,
    this.initialFilter = 'all',
    this.initialSearchQuery = '',
    this.initialEstadoFiltro = FiltroVer.todos,
    this.focusSearchOnOpen = false,
  });

  @override
  VerScreenState createState() => VerScreenState();
}

class VerScreenState extends State<VerScreen> {
  final _casoRepo = AppRepositories.casoEpidemiologico;
  final _sectorRepo = AppRepositories.sector;

  final _qCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _debouncer = Debouncer(milliseconds: 300);
  final _scrollController = ScrollController();

  bool _loading = true;
  String? _loadError;
  String _query = '';
  late FiltroVer _filtro;
  String _dateFilter = 'all';
  List<CasoEpidemiologico> _casos = [];
  Map<int, String> _sectorNombrePorId = {};
  Map<int, String> _sectorEtiquetaPorId = {};
  String? _generoFiltro;
  int? _sectorFiltroId;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String _ordenFecha = 'recientes';
  Map<FiltroVer, int> _contadoresFiltros = {};
  bool _animatedOnce = false;

  @override
  void initState() {
    super.initState();
    _dateFilter = _normalizeDateFilter(widget.initialFilter);
    _filtro = widget.initialEstadoFiltro;
    if (widget.initialSearchQuery.isNotEmpty) {
      _qCtrl.text = widget.initialSearchQuery;
      _query = widget.initialSearchQuery.trim();
    }
    _load();
    if (widget.focusSearchOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocus.requestFocus();
      });
    }
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
    setState(() {});
  }

  void requestSearchFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocus.requestFocus();
    });
  }

  /// Recarga casos desde el servidor (Supabase). Útil porque [VerScreen] vive en un
  /// [IndexedStack]: puede estar oculto mientras en Inicio se registran nuevos casos.
  Future<void> refreshCasosDesdeServidor() => _load();

  void applyEstadoFiltro(FiltroVer filtro) {
    if (!mounted) return;
    setState(() {
      _filtro = filtro;
      _dateFilter = 'all';
      _query = '';
      _qCtrl.clear();
    });
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
      setState(() {
        _loading = false;
        _loadError = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final list = await _casoRepo.getCasos();
      final ids = list.map((c) => c.idSector).whereType<int>().toSet().toList();
      final sectores = await _sectorRepo.getSectoresByIds(ids);
      final map = {for (final s in sectores) s.idSector: s.nombreSector};
      final etiquetas = {
        for (final s in sectores) s.idSector: _verSectorEtiquetaOpcion(s),
      };

      if (!mounted) return;
      final contadores = _contadoresFrom(list);
      setState(() {
        _casos = list;
        _sectorNombrePorId = map;
        _sectorEtiquetaPorId = etiquetas;
        _contadoresFiltros = contadores;
        _loading = false;
        _loadError = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _animatedOnce = true);
      });
    } catch (e, st) {
      debugPrint('VerScreen _load: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _casos = [];
        _sectorEtiquetaPorId = {};
        _contadoresFiltros = {};
        _loadError =
            'No se pudieron cargar los casos. Intenta nuevamente.';
      });
    }
  }

  void _limpiar() {
    setState(() {
      _query = '';
      _filtro = FiltroVer.todos;
      _dateFilter = 'all';
      _qCtrl.clear();
      _generoFiltro = null;
      _sectorFiltroId = null;
      _fechaDesde = null;
      _fechaHasta = null;
      _ordenFecha = 'recientes';
    });
  }

  int get _cantidadFiltrosAvanzadosActivos {
    var n = 0;
    if (_generoFiltro != null) n++;
    if (_sectorFiltroId != null) n++;
    if (_fechaDesde != null) n++;
    if (_fechaHasta != null) n++;
    if (_ordenFecha != 'recientes') n++;
    return n;
  }

  bool get _tieneFiltros =>
      _query.isNotEmpty ||
      _filtro != FiltroVer.todos ||
      _dateFilter != 'all' ||
      _cantidadFiltrosAvanzadosActivos > 0;

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
        final occ = (c.ocupacion ?? '').toLowerCase();
        final rg = (c.rangoEtario ?? '').toLowerCase();
        final idp = (c.identificadorParcial ?? '').toLowerCase();
        return code.contains(q) ||
            sec.contains(q) ||
            occ.contains(q) ||
            rg.contains(q) ||
            idp.contains(q);
      }).toList();
    }

    if (_generoFiltro != null) {
      out = out.where((c) => c.genero == _generoFiltro).toList();
    }

    if (_sectorFiltroId != null) {
      out = out.where((c) => c.idSector == _sectorFiltroId).toList();
    }

    if (_fechaDesde != null) {
      final desde = _verSoloDia(_fechaDesde!);
      out = out.where((c) {
        final t = _verFechaOrdenFiltro(c);
        if (t == null) return false;
        return !_verSoloDia(t).isBefore(desde);
      }).toList();
    }

    if (_fechaHasta != null) {
      final hasta = _verSoloDia(_fechaHasta!);
      out = out.where((c) {
        final t = _verFechaOrdenFiltro(c);
        if (t == null) return false;
        return !_verSoloDia(t).isAfter(hasta);
      }).toList();
    }

    out = [...out]..sort((a, b) {
          final fa = _verFechaOrdenFiltro(a);
          final fb = _verFechaOrdenFiltro(b);
          final da = fa != null ? _verSoloDia(fa) : DateTime(1900);
          final db = fb != null ? _verSoloDia(fb) : DateTime(1900);
          if (_ordenFecha == 'antiguos') {
            return da.compareTo(db);
          }
          return db.compareTo(da);
        });

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

  static String _fmtFecha(CasoEpidemiologico c) {
    final t = c.fechaRegistro ?? c.creadoEn;
    if (t == null) return '—';
    final l = t.toLocal();
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${l.day} ${meses[l.month - 1]} ${l.year}';
  }

  void _openAdvancedFilters() {
    final draft = _VerAdvFiltrosDraft(
      genero: _generoFiltro,
      sectorId: _sectorFiltroId,
      desde: _fechaDesde,
      hasta: _fechaHasta,
      orden: _ordenFecha,
    );

    Widget buildPanel(BuildContext ctx, StateSetter setModal) {
      final sectorIds = _sectorEtiquetaPorId.keys.toList()
        ..sort(
          (a, b) => (_sectorEtiquetaPorId[a] ?? '')
              .toLowerCase()
              .compareTo((_sectorEtiquetaPorId[b] ?? '').toLowerCase()),
        );

      Future<void> pickDesde() async {
        final now = DateTime.now();
        final initial = draft.desde ?? draft.hasta ?? now;
        final d = await showDatePicker(
          context: ctx,
          initialDate: initial,
          firstDate: DateTime(1990),
          lastDate: DateTime(now.year + 2, 12, 31),
        );
        if (d == null || !ctx.mounted) return;
        setModal(() => draft.desde = DateTime(d.year, d.month, d.day));
      }

      Future<void> pickHasta() async {
        final now = DateTime.now();
        final initial = draft.hasta ?? draft.desde ?? now;
        final d = await showDatePicker(
          context: ctx,
          initialDate: initial,
          firstDate: DateTime(1990),
          lastDate: DateTime(now.year + 2, 12, 31),
        );
        if (d == null || !ctx.mounted) return;
        setModal(() => draft.hasta = DateTime(d.year, d.month, d.day));
      }

      void aplicar() {
        if (!mounted) return;
        setState(() {
          _generoFiltro = draft.genero;
          _sectorFiltroId = draft.sectorId;
          _fechaDesde = draft.desde;
          _fechaHasta = draft.hasta;
          _ordenFecha = draft.orden;
        });
        Navigator.of(ctx).pop();
      }

      void limpiarDraft() {
        setModal(() {
          draft.genero = null;
          draft.sectorId = null;
          draft.desde = null;
          draft.hasta = null;
          draft.orden = 'recientes';
        });
      }

      final textStyle =
          GoogleFonts.inter(fontSize: 15, color: _VerTokens.shark);

      const borderColor = _VerTokens.blueHaze;
      const primaryColor = _VerTokens.royalBlue;
      const textSecondary = _VerTokens.paleSky;
      const textPrimary = _VerTokens.shark;

      final fieldBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor, width: 1),
      );
      final fieldFocusedBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      );
      final fieldDecoration = InputDecoration(
        isDense: true,
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldFocusedBorder,
      );

      Widget sectionLabel(String s) => Text(
            s,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          );

      Widget dateField({
        required String hint,
        required DateTime? value,
        required VoidCallback onTap,
        required VoidCallback onClear,
      }) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value == null ? hint : _verFmtDiaCorto(value),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: value == null ? textSecondary : textPrimary,
                      fontWeight:
                          value == null ? FontWeight.w400 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Más filtros',
                        style: GoogleFonts.publicSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),
          sectionLabel('Género'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            key: ValueKey('gen_${draft.genero}'),
            initialValue: draft.genero,
            isExpanded: true,
            borderRadius: BorderRadius.circular(8),
            style: textStyle,
            decoration: fieldDecoration,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos', style: textStyle),
              ),
              DropdownMenuItem(
                value: EpiGenero.femenino,
                child: Text('Femenino', style: textStyle),
              ),
              DropdownMenuItem(
                value: EpiGenero.masculino,
                child: Text('Masculino', style: textStyle),
              ),
              DropdownMenuItem(
                value: EpiGenero.noInforma,
                child: Text('No informa', style: textStyle),
              ),
            ],
            onChanged: (v) => setModal(() => draft.genero = v),
          ),
          const SizedBox(height: 16),
          sectionLabel('Sector'),
          const SizedBox(height: 6),
          DropdownButtonFormField<int?>(
            key: ValueKey('sec_${draft.sectorId}'),
            initialValue: draft.sectorId,
            isExpanded: true,
            borderRadius: BorderRadius.circular(8),
            style: textStyle,
            decoration: fieldDecoration,
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text('Todos los sectores', style: textStyle),
              ),
              ...sectorIds.map(
                (id) => DropdownMenuItem<int?>(
                  value: id,
                  child: Text(
                    _sectorEtiquetaPorId[id] ?? '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ),
            ],
            onChanged: (v) => setModal(() => draft.sectorId = v),
          ),
          const SizedBox(height: 16),
          sectionLabel('Fecha de registro'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: dateField(
                  hint: 'Desde',
                  value: draft.desde,
                  onTap: pickDesde,
                  onClear: () => setModal(() => draft.desde = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: dateField(
                  hint: 'Hasta',
                  value: draft.hasta,
                  onTap: pickHasta,
                  onClear: () => setModal(() => draft.hasta = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          sectionLabel('Orden'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('ord_${draft.orden}'),
            initialValue: draft.orden,
            isExpanded: true,
            borderRadius: BorderRadius.circular(8),
            style: textStyle,
            decoration: fieldDecoration,
            items: [
              DropdownMenuItem(
                value: 'recientes',
                child: Text('Más recientes primero', style: textStyle),
              ),
              DropdownMenuItem(
                value: 'antiguos',
                child: Text('Más antiguos primero', style: textStyle),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setModal(() => draft.orden = v);
            },
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: limpiarDraft,
                style: TextButton.styleFrom(
                  foregroundColor: textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(
                  'Limpiar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: aplicar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: _VerTokens.chipSelectedFg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Aplicar',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final isDesktop =
        MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

    if (isDesktop) {
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (dialogCtx, setModal) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: SingleChildScrollView(
                    child: buildPanel(dialogCtx, setModal),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetCtx) => StatefulBuilder(
          builder: (sheetCtx, setModal) {
            final padBottom =
                MediaQuery.viewInsetsOf(sheetCtx).bottom + 16;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, padBottom),
              child: SingleChildScrollView(
                child: buildPanel(sheetCtx, setModal),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _baseFiltrada;
    final n = filtrados.length;
    final total = _casos.length;
    final online = NetworkService.instance.isOnline;

    return Scaffold(
      backgroundColor: _VerTokens.bg,
      appBar: AppBar(
        backgroundColor: _VerTokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Ver casos',
          style: GoogleFonts.publicSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _VerTokens.royalBlue,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Registro epidemiológico territorial',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 20 / 14,
                  color: _VerTokens.gunPowder,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _tieneFiltros && total > 0
                        ? 'Mostrando $n de $total casos'
                        : 'Mostrando $n ${n == 1 ? "caso" : "casos"}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _VerTokens.shark,
                    ),
                  ),
                  if (_dateFilter != 'all')
                    Chip(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.calendar_today_outlined,
                          size: 14, color: _VerTokens.royalBlue),
                      label: Text(
                        _dateFilterLabel(),
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      side: const BorderSide(color: _VerTokens.blueHaze),
                      backgroundColor: _VerTokens.cardSurface,
                    ),
                  if (_cantidadFiltrosAvanzadosActivos > 0)
                    Chip(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.tune,
                          size: 14, color: _VerTokens.royalBlue),
                      label: Text(
                        'Filtros activos',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      side: const BorderSide(color: _VerTokens.blueHaze),
                      backgroundColor: _VerTokens.cardSurface,
                    ),
                  if (_tieneFiltros)
                    TextButton.icon(
                      onPressed: _limpiar,
                      icon: Icon(Icons.clear_rounded,
                          size: 18, color: _VerTokens.royalBlue),
                      label: Text(
                        'Limpiar',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: _VerTokens.royalBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBar(
                controller: _qCtrl,
                focusNode: _searchFocus,
                onOpenAdvancedFilters: _openAdvancedFilters,
                advancedFiltersCount: _cantidadFiltrosAvanzadosActivos,
              ),
            ),
            const SizedBox(height: 12),
            _StatusFilterChips(
              filtro: _filtro,
              contadores: _contadoresFiltros,
              onSelected: (f) {
                HapticFeedback.selectionClick();
                setState(() => _filtro = f);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildBodyContent(
                  context: context,
                  online: online,
                  filtrados: filtrados,
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent({
    required BuildContext context,
    required bool online,
    required List<CasoEpidemiologico> filtrados,
  }) {
    if (_loadError != null) {
      return _ErrorState(
        key: const ValueKey('err'),
        message: _loadError!,
        onRetry: () {
          setState(() => _loadError = null);
          _load();
        },
      );
    }
    if (_loading) {
      return const _LoadingState(key: ValueKey('load'));
    }
    if (!online && _casos.isEmpty) {
      return _EmptyState(
        key: const ValueKey('off'),
        icon: Icons.cloud_off_outlined,
        title: 'Sin conexión',
        subtitle:
            'Conéctate a internet para ver los casos registrados.',
      );
    }
    if (_casos.isEmpty) {
      return _EmptyState(
        key: const ValueKey('empty0'),
        icon: Icons.inbox_outlined,
        title: 'Aún no hay casos registrados.',
        subtitle: 'Los nuevos registros aparecerán aquí.',
      );
    }
    if (filtrados.isEmpty) {
      return _EmptyState(
        key: const ValueKey('emptyF'),
        icon: Icons.search_off_rounded,
        title: 'No se encontraron casos con ese criterio.',
        subtitle: 'Prueba otro código, sector, ocupación, rango etario o filtro.',
        actionLabel: _tieneFiltros ? 'Limpiar filtros' : null,
        onAction: _tieneFiltros ? _limpiar : null,
      );
    }

    return RefreshIndicator(
      key: const ValueKey('list'),
      color: _VerTokens.royalBlue,
      onRefresh: () async {
        if (!NetworkService.instance.isOnline) return;
        HapticFeedback.lightImpact();
        await _load();
        if (!context.mounted) return;
        showOk(context, 'Actualizado');
      },
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: filtrados.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final c = filtrados[i];
          final idCaso = c.idCaso;
          if (idCaso == null) return const SizedBox.shrink();

          final sec = c.idSector != null
              ? (_sectorNombrePorId[c.idSector!] ?? '—')
              : '—';
          final card = SizedBox(
            width: double.infinity,
            child: _CaseCard(
              codigo: c.codigoCaso ?? '—',
              generoRaw: c.genero,
              estadoKey: c.estadoActual,
              sector: sec,
              edad: edadEfectivaCaso(c),
              numeroContactos: c.numeroContactos,
              ocupacion: (c.ocupacion == null || c.ocupacion!.trim().isEmpty)
                  ? null
                  : c.ocupacion!.trim(),
              fechaTexto: _fmtFecha(c),
              onTap: () async {
                HapticFeedback.selectionClick();
                final r = await pushSharedAxis<bool>(
                  context,
                  DetalleCasoScreen(idCaso: idCaso),
                );
                if (!mounted) return;
                if (r == true) _load();
              },
            ),
          );
          if (_animatedOnce) return card;
          return TweenAnimationBuilder<double>(
            key: ValueKey('anim_$idCaso'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 160 + (i.clamp(0, 8) * 18)),
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, (1 - v) * 6),
                child: child,
              ),
            ),
            child: card,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI components
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onOpenAdvancedFilters;
  final int advancedFiltersCount;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    this.onOpenAdvancedFilters,
    this.advancedFiltersCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final filtersBtn = onOpenAdvancedFilters == null
        ? null
        : Badge(
            isLabelVisible: advancedFiltersCount > 0,
            backgroundColor: _VerTokens.royalBlue,
            textColor: _VerTokens.chipSelectedFg,
            label: Text(
              '$advancedFiltersCount',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: IconButton(
              tooltip: 'Más filtros',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: onOpenAdvancedFilters,
              icon: Icon(
                Icons.tune_rounded,
                size: 22,
                color: _VerTokens.royalBlue,
              ),
            ),
          );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      style: GoogleFonts.inter(fontSize: 16, color: _VerTokens.shark),
      decoration: InputDecoration(
        hintText: 'Buscar por código, sector, ocupación o rango etario',
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: _VerTokens.paleSky,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: _VerTokens.paleSky),
        suffixIcon: filtersBtn,
        suffixIconConstraints: filtersBtn == null
            ? null
            : const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: _VerTokens.cardSurface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _VerTokens.blueHaze),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _VerTokens.blueHaze),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _VerTokens.royalBlue, width: 1.5),
        ),
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  final FiltroVer filtro;
  final Map<FiltroVer, int> contadores;
  final ValueChanged<FiltroVer> onSelected;

  const _StatusFilterChips({
    required this.filtro,
    required this.contadores,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({String label, FiltroVer f, Color? accent})>[
      (label: 'Todos', f: FiltroVer.todos, accent: null),
      (label: 'Caso nuevo', f: FiltroVer.nuevo, accent: _VerTokens.estadoNuevo),
      (label: 'Reingreso', f: FiltroVer.reingreso, accent: _VerTokens.estadoReingreso),
      (label: 'Tratado', f: FiltroVer.tratado, accent: _VerTokens.estadoTratado),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final it = items[i];
          final selected = filtro == it.f;
          final count = contadores[it.f] ?? 0;
          final label = count > 0 ? '${it.label} ($count)' : it.label;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(it.f),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _VerTokens.chipSelectedBg
                      : _VerTokens.cardSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? _VerTokens.chipSelectedBg
                        : _VerTokens.blueHaze,
                  ),
                  boxShadow: selected
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!selected && it.accent != null) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: it.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? _VerTokens.chipSelectedFg
                            : _VerTokens.shark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? estadoRaw;

  const _StatusBadge({required this.estadoRaw});

  @override
  Widget build(BuildContext context) {
    final k = EpidemiologiaUi.claveEstadoCaso(estadoRaw);
    final p = _badgePalette(context, k);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _verEstadoLabel(k),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: p.fg,
        ),
      ),
    );
  }
}

class _BadgePalette {
  final Color bg;
  final Color fg;
  const _BadgePalette(this.bg, this.fg);
}

_BadgePalette _badgePalette(BuildContext context, String key) {
  switch (key) {
    case 'nuevo':
      return const _BadgePalette(Color(0xFFE6F1FB), Color(0xFF0C447C));
    case 'reingreso':
      return const _BadgePalette(Color(0xFFFAEEDA), Color(0xFF633806));
    case 'tratado':
      return const _BadgePalette(Color(0xFFEAF3DE), Color(0xFF27500A));
    case 'en_estudio':
      return const _BadgePalette(Color(0xFFF1EFE8), Color(0xFF444441));
    default:
      final cs = Theme.of(context).colorScheme;
      return _BadgePalette(cs.surfaceContainerHighest, _VerTokens.paleSky);
  }
}

class _CaseCard extends StatelessWidget {
  final String codigo;
  final String? generoRaw;
  final String? estadoKey;
  final String sector;
  final int? edad;
  final int? numeroContactos;
  final String? ocupacion;
  final String fechaTexto;
  final VoidCallback onTap;

  const _CaseCard({
    required this.codigo,
    required this.generoRaw,
    required this.estadoKey,
    required this.sector,
    required this.edad,
    required this.numeroContactos,
    required this.ocupacion,
    required this.fechaTexto,
    required this.onTap,
  });

  String _edadLine() {
    if (edad != null) {
      return '$edad ${edad == 1 ? 'año' : 'años'}';
    }
    return 'Edad —';
  }

  @override
  Widget build(BuildContext context) {
    final k = EpidemiologiaUi.claveEstadoCaso(estadoKey);
    final accent = _verEstadoColor(k);
    final generoTxt = EpidemiologiaUi.generoTituloLista(generoRaw);

    final textSecondary = _VerTokens.paleSky;
    final textTertiary = _VerTokens.blueHaze;
    final contactosTxt = numeroContactos != null
        ? 'Contactos: $numeroContactos'
        : 'Contactos: —';

    return HoverScale(
      radius: 14,
      child: Material(
        color: _VerTokens.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _VerTokens.blueHaze),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: _VerTokens.bg,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(width: 4, color: accent),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CasoAvatar(genero: generoRaw),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              codigo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.publicSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _VerTokens.shark,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(estadoRaw: estadoKey),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$generoTxt · ${_edadLine()} · $fechaTexto',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sector,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 13,
                            color: textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            contactosTxt,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                          if (ocupacion != null && ocupacion!.isNotEmpty) ...[
                            Text(
                              ' · ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: textTertiary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                ocupacion!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Recuadro pequeño con ícono según género del caso (sin datos personales).
class _CasoAvatar extends StatelessWidget {
  final String? genero;

  const _CasoAvatar({required this.genero});

  @override
  Widget build(BuildContext context) {
    final spec = _avatarSpec(genero);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _VerTokens.blueHaze.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(spec.icon, size: 26, color: spec.fg),
    );
  }

  static _AvatarSpec _avatarSpec(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    if (s.isEmpty ||
        s == 'ni' ||
        s.contains('no_inf') ||
        s.contains('no inform')) {
      return _AvatarSpec(
        bg: const Color(0xFFF0F0F0),
        fg: const Color(0xFF757575),
        icon: Icons.help_outline_rounded,
      );
    }
    if (s == 'f' || s.contains('femen') || s.contains('mujer')) {
      return _AvatarSpec(
        bg: const Color(0xFFFCE4EC),
        fg: const Color(0xFFC2185B),
        icon: Icons.woman_rounded,
      );
    }
    if (s == 'm' || s.contains('mascul')) {
      return _AvatarSpec(
        bg: const Color(0xFFE3F2FD),
        fg: const Color(0xFF1565C0),
        icon: Icons.man_rounded,
      );
    }
    return _AvatarSpec(
      bg: const Color(0xFFF0F0F0),
      fg: const Color(0xFF757575),
      icon: Icons.help_outline_rounded,
    );
  }
}

class _AvatarSpec {
  final Color bg;
  final Color fg;
  final IconData icon;

  _AvatarSpec({required this.bg, required this.fg, required this.icon});
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({super.key});

  Widget _skeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: _VerTokens.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _VerTokens.blueHaze),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(height: 48, width: 48, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(child: ShimmerBox(height: 16, radius: 6)),
                    SizedBox(width: 8),
                    ShimmerBox(height: 18, width: 70, radius: 999),
                  ],
                ),
                const SizedBox(height: 10),
                const ShimmerBox(height: 12, width: 200, radius: 6),
                const SizedBox(height: 10),
                const ShimmerBox(height: 12, width: 160, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _skeletonCard(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: _VerTokens.paleSky),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _VerTokens.shark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: _VerTokens.gunPowder,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: _VerTokens.royalBlue,
                  foregroundColor: _VerTokens.chipSelectedFg,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 52, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.45,
                color: _VerTokens.shark,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: _VerTokens.royalBlue,
                foregroundColor: _VerTokens.chipSelectedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
