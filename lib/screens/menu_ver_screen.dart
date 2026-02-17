import 'package:flutter/material.dart';
import 'ver_personas_screen.dart';
import 'bajo_control_list_screen.dart';
import 'tratamiento_list_screen.dart';
import 'inasistentes_list_screen.dart';
import 'agudo_list_screen.dart';
import 'gestantes_list_screen.dart';
import 'grupos_list_screen.dart';
import 'examenes_list_screen.dart';

class MenuVerScreen extends StatelessWidget {
  const MenuVerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_Item>[
      _Item(
        'Pacientes',
        Icons.people,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerPersonasScreen()),
          );
        },
      ),
      _Item(
        'Bajo control',
        Icons.assignment,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BajoControlListScreen()),
          );
        },
      ),
      _Item(
        'Tratamiento',
        Icons.medication,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TratamientoListScreen()),
          );
        },
      ),
      _Item(
        'Inasistentes',
        Icons.event_busy,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InasistentesListScreen()),
          );
        },
      ),
      _Item(
        'Agudo',
        Icons.warning_amber,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AgudoListScreen()),
          );
        },
      ),
      _Item(
        'Gestantes',
        Icons.pregnant_woman,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GestantesListScreen()),
          );
        },
      ),
      _Item(
        'Exámenes',
        Icons.assignment,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExamenesListScreen()),
          );
        },
      ),
      _Item(
        'Grupos',
        Icons.group,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GruposListScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ver',
          style: TextStyle(fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (_, i) => _MenuTile(item: items[i]),
        ),
      ),
    );
  }
}

class _Item {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _Item(this.title, this.icon, this.onTap);
}

class _MenuTile extends StatelessWidget {
  final _Item item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 40),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
