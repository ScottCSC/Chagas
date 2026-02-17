import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';

class GestantesListScreen extends StatefulWidget {
  @override
  _GestantesListScreenState createState() => _GestantesListScreenState();
}

class _GestantesListScreenState extends State<GestantesListScreen> {
  List gestantes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarGestantes();
  }

  Future<void> cargarGestantes() async {
    final supabase = Supabase.instance.client;

    try {
      final data = await supabase
          .from('chagas_gestantes')
          .select('''
            id,
            fecha_ingreso_prenatal,
            fecha_parto_aprox,
            persona (
              id_persona,
              nombre,
              rut,
              edad,
              direccion,
              telefono
            )
          ''')
          .order('fecha_ingreso_prenatal', ascending: false);

      setState(() {
        gestantes = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, 'Error cargando gestantes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestantes registradas")),
      body: cargando
          ? Center(child: CircularProgressIndicator())
          : gestantes.isEmpty
              ? Center(child: Text("No hay gestantes registradas"))
              : RefreshIndicator(
                  onRefresh: cargarGestantes,
                  child: ListView.builder(
                    itemCount: gestantes.length,
                    itemBuilder: (context, index) {
                      final g = gestantes[index];
                      final persona = g['persona'] ?? {};

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
                              Text(
                                "Ingreso:",
                                style: TextStyle(fontSize: 11),
                              ),
                              Text(
                                "${g['fecha_ingreso_prenatal'] ?? ''}",
                                style: TextStyle(
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
