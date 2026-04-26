import 'package:flutter/material.dart';

import '../utils/app_messages.dart';
import '../utils/toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeleccionarPersonaScreen extends StatefulWidget {
  final Set<int> excluirIds; // 👈 NUEVO

  const SeleccionarPersonaScreen({
    super.key,
    this.excluirIds = const {}, // por defecto, no excluye a nadie
  });

  @override
  State<SeleccionarPersonaScreen> createState() =>
      _SeleccionarPersonaScreenState();
}

class _SeleccionarPersonaScreenState extends State<SeleccionarPersonaScreen> {
  bool cargando = true;
  List personas = [];
  String filtro = '';

  @override
  void initState() {
    super.initState();
    cargarPersonas();
  }

  Future<void> cargarPersonas() async {
    final supabase = Supabase.instance.client;

    try {
      final data = await supabase
          .from('persona')
          .select('id_persona, nombre, rut, telefono, direccion, edad')
          .order('nombre', ascending: true);

      // 🔥 Filtrar las personas que NO queremos mostrar
      final filtradas = data.where((p) {
        final id = p['id_persona'] as int;
        return !widget.excluirIds.contains(id);
      }).toList();

      setState(() {
        personas = filtradas;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, AppMessages.errorCargar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = personas.where((p) {
      if (filtro.isEmpty) return true;
      final texto = (
        (p['nombre'] ?? '') +
        ' ' +
        (p['rut'] ?? '') +
        ' ' +
        (p['telefono'] ?? '')
      ).toString().toLowerCase();
      return texto.contains(filtro.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar persona')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar por nombre / RUT / teléfono',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filtro = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: listaFiltrada.isEmpty
                      ? const Center(child: Text('No hay personas registradas'))
                      : ListView.builder(
                          itemCount: listaFiltrada.length,
                          itemBuilder: (context, index) {
                            final p = listaFiltrada[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                title: Text(p['nombre'] ?? 'Sin nombre'),
                                subtitle: Text(
                                  "RUT: ${p['rut'] ?? '-'}\n"
                                  "Tel: ${p['telefono'] ?? '-'}\n"
                                  "Dir: ${p['direccion'] ?? '-'}",
                                ),
                                onTap: () {
                                  Navigator.pop(context, p['id_persona']);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
