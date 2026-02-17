import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';

class BajoControlListScreen extends StatefulWidget {
  const BajoControlListScreen({super.key});

  @override
  State<BajoControlListScreen> createState() => _BajoControlListScreenState();
}

class _BajoControlListScreenState extends State<BajoControlListScreen> {
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
          .from('chagas_bajo_control')
          .select('''
            id,
            folio,
            fecha_notificacion,
            fecha_confirmacion,
            ultimo_control,
            proximo_control,
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
      showErr(context, 'Error cargando registros: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pacientes bajo control")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : registros.isEmpty
              ? const Center(child: Text("No hay registros bajo control"))
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
                          title: Text(persona['nombre'] ?? 'Sin nombre'),
                          subtitle: Text(
                            "RUT: ${persona['rut'] ?? '-'}\n"
                            "Tel: ${persona['telefono'] ?? '-'}\n"
                            "Dirección: ${persona['direccion'] ?? '-'}",
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
                              if (r['proximo_control'] != null)
                                Text(
                                  "Próx: ${r['proximo_control']}",
                                  style: const TextStyle(
                                    fontSize: 11,
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
