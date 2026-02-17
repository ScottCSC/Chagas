import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';
import 'detalle_persona_screen.dart';

class VerPersonasScreen extends StatefulWidget {
  const VerPersonasScreen({super.key});

  @override
  State<VerPersonasScreen> createState() => _VerPersonasScreenState();
}

class _VerPersonasScreenState extends State<VerPersonasScreen> {
  final supabase = Supabase.instance.client;

  List personas = [];
  List personasFiltradas = [];
  bool cargando = true;

  String busqueda = "";
  String filtro = "todos"; // todos, gestantes, bajo_control, tratamiento, agudo
  String orden = "recientes"; // recientes, az, za

  @override
  void initState() {
    super.initState();
    cargarPersonas();
  }

  Future<void> cargarPersonas() async {
    try {
      setState(() => cargando = true);

      final data = await supabase
          .from('persona')
          .select()
          .order('id_persona', ascending: false)
          .timeout(const Duration(seconds: 10));

      personas = data;
      aplicarFiltros();

      setState(() => cargando = false);
    } catch (e) {
      debugPrint("Error cargando personas: $e");
      setState(() => cargando = false);
      
      if (mounted) {
        final msg = e.toString().contains('timeout') || e.toString().contains('Connection timed out')
            ? 'No se pudo conectar con el servidor. Verifica tu conexión a internet.'
            : 'Error al cargar pacientes: $e';
        showErrWithAction(context, msg, actionLabel: 'Reintentar', onAction: cargarPersonas);
      }
    }
  }

  Future<bool> personaTiene(String tabla, int idPersona) async {
    final res = await supabase
        .from(tabla)
        .select()
        .eq('id_persona', idPersona)
        .maybeSingle();

    return res != null;
  }

  Future<void> aplicarFiltros() async {
    List filtradas = [...personas];

    // 🔎 BUSQUEDA
    if (busqueda.isNotEmpty) {
      filtradas = filtradas.where((p) {
        final nombre = (p['nombre'] ?? '').toString().toLowerCase();
        final rut = (p['rut'] ?? '').toString().toLowerCase();

        return nombre.contains(busqueda.toLowerCase()) ||
            rut.contains(busqueda.toLowerCase());
      }).toList();
    }

    // 🟣 FILTROS AVANZADOS
    if (filtro != "todos") {
      List nuevas = [];
      for (var p in filtradas) {
        final id = p['id_persona'];

        bool agregar = false;

        if (filtro == "gestantes") {
          agregar = await personaTiene("chagas_gestantes", id);
        } else if (filtro == "bajo_control") {
          agregar = await personaTiene("chagas_bajo_control", id);
        } else if (filtro == "tratamiento") {
          agregar = await personaTiene("chagas_tratamiento", id);
        } else if (filtro == "agudo") {
          agregar = await personaTiene("chagas_agudo", id);
        }

        if (agregar) nuevas.add(p);
      }
      filtradas = nuevas;
    }

    // 🔽 ORDEN
    if (orden == "az") {
      filtradas.sort((a, b) =>
          a['nombre'].toString().compareTo(b['nombre'].toString()));
    } else if (orden == "za") {
      filtradas.sort((a, b) =>
          b['nombre'].toString().compareTo(a['nombre'].toString()));
    }
    // "recientes" no necesita lógica: ya viene ordenado desde Supabase.

    setState(() {
      personasFiltradas = filtradas;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pacientes Registrados"),
      ),

      // REFRESH (pull to refresh)
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: cargarPersonas,
              child: Column(
                children: [
                  // 🔍 BUSCADOR
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: "Buscar por nombre o RUT",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) {
                        busqueda = v;
                        aplicarFiltros();
                      },
                    ),
                  ),

                  // 🟣 FILTROS + ORDEN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: filtro,
                            decoration: const InputDecoration(
                              labelText: "Filtro",
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: "todos", child: Text("Todos")),
                              DropdownMenuItem(
                                  value: "gestantes", child: Text("Gestantes")),
                              DropdownMenuItem(
                                  value: "bajo_control",
                                  child: Text("Bajo Control")),
                              DropdownMenuItem(
                                  value: "tratamiento",
                                  child: Text("Tratamiento")),
                              DropdownMenuItem(
                                  value: "agudo",
                                  child: Text("Chagas Agudo")),
                            ],
                            onChanged: (v) {
                              filtro = v!;
                              aplicarFiltros();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: orden,
                            decoration: const InputDecoration(
                              labelText: "Ordenar",
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: "recientes",
                                  child: Text("Más recientes")),
                              DropdownMenuItem(
                                  value: "az", child: Text("A → Z")),
                              DropdownMenuItem(
                                  value: "za", child: Text("Z → A")),
                            ],
                            onChanged: (v) {
                              orden = v!;
                              aplicarFiltros();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // LISTA DE PACIENTES
                  Expanded(
                    child: personas.isEmpty && !cargando
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  "No se pudieron cargar los pacientes",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Verifica tu conexión a internet",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Reintentar"),
                                  onPressed: cargarPersonas,
                                ),
                              ],
                            ),
                          )
                        : personasFiltradas.isEmpty
                            ? const Center(child: Text("No se encontraron resultados"))
                            : ListView.builder(
                            itemCount: personasFiltradas.length,
                            itemBuilder: (context, index) {
                              final p = personasFiltradas[index];

                              return Card(
                                child: ListTile(
                                  title: Text(p['nombre']),
                                  subtitle: Text(p['rut'] ?? 'Sin RUT'),
                                  trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 18),
                                  onTap: () async {
                                    final resultado = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetallePersonaScreen(
                                            idPersona: p['id_persona']),
                                      ),
                                    );
                                    // Si se editó algo, refrescar la lista
                                    if (resultado == true) {
                                      await cargarPersonas();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
