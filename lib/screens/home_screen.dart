import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caso_epidemiologico.dart';
import '../repositories/app_repositories.dart';
import '../services/network_service.dart';
import '../utils/epidemiologia_ui.dart';
import '../utils/responsive_layout.dart';
import '../utils/nav.dart';
import 'detalle_caso_screen.dart';
import 'nuevo_caso_screen.dart';
import 'ver_screen.dart' show FiltroVer;

/// Tokens alineados al sistema visual del frame Home en Figma (Chagas Tracker).
class _HomeTokens {
  static const Color bg = Color(0xFFFCF8FF);
  static const Color royalBlue = Color(0xFF493EE5);
  static const Color cta = Color(0xFF635BFF);
  static const Color shark = Color(0xFF1B1B24);
  static const Color gunPowder = Color(0xFF464555);
  static const Color blueHaze = Color(0xFFC7C4D8);
  static const Color quickSurface = Color(0xFFF5F2FF);
  static const Color activityIconBg = Color(0xFFD8E2FF);
  static const Color dividerSoft = Color(0xFFE4E1EE);
  static const Color paleSky = Color(0xFF6B7280);

  static const Color kpiNuevoBg = Color(0x4DFFDAD6);
  static const Color kpiNuevoBorder = Color(0xFFD1D5DB);
  static const Color kpiNuevoNumber = Color(0xFF001A41);
  static const Color kpiNuevoCaption = Color(0xFF004493);

  static const Color kpiReingresoBg = Color(0x4DFFDDB8);
  static const Color kpiReingresoBorder = Color(0xFFFFB95F);
  static const Color kpiReingresoNumber = Color(0xFF2A1700);
  static const Color kpiReingresoCaption = Color(0xFF653E00);

  static const Color kpiTratadoBg = Color(0x4DE2DFFF);
  static const Color kpiTratadoBorder = Color(0xFFC3C0FF);
  static const Color kpiTratadoNumber = Color(0xFF0F0069);
  static const Color kpiTratadoCaption = Color(0xFF321ED2);
}

class HomeScreen extends StatefulWidget {
  /// [focusVerSearch]: al ir a Ver (índice 2), enfoca el buscador.
  /// [verEstadoFiltro]: al ir a Ver, aplica chip de estado (p. ej. desde tarjetas Inicio).
  final void Function(
    int tabIndex, {
    bool focusVerSearch,
    FiltroVer? verEstadoFiltro,
  }) onGoToTab;

  const HomeScreen({super.key, required this.onGoToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _casoRepo = AppRepositories.casoEpidemiologico;
  final _sectorRepo = AppRepositories.sector;

  List<CasoEpidemiologico> _casos = [];
  Map<int, String> _nombreSectorPorId = {};
  bool _loading = true;
  int _sectoresActivos = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!NetworkService.instance.isOnline) {
      if (mounted) {
        setState(() {
          _loading = false;
          _casos = [];
          _nombreSectorPorId = {};
          _sectoresActivos = 0;
        });
      }
      return;
    }
    if (mounted) setState(() => _loading = true);

    try {
      final list = await _casoRepo.getCasos();
      final activos = await _sectorRepo.getSectoresActivos();
      final ids = <int>{};
      for (final c in list.take(5)) {
        final sid = c.idSector;
        if (sid != null) ids.add(sid);
      }
      Map<int, String> secMap = {};
      if (ids.isNotEmpty) {
        final sectores = await _sectorRepo.getSectoresByIds(ids.toList());
        secMap = {for (final s in sectores) s.idSector: s.nombreSector};
      }
      if (!mounted) return;
      setState(() {
        _casos = list;
        _nombreSectorPorId = secMap;
        _sectoresActivos = activos.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _casos = [];
        _nombreSectorPorId = {};
        _sectoresActivos = 0;
        _loading = false;
      });
    }
  }

