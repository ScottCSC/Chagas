import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../repositories/app_repositories.dart';
import '../services/network_service.dart';
import '../utils/nav.dart';
import 'nuevo_caso_screen.dart';
import 'detalle_caso_screen.dart';
import 'grupos_list_screen.dart';
import 'sectores_list_screen.dart';
import 'ver_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex) onGoToTab;

  const HomeScreen({super.key, required this.onGoToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!NetworkService.instance.isOnline) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final s = await AppRepositories.stats.getHomeStats();
    if (!mounted) return;
    setState(() {
      _stats = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final salir = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Salir de la aplicación'),
            content: const Text('¿Deseas salir de la aplicación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salir'),
              ),
            ],
          ),
        );

        if (salir == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chagas Tracker',
            style: TextStyle(fontSize: 20),
          ),
          actions: [
            IconButton(
              onPressed: () => widget.onGoToTab(3),
              icon: const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 18),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            if (!NetworkService.instance.isOnline) return;
            await _load();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _NuevoCasoCta(
                onPressed: () async {
                  final result =
                      await pushSharedAxis(context, const NuevoCasoScreen());
                  if (!context.mounted) return;
                  if (result == 'registrar_otro') {
                    await pushSharedAxis(context, const NuevoCasoScreen());
                  } else if (result is int) {
                    await pushSharedAxis(
                      context,
                      DetalleCasoScreen(idCaso: result),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _AccesoOperativos(
                onTap: () => pushFade(context, GruposListScreen()),
              ),
              const SizedBox(height: 24),

              const _SectionLabel('Resumen'),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _loading
                    ? const Padding(
                        key: ValueKey('loading'),
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _ResumenGrid(
                        key: const ValueKey('stats'),
                        stats: _stats ?? {},
                        onOpenVerToday: () => pushFade(
                          context,
                          const VerScreen(initialFilter: 'today'),
                        ),
                        onOpenVerLast7: () => pushFade(
                          context,
                          const VerScreen(initialFilter: 'last7'),
                        ),
                        onOpenVerAll: () => pushFade(
                          context,
                          const VerScreen(initialFilter: 'all'),
                        ),
                        onOpenSectores: () => pushFade(
                          context,
                          const SectoresListScreen(),
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              const _SectionLabel('Pendientes'),
              const SizedBox(height: 12),
              _PendientesCard(
                sinControl: _stats?['sinControl'] ?? 0,
                examenesPendientes: _stats?['examenesPendientes'] ?? 0,
                examenesAtrasados: _stats?['examenesAtrasados'] ?? 0,
                onSinControl: null,
                onExamenesPendientes: null,
                onExamenesAtrasados: null,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Casos: búsqueda y filtros en la barra inferior.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NuevoCasoCta extends StatelessWidget {
  final VoidCallback onPressed;
  const _NuevoCasoCta({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_circle_outline,
                    color: cs.onPrimary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nuevo caso',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Registrar caso epidemiológico anónimo',
                      style: TextStyle(
                        color: cs.onPrimary.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccesoOperativos extends StatelessWidget {
  final VoidCallback onTap;
  const _AccesoOperativos({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.groups, size: 24, color: cs.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Operativos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: cs.primary,
      ),
    );
  }
}

class _ResumenGrid extends StatelessWidget {
  final Map<String, int> stats;
  final VoidCallback onOpenVerToday;
  final VoidCallback onOpenVerLast7;
  final VoidCallback onOpenVerAll;
  final VoidCallback onOpenSectores;

  const _ResumenGrid({
    super.key,
    required this.stats,
    required this.onOpenVerToday,
    required this.onOpenVerLast7,
    required this.onOpenVerAll,
    required this.onOpenSectores,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _KpiCard(
          icon: Icons.today,
          color: cs.primary,
          label: 'Casos hoy',
          value: stats['hoy'] ?? 0,
          onTap: onOpenVerToday,
        ),
        _KpiCard(
          icon: Icons.calendar_view_week,
          color: const Color(0xFFF9A825),
          label: 'Últimos 7 días',
          value: stats['semana'] ?? 0,
          onTap: onOpenVerLast7,
        ),
        _KpiCard(
          icon: Icons.place_outlined,
          color: const Color(0xFF2E7D32),
          label: 'Sectores activos',
          value: stats['sectoresActivos'] ?? 0,
          onTap: onOpenSectores,
        ),
        _KpiCard(
          icon: Icons.assignment_outlined,
          color: const Color(0xFF6A1B9A),
          label: 'Total casos',
          value: stats['total'] ?? 0,
          onTap: onOpenVerAll,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  final VoidCallback onTap;

  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendientesCard extends StatelessWidget {
  final int sinControl;
  final int examenesPendientes;
  final int examenesAtrasados;
  final VoidCallback? onSinControl;
  final VoidCallback? onExamenesPendientes;
  final VoidCallback? onExamenesAtrasados;

  const _PendientesCard({
    required this.sinControl,
    required this.examenesPendientes,
    required this.examenesAtrasados,
    required this.onSinControl,
    required this.onExamenesPendientes,
    required this.onExamenesAtrasados,
  });

  @override
  Widget build(BuildContext context) {
    final hasPendientes =
        sinControl > 0 || examenesPendientes > 0 || examenesAtrasados > 0;

    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: hasPendientes
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sinControl > 0)
                  ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      size: 22,
                      color: Colors.orange.shade700,
                    ),
                    title: Text(
                      '$sinControl ${sinControl == 1 ? 'caso' : 'casos'} sin seguimiento',
                    ),
                    trailing: onSinControl != null
                        ? const Icon(Icons.chevron_right)
                        : null,
                    enabled: onSinControl != null,
                    onTap: onSinControl,
                  ),
                if (examenesPendientes > 0)
                  ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      size: 22,
                      color: Colors.orange.shade700,
                    ),
                    title: Text(
                      '$examenesPendientes ${examenesPendientes == 1 ? 'examen' : 'exámenes'} pendientes',
                    ),
                    trailing: onExamenesPendientes != null
                        ? const Icon(Icons.chevron_right)
                        : null,
                    enabled: onExamenesPendientes != null,
                    onTap: onExamenesPendientes,
                  ),
                if (examenesAtrasados > 0)
                  ListTile(
                    leading: const Icon(
                      Icons.error_outline,
                      size: 22,
                      color: Colors.red,
                    ),
                    title: Text(
                      '$examenesAtrasados ${examenesAtrasados == 1 ? 'examen atrasado' : 'exámenes atrasados'}',
                    ),
                    trailing: onExamenesAtrasados != null
                        ? const Icon(Icons.chevron_right)
                        : null,
                    enabled: onExamenesAtrasados != null,
                    onTap: onExamenesAtrasados,
                  ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sin pendientes registrados.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
