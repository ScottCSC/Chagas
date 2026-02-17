import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';

class InasistentesListScreen extends StatefulWidget {
  const InasistentesListScreen({super.key});

  @override
  State<InasistentesListScreen> createState() => _InasistentesListScreenState();
}

class _InasistentesListScreenState extends State<InasistentesListScreen> {
  bool cargando = true;
  List registros = [];

  @override
  void initState() {
    super.initState();
    cargarRegistros();
  }

  Future<void> cargarRegistros() async {
    final supabase = Supabase.instance.client;

    try {
      final data = await supabase
          .from('chagas_inasistentes')
          .select('''
            id,
            fecha_inasistencia,
            tipo_control,
            persona (
              id_persona,
              nombre,
              rut,
              edad,
              direccion,
              telefono
            )
          ''')
          .order('fecha_inasistencia', ascending: false);

      setState(() {
        registros = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, "Error cargando inasistentes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pacientes inasistentes")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : registros.isEmpty
              ? const Center(child: Text("No hay inasistencias registradas"))
              : RefreshIndicator(
                  onRefresh: cargarRegistros,
                  child: ListView.builder(
                    itemCount: registros.length,
                    itemBuilder: (context, index) {
                      final r = registros[index];
                      final persona = r['persona'] ?? {};

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            persona['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "RUT: ${persona['rut'] ?? '-'}\n"
                            "Tel: ${persona['telefono'] ?? '-'}\n"
                            "Dirección: ${persona['direccion'] ?? '-'}\n"
                            "Tipo de control: ${r['tipo_control'] ?? '-'}",
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Fecha inasistencia:",
                                style: TextStyle(fontSize: 11),
                              ),
                              Text(
                                "${r['fecha_inasistencia'] ?? ''}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