  int _countEstado(String clave) {
    return _casos
        .where((c) => EpidemiologiaUi.claveEstadoCaso(c.estadoActual) == clave)
        .length;
  }

  void _abrirVerCasosBuscar() {
    widget.onGoToTab(2, focusVerSearch: true);
  }

  void _irAVerEstado(FiltroVer filtro) {
    widget.onGoToTab(2, verEstadoFiltro: filtro);
  }

  String _lineaSaludo() {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata;
    if (meta != null) {
      for (final key in ['full_name', 'name', 'display_name']) {
        final v = meta[key];
        if (v is String && v.trim().isNotEmpty) {
          final part = v.trim().split(RegExp(r'\s+')).first;
          if (part.isNotEmpty) return 'Hola, $part';
        }
      }
    }
    final email = user?.email;
    if (email != null && email.contains('@')) {
      final local = email.split('@').first;
      if (local.length >= 3) return 'Hola, $local';
    }
    return 'Hola';
  }

  static String _fmtFechaLista(CasoEpidemiologico c) {
    final t = c.fechaRegistro ?? c.creadoEn;
    if (t == null) return '—';
    final l = t.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(l.year, l.month, l.day);
    if (day == today) return 'Hoy';
    if (day == today.subtract(const Duration(days: 1))) return 'Ayer';
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${l.day} ${meses[l.month - 1]}';
  }

  Future<void> _abrirNuevoCaso() async {
    final result = await pushSharedAxis(context, const NuevoCasoScreen());
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    if (result == 'registrar_otro') {
      await pushSharedAxis(context, const NuevoCasoScreen());
    } else if (result is int) {
      await pushSharedAxis(
        context,
        DetalleCasoScreen(idCaso: result),
      );
    }
  }

