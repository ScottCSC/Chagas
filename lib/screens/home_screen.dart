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
          padding: const EdgeInsets.all(16),
          children: [
            // 1) CTA principal: Nuevo Caso (wizard visual epidemiológico)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 24),
                label: const Text(
                  '+ Nuevo caso',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final result = await pushSharedAxis(
                    context,
                    const NuevoCasoScreen(),
                  );
                  if (!context.mounted) return;
                  if (result == 'registrar_otro') {
                    await pushSharedAxis(
                      context,
                      const NuevoCasoScreen(),
                    );
                  } else if (result is int) {
                    await pushSharedAxis(
                      context,
                      DetalleCasoScreen(idCaso: result),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            // Card Operativos
            InkWell(
              onTap: () => pushFade(context, GruposListScreen()),
              borderRadius: BorderRadius.circular(14),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.groups, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Operativos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2) Resumen (KPIs) — clickeables
            const Text(
              'Resumen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _loading
                  ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.all(20),
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

            // 3) Pendientes
            const Text(
              'Pendientes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _PendientesCard(
              sinControl: _stats?['sinControl'] ?? 0,
              examenesPendientes: _stats?['examenesPendientes'] ?? 0,
              examenesAtrasados: _stats?['examenesAtrasados'] ?? 0,
              onSinControl: null,
              onExamenesPendientes: null,
              onExamenesAtrasados: null,
            ),
            const SizedBox(height: 16),

            // 4) Consejo / tutorial rápido
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '💡 Toca "Casos" en la barra inferior para buscar y filtrar.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _KpiCard(
          label: 'Casos hoy',
          value: stats['hoy'] ?? 0,
          cta: 'Ver hoy',
          onTap: onOpenVerToday,
        ),
        _KpiCard(
          label: 'Casos últimos 7 días',
          value: stats['semana'] ?? 0,
          cta: 'Ver registros',
          onTap: onOpenVerLast7,
        ),
        _KpiCard(
          label: 'Sectores activos',
          value: stats['sectoresActivos'] ?? 0,
          cta: 'Ver listado',
          onTap: onOpenSectores,
        ),
        _KpiCard(
          label: 'Total casos',
          value: stats['total'] ?? 0,
          cta: 'Ver todos',
          onTap: onOpenVerAll,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final String cta;
  final VoidCallback onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cta,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
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

    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    trailing: const Icon(Icons.chevron_right),
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
                    trailing: const Icon(Icons.chevron_right),
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
                    trailing: const Icon(Icons.chevron_right),
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
                  const Text(
                    'No hay pendientes por ahora',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
    );
  }
}
