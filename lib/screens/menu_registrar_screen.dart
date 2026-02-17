import 'package:flutter/material.dart';

import '../utils/nav.dart';
import 'detalle_persona_screen.dart';
import 'grupos_list_screen.dart';
import 'registro_paciente_wizard_screen.dart';

class MenuRegistrarScreen extends StatelessWidget {
  const MenuRegistrarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrar',
          style: TextStyle(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActionCard(
              title: '+ Nuevo paciente',
              subtitle: 'Registrar paciente + módulos',
              icon: Icons.person_add_alt_1,
              iconColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              onTap: () async {
                final result = await pushSharedAxis(
                  context,
                  const RegistroPacienteWizardScreen(),
                );
                if (!context.mounted) return;
                if (result == 'registrar_otro') {
                  await pushSharedAxis(context, const RegistroPacienteWizardScreen());
                } else if (result is int) {
                  await pushSharedAxis(
                    context,
                    DetallePersonaScreen(idPersona: result),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _ActionCard(
              title: 'Operativos',
              subtitle: 'Crear/editar operativos y asignar pacientes',
              icon: Icons.groups,
              iconColor: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              onTap: () => pushFade(context, const GruposListScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: backgroundColor.withValues(alpha: 0.3),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 28,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
