import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';
import '../widgets/form_actions_row.dart';
import 'crear_persona_screen.dart';
import 'seleccionar_persona_screen.dart';

class GrupoDetalleScreen extends StatefulWidget {
  final int idGrupo;
  final String nombreGrupo;

  const GrupoDetalleScreen({
    super.key,
    required this.idGrupo,
    required this.nombreGrupo,
  });

  @override
  State<GrupoDetalleScreen> createState() => _GrupoDetalleScreenState();
}

class _GrupoDetalleScreenState extends State<GrupoDetalleScreen> {
  bool cargando = true;
  List miembros = [];

  @override
  void initState() {
    super.initState();
    cargarMiembros();
  }

  Future<void> cargarMiembros() async {
    final supabase = Supabase.instance.client;

    try {
      final data = await supabase
          .from('persona_grupo')
          .select('''
            id,
            tipo_relacion,
            persona (
              id_persona,
              nombre,
              rut,
              edad,
              direccion,
              telefono
            )
          ''')
          .eq('id_grupo', widget.idGrupo)
          .order('id', ascending: true);

      setState(() {
        miembros = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, 'Error cargando miembros: $e');
    }
  }

  Future<String?> elegirTipoRelacion() async {
    String temp = 'contacto';

    return showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Tipo de relación'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButton<String>(
                value: temp,
                items: const [
                  DropdownMenuItem(value: 'familiar', child: Text('Familiar')),
                  DropdownMenuItem(value: 'vecino', child: Text('Vecino')),
                  DropdownMenuItem(
                      value: 'conviviente', child: Text('Conviviente')),
                  DropdownMenuItem(value: 'contacto', child: Text('Contacto')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() => temp = val);
                  }
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, temp),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> agregarPersona(int idPersona) async {
    final tipo = await elegirTipoRelacion();

    if (tipo == null) return;

    final supabase = Supabase.instance.client;

    try {
      // 1) Revisar si ya existe en el grupo
      final existente = await supabase
          .from('persona_grupo')
          .select('id')
          .eq('id_grupo', widget.idGrupo)
          .eq('id_persona', idPersona)
          .maybeSingle();

      if (existente != null) {
        showErr(context, 'Esta persona ya está asociada a este grupo');
        return;
      }

      // 2) Insertar si no existe
      await supabase.from('persona_grupo').insert({
        'id_grupo': widget.idGrupo,
        'id_persona': idPersona,
        'tipo_relacion': tipo,
      });

      await cargarMiembros();
    } catch (e) {
      showErr(context, 'Error agregando persona al grupo: $e');
    }
  }

  void agregarPersonaNueva() async {
    final nuevoId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CrearPersonaScreen()),
    );
    if (nuevoId != null) {
      await agregarPersona(int.parse(nuevoId.toString()));
    }
  }

  void agregarPersonaExistente() async {
    // 1️⃣ Obtener los id_persona que ya están en este grupo
    final idsExistentes = miembros
        .map<int?>((m) {
          final p = m['persona'];
          if (p == null) return null;
          return p['id_persona'] as int?;
        })
        .whereType<int>() // elimina nulls
        .toSet();

    // 2️⃣ Llamar al selector excluyendo esos IDs
    final seleccionadoId = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarPersonaScreen(
          excluirIds: idsExistentes,
        ),
      ),
    );

    if (seleccionadoId != null) {
      await agregarPersona(int.parse(seleccionadoId.toString()));
    }
  }

  Future<void> eliminarMiembro(int idRelacion) async {
    final supabase = Supabase.instance.client;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar del grupo'),
        content: const Text('¿Seguro que quieres quitar a esta persona del grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await supabase
          .from('persona_grupo')
          .delete()
          .eq('id', idRelacion);

      await cargarMiembros();
    } catch (e) {
      showErr(context, 'Error al quitar persona del grupo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreGrupo),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FormActionsRow(
              leftText: 'Agregar existente',
              rightText: 'Nueva persona',
              onLeft: agregarPersonaExistente,
              onRight: agregarPersonaNueva,
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : miembros.isEmpty
                    ? const Center(child: Text('Este grupo aún no tiene personas'))
                    : RefreshIndicator(
                        onRefresh: cargarMiembros,
                        child: ListView.builder(
                          itemCount: miembros.length,
                          itemBuilder: (context, index) {
                            final m = miembros[index];
                            final p = m['persona'] ?? {};

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(
                                  p['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "RUT: ${p['rut'] ?? '-'}\n"
                                  "Tel: ${p['telefono'] ?? '-'}\n"
                                  "Dirección: ${p['direccion'] ?? '-'}\n"
                                  "Relación: ${m['tipo_relacion'] ?? '-'}",
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => eliminarMiembro(m['id'] as int),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
