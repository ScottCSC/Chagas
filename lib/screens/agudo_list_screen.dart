import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';

class AgudoListScreen extends StatefulWidget {
  const AgudoListScreen({super.key});

  @override
  State<AgudoListScreen> createState() => _AgudoListScreenState();
}

class _AgudoListScreenState extends State<AgudoListScreen> {
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
          .from('chagas_agudo')
          .select('''
            id,
            folio,
            fecha_notificacion,
            ex_rn,
            ex_2m,
            ex_9m,
            observacion,
            persona (
              id_persona,
              nombre,
              rut,
              edad,
              direccion,
              telefono
            )
          ''')
          .order('fecha_notificacion', ascending: false);

      setState(() {
        registros = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, "Error cargando casos agudos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Casos de Chagas Agudo")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : registros.isEmpty
              ? const Center(child: Text("No hay casos agudos registrados"))
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
                            "Ex RN: ${r['ex_rn'] ?? '-'}\n"
                            "Ex 2m: ${r['ex_2m'] ?? '-'}\n"
                            "Ex 9m: ${r['ex_9m'] ?? '-'}\n"
                            "Obs: ${r['observacion'] ?? '-'}",
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Notificado:",
                                style: TextStyle(fontSize: 11),
                              ),
                              Text(
                                "${r['fecha_notificacion'] ?? ''}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (r['folio'] != null)
                                Text(
                                  "Folio: ${r['folio']}",
                                  style: const TextStyle(fontSize: 11),
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
