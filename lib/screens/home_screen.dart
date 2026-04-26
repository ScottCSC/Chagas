import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../repositories/app_repositories.dart';
import '../services/network_service.dart';
import '../utils/nav.dart';
import '../widgets/states.dart';
import 'detalle_persona_screen.dart';
import 'examenes_list_screen.dart';
import 'grupos_list_screen.dart';
import 'inasistentes_list_screen.dart';
import 'registro_paciente_wizard_screen.dart';

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
              StreamBuilder<bool>(
                stream: NetworkService.instance.connectivityStream,
                initialData: NetworkService.instance.isOnline,
                builder: (context, snapshot) {
                  final online = snapshot.data ?? true;
                  return _StatusBanner(isOnline: online);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 28),
                  label: const Text(
                    'REGISTRAR PACIENTE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(72),
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final result = await pushSharedAxis(
                      context,
                      const RegistroPacienteWizardScreen(),
                    );
                    if (!context.mounted) return;
                    if (result == 'registrar_otro') {
                      await pushSharedAxis(
                        context,
                        const RegistroPacienteWizardScreen(),
                      );
                    } else if (result is int) {
                      await pushSharedAxis(
                        context,
                        DetallePersonaScreen(idPersona: result),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Pendientes'),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _loading
                    ? const Padding(
                        key: ValueKey('pend_loading'),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: AppLoading(compact: true),
                      )
                    : _PendientesCard(
                        key: const ValueKey('pend_card'),
                        sinControl: _stats?['sinControl'] ?? 0,
                        examenesPendientes: _stats?['examenesPendientes'] ?? 0,
                        examenesAtrasados: _stats?['examenesAtrasados'] ?? 0,
                        onSinControl: () =>
                            pushFade(context, const InasistentesListScreen()),
                        onExamenesPendientes: () => pushFade(
                          context,
                          const ExamenesListScreen(initialFilter: 'pending'),
                        ),
                        onExamenesAtrasados: () => pushFade(
                          context,
                          const ExamenesListScreen(initialFilter: 'overdue'),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Accesos rápidos'),
              const SizedBox(height: 8),
              _QuickActionsSection(
                onBuscarPaciente: () => widget.onGoToTab(2),
                onGrupos: () => pushFade(context, GruposListScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final bool isOnline;

  const _StatusBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isOnline ? Colors.green.shade50 : Colors.red.shade50;
    final iconColor =
        isOnline ? Colors.green.shade700 : Colors.red.shade700;
    final borderColor =
        isOnline ? Colors.green.shade100 : Colors.red.shade100;
    final title = isOnline ? 'Conectado' : 'Sin conexión';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.cloud_off,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onBuscarPaciente;
  final VoidCallback onGrupos;

  const _QuickActionsSection({
    required this.onBuscarPaciente,
    required this.onGrupos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickActionTile(
          icon: Icons.search,
          title: 'Buscar paciente',
          onTap: onBuscarPaciente,
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          icon: Icons.groups_2_outlined,
          title: 'Grupos',
          onTap: onGrupos,
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 26, color: Colors.grey.shade800),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
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
  final VoidCallback onSinControl;
  final VoidCallback onExamenesPendientes;
  final VoidCallback onExamenesAtrasados;

  const _PendientesCard({
    super.key,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      '$sinControl ${sinControl == 1 ? 'paciente' : 'pacientes'} sin control',
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
                  Icon(Icons.check_circle_outline,
                      color: Colors.green.shade700, size: 22),
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
