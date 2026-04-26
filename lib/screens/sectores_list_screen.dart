import 'package:flutter/material.dart';

import '../repositories/app_repositories.dart';
import '../models/sector.dart';

/// Listado informativo de sectores (usado desde el KPI Sectores activos).
class SectoresListScreen extends StatefulWidget {
  const SectoresListScreen({super.key});

  @override
  State<SectoresListScreen> createState() => _SectoresListScreenState();
}

class _SectoresListScreenState extends State<SectoresListScreen> {
  final _repo = AppRepositories.sector;
  List<Sector> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final s = await _repo.getSectoresActivos();
      if (mounted) {
        setState(() {
          _list = s;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _list = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sectores activos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: _list.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text('No hay sectores o no se pudieron cargar.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final s = _list[i];
                        return Card(
                          child: ListTile(
                            title: Text(s.nombreSector, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(s.comuna == null || s.comuna!.isEmpty ? '—' : s.comuna!),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