  void _snackProximamente(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  static const double _kQuickActionsDesktopHeight = 160;

  /// Acciones principales: en escritorio misma fila (2:1); en móvil, columna.
  Widget _buildQuickActions(bool isDesktop) {
    final nuevoCasoCard = _PrimaryActionCard(
      onPressed: _abrirNuevoCaso,
      borderRadius: 18,
      compact: isDesktop,
    );
    final verCasosCard = _QuickActionCard(
      icon: Icons.article_outlined,
      iconColor: const Color(0xFF0058BC),
      title: 'Ver casos registrados',
      subtitle:
          isDesktop ? 'Consulta y filtros' : 'Registro epidemiológico',
      onTap: () => widget.onGoToTab(2),
      borderRadius: 18,
      stacked: isDesktop,
    );

    if (isDesktop) {
      // El ListView da altura vertical ilimitada a los hijos; sin altura acotada
      // un Row + stretch rompe el layout (RenderFlex con h<=Infinity).
      return SizedBox(
        height: _kQuickActionsDesktopHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: nuevoCasoCard,
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: verCasosCard,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nuevoCasoCard,
        const SizedBox(height: 12),
        verCasosCard,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nuevo = _loading ? null : _countEstado('nuevo');
    final reingreso = _loading ? null : _countEstado('reingreso');
    final tratado = _loading ? null : _countEstado('tratado');
    final total = _loading ? null : _casos.length;
    final recientes = _casos.take(5).toList();

    return Scaffold(
      backgroundColor: _HomeTokens.bg,
      appBar: AppBar(
        backgroundColor: _HomeTokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(Icons.monitor_heart_outlined,
                  color: _HomeTokens.royalBlue, size: 26),
              const SizedBox(width: 10),
              Text(
                'Chagas Tracker',
                style: GoogleFonts.publicSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _HomeTokens.royalBlue,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Avisos',
            onPressed: () => _snackProximamente(
              'Próximamente: avisos en la plataforma.',
            ),
            icon: Icon(Icons.notifications_outlined,
                color: _HomeTokens.shark.withValues(alpha: 0.85)),
          ),
          IconButton(
            tooltip: 'Buscar casos',
            onPressed: _abrirVerCasosBuscar,
            icon: Icon(Icons.search,
                color: _HomeTokens.shark.withValues(alpha: 0.85)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: _HomeTokens.royalBlue,
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = isDesktopWidth(constraints.maxWidth);
            return responsiveContentShell(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Text(
                    _lineaSaludo(),
                    style: GoogleFonts.publicSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 32 / 24,
                      color: _HomeTokens.shark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dashboard epidemiológico territorial · equipo programa Chagas.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 24 / 16,
                      color: _HomeTokens.gunPowder,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(isDesktop),
                  const SizedBox(height: 12),
                  _QuickActionCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF815100),
                    title: 'Indicadores',
                    subtitle: 'Disponible próximamente',
                    muted: true,
                    onTap: () => _snackProximamente(
                      'Indicadores en preparación.',
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Estado actual',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      color: _HomeTokens.gunPowder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_loading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.map_outlined,
                              size: 18, color: _HomeTokens.paleSky),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$_sectoresActivos sectores territoriales activos en catálogo.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 1.35,
                                color: _HomeTokens.gunPowder,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child:
                              CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    )
                  else if (isDesktop)
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: kKpiCardWidth,
                          child: _TotalMetricCard(
                            value: total ?? 0,
                            onTap: () => widget.onGoToTab(2),
                          ),
                        ),
                        SizedBox(
                          width: kKpiCardWidth,
                          child: _StatusMetricCard(
                            icon: Icons.person_add_alt_1_outlined,
                            iconColor: _HomeTokens.kpiNuevoCaption,
                            value: nuevo ?? 0,
                            caption: 'Casos nuevos',
                            background: _HomeTokens.kpiNuevoBg,
                            borderColor: _HomeTokens.kpiNuevoBorder,
                            valueColor: _HomeTokens.kpiNuevoNumber,
                            captionColor: _HomeTokens.kpiNuevoCaption,
                            onTap: () => _irAVerEstado(FiltroVer.nuevo),
                          ),
                        ),
                        SizedBox(
                          width: kKpiCardWidth,
                          child: _StatusMetricCard(
                            icon: Icons.history_rounded,
                            iconColor: _HomeTokens.kpiReingresoCaption,
                            value: reingreso ?? 0,
                            caption: 'Reingresos',
                            background: _HomeTokens.kpiReingresoBg,
                            borderColor: _HomeTokens.kpiReingresoBorder,
                            valueColor: _HomeTokens.kpiReingresoNumber,
                            captionColor: _HomeTokens.kpiReingresoCaption,
                            onTap: () => _irAVerEstado(FiltroVer.reingreso),
                          ),
                        ),
                        SizedBox(
                          width: kKpiCardWidth,
                          child: _StatusMetricCard(
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: _HomeTokens.kpiTratadoCaption,
                            value: tratado ?? 0,
                            caption: 'Tratados',
                            background: _HomeTokens.kpiTratadoBg,
                            borderColor: _HomeTokens.kpiTratadoBorder,
                            valueColor: _HomeTokens.kpiTratadoNumber,
                            captionColor: _HomeTokens.kpiTratadoCaption,
                            onTap: () => _irAVerEstado(FiltroVer.tratado),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _TotalMetricCard(
                      value: total ?? 0,
                      onTap: () => widget.onGoToTab(2),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _StatusMetricCard(
                            icon: Icons.person_add_alt_1_outlined,
                            iconColor: _HomeTokens.kpiNuevoCaption,
                            value: nuevo ?? 0,
                            caption: 'Casos nuevos',
                            background: _HomeTokens.kpiNuevoBg,
                            borderColor: _HomeTokens.kpiNuevoBorder,
                            valueColor: _HomeTokens.kpiNuevoNumber,
                            captionColor: _HomeTokens.kpiNuevoCaption,
                            onTap: () => _irAVerEstado(FiltroVer.nuevo),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatusMetricCard(
                            icon: Icons.history_rounded,
                            iconColor: _HomeTokens.kpiReingresoCaption,
                            value: reingreso ?? 0,
                            caption: 'Reingresos',
                            background: _HomeTokens.kpiReingresoBg,
                            borderColor: _HomeTokens.kpiReingresoBorder,
                            valueColor: _HomeTokens.kpiReingresoNumber,
                            captionColor: _HomeTokens.kpiReingresoCaption,
                            onTap: () => _irAVerEstado(FiltroVer.reingreso),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StatusMetricCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: _HomeTokens.kpiTratadoCaption,
                      value: tratado ?? 0,
                      caption: 'Tratados',
                      background: _HomeTokens.kpiTratadoBg,
                      borderColor: _HomeTokens.kpiTratadoBorder,
                      valueColor: _HomeTokens.kpiTratadoNumber,
                      captionColor: _HomeTokens.kpiTratadoCaption,
                      fullWidth: true,
                      onTap: () => _irAVerEstado(FiltroVer.tratado),
                    ),
                  ],
                  const SizedBox(height: 28),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _HomeTokens.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _HomeTokens.blueHaze),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: () => widget.onGoToTab(2),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 12, 16),
                                child: Row(
                                  children: [
                                    Text(
                                      'Actividad reciente',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.28,
                                        color: _HomeTokens.shark,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Ver todos',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.48,
                                        color: _HomeTokens.royalBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: _HomeTokens.blueHaze),
                          if (recientes.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 22,
                              ),
                              child: Text(
                                _loading
                                    ? 'Cargando…'
                                    : 'Aún no hay registros recientes.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recientes.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                height: 1,
                                thickness: 1,
                                color: _HomeTokens.dividerSoft,
                              ),
                              itemBuilder: (context, i) {
                                final c = recientes[i];
                                final sid = c.idSector;
                                final sector = sid != null
                                    ? (_nombreSectorPorId[sid] ?? 'Sector')
                                    : '—';
                                return _RecentCaseItem(
                                  codigo: c.codigoCaso ?? '—',
                                  sector: sector,
                                  estadoLabel:
                                      EpidemiologiaUi.getEstadoCasoLabel(
                                    c.estadoActual ?? '',
                                  ),
                                  estadoColor:
                                      EpidemiologiaUi.getEstadoCasoColor(
                                    c.estadoActual ?? '',
                                  ),
                                  cuando: _fmtFechaLista(c),
                                  onTap: c.idCaso != null
                                      ? () {
                                          pushSharedAxis(
                                            context,
                                            DetalleCasoScreen(
                                                idCaso: c.idCaso!),
                                          ).then((_) {
                                            if (mounted) _load();
                                          });
                                        }
                                      : null,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- Widgets de UI ---

class _PrimaryActionCard extends StatelessWidget {
  final VoidCallback onPressed;
  final double borderRadius;
  /// Layout denso para fila desktop con altura fija.
  final bool compact;

  const _PrimaryActionCard({
    required this.onPressed,
    this.borderRadius = 18,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(borderRadius);
    final pad = compact
        ? const EdgeInsets.fromLTRB(14, 14, 14, 12)
        : const EdgeInsets.all(22);
    final iconSize = compact ? 22.0 : 32.0;
    final iconPadH = compact ? 10.0 : 12.0;
    final iconPadV = compact ? 7.0 : 9.0;
    final gapAfterIcon = compact ? 10.0 : 18.0;
    final titleSize = compact ? 16.0 : 20.0;
    final titleH = compact ? 22 / 16 : 28 / 20;
    final subSize = compact ? 11.0 : 14.0;
    final subH = compact ? 1.25 : 20 / 14;

    return Material(
      color: _HomeTokens.cta,
      borderRadius: r,
      clipBehavior: Clip.antiAlias,
      elevation: compact ? 1 : 2,
      shadowColor: Colors.black.withValues(alpha: compact ? 0.04 : 0.08),
      child: InkWell(
        borderRadius: r,
        onTap: onPressed,
        child: Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: iconPadH,
                  vertical: iconPadV,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: iconSize,
                ),
              ),
              SizedBox(height: gapAfterIcon),
              Text(
                'Registrar nuevo caso',
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.publicSans(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  height: titleH,
                  color: const Color(0xFFFCF8FF),
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
              if (compact)
                Expanded(
                  child: Text(
                    'Ingresar datos anónimos: género, edad, sector y estado del caso.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: subSize,
                      height: subH,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                )
              else
                Text(
                  'Ingresar datos anónimos: género, edad, sector y estado del caso.',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: subSize,
                    height: subH,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  /// Estilo atenuado (p. ej. función aún no disponible).
  final bool muted;
  final double borderRadius;
  /// Misma columna visual que la card principal (escritorio, fila de acciones).
  final bool stacked;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.muted = false,
    this.borderRadius = 12,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = muted ? 0.55 : 1.0;
    final r = BorderRadius.circular(borderRadius);

    if (stacked) {
      return Opacity(
        opacity: opacity,
        child: Material(
          color: _HomeTokens.quickSurface,
          borderRadius: r,
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          child: InkWell(
            borderRadius: r,
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: r,
                border: Border.all(color: _HomeTokens.blueHaze),
              ),
              child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: _HomeTokens.shark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: _HomeTokens.gunPowder,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _HomeTokens.gunPowder.withValues(alpha: 0.45),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    }

    return Opacity(
      opacity: opacity,
      child: Material(
        color: _HomeTokens.quickSurface,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              border: Border.all(color: _HomeTokens.blueHaze),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.28,
                            color: _HomeTokens.shark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.48,
                            color: _HomeTokens.gunPowder,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _HomeTokens.gunPowder.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// KPI resumen: total de casos cargados en el panel.
class _TotalMetricCard extends StatelessWidget {
  final int value;
  final VoidCallback onTap;

  const _TotalMetricCard({
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _HomeTokens.blueHaze),
          ),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.analytics_outlined,
                    size: 26, color: _HomeTokens.gunPowder),
                const SizedBox(height: 8),
                Text(
                  '$value',
                  style: GoogleFonts.publicSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 38 / 30,
                    letterSpacing: -0.6,
                    color: _HomeTokens.shark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TOTAL CASOS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.48,
                    height: 16 / 12,
                    color: _HomeTokens.gunPowder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final String caption;
  final Color background;
  final Color borderColor;
  final Color valueColor;
  final Color captionColor;
  final VoidCallback onTap;
  final bool fullWidth;

  const _StatusMetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.caption,
    required this.background,
    required this.borderColor,
    required this.valueColor,
    required this.captionColor,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: iconColor),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: GoogleFonts.publicSans(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 38 / 30,
              letterSpacing: -0.6,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.48,
              height: 16 / 12,
              color: captionColor,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: inner,
        ),
      ),
    );
  }
}

class _RecentCaseItem extends StatelessWidget {
  final String codigo;
  final String sector;
  final String estadoLabel;
  final Color estadoColor;
  final String cuando;
  final VoidCallback? onTap;

  const _RecentCaseItem({
    required this.codigo,
    required this.sector,
    required this.estadoLabel,
    required this.estadoColor,
    required this.cuando,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _HomeTokens.activityIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_outlined,
                    size: 22, color: _HomeTokens.royalBlue.withValues(alpha: 0.9)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      codigo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 24 / 16,
                        color: _HomeTokens.shark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: estadoColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$sector · $estadoLabel',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 20 / 14,
                              color: _HomeTokens.gunPowder,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 72),
                    child: Text(
                      cuando,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                        letterSpacing: 0.48,
                        color: _HomeTokens.gunPowder,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: _HomeTokens.gunPowder.withValues(alpha: 0.45)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
