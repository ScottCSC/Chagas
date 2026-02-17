import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/nav.dart';
import '../utils/toast.dart';
import 'crear_grupo_screen.dart';
import 'grupo_detalle_screen.dart';

class GruposListScreen extends StatefulWidget {
  const GruposListScreen({super.key});

  @override
  State<GruposListScreen> createState() => _GruposListScreenState();
}

class _GruposListScreenState extends State<GruposListScreen> {
  bool cargando = true;
  List grupos = [];

  @override
  void initState() {
    super.initState();
    cargarGrupos();
  }

  Future<void> cargarGrupos() async {
    final supabase = Supabase.instance.client;

    try {
      final data = await supabase
          .from('grupo_contacto')
          .select('id_grupo, nombre_grupo, direccion, fecha_operativo, descripcion, persona_grupo(count)')
          .order('fecha_operativo', ascending: false);

      setState(() {
        grupos = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, 'Error cargando grupos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grupos / operativos')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : grupos.isEmpty
              ? const Center(child: Text('No hay grupos registrados'))
              : RefreshIndicator(
                  onRefresh: cargarGrupos,
                  child: ListView.builder(
                    itemCount: grupos.length,
                    itemBuilder: (context, index) {
                      final g = grupos[index];
                      final count = (g['persona_grupo'] is List &&
                              g['persona_grupo'].isNotEmpty)
                          ? (g['persona_grupo'][0]['count'] ?? 0)
                          : 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            g['nombre_grupo'] ?? 'Sin nombre',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Fecha: ${g['fecha_operativo'] ?? '-'}\n"
                            "Dirección: ${g['direccion'] ?? '-'}\n"
                            "Personas asociadas: $count",
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GrupoDetalleScreen(
                                  idGrupo: g['id_grupo'] as int,
                                  nombreGrupo:
                                      g['nombre_grupo'] ?? 'Grupo sin nombre',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await pushSharedAxis(
            context,
            const CrearGrupoScreen(),
          );
          if (result == true && mounted) {
            cargarGrupos();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear operativo'),
      ),
    );
  }
}
