import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';

class TratamientoListScreen extends StatefulWidget {
  const TratamientoListScreen({super.key});

  @override
  State<TratamientoListScreen> createState() => _TratamientoListScreenState();
}

class _TratamientoListScreenState extends State<TratamientoListScreen> {
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
          .from('chagas_tratamiento')
          .select('''
            id,
            fecha_inicio,
            nombre_tratamiento,
            lugar_tratamiento,
            medico_tratante,
            persona (
              id_persona,
              nombre,
              rut,
              edad,
              direccion,
              telefono
            )
          ''')
          .order('fecha_inicio', ascending: false);

      setState(() {
        registros = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, "Error cargando tratamientos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pacientes en tratamiento")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : registros.isEmpty
              ? const Center(child: Text("No hay pacientes en tratamiento"))
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
                            "Tratamiento: ${r['nombre_tratamiento'] ?? '-'}\n"
                            "Lugar: ${r['lugar_tratamiento'] ?? '-'}\n"
                            "Médico: ${r['medico_tratante'] ?? '-'}",
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Inicio:",
                                style: TextStyle(fontSize: 11),
                              ),
                              Text(
                                "${r['fecha_inicio'] ?? ''}",
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
