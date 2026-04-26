import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_messages.dart';
import '../utils/clinical_list_helpers.dart';
import '../utils/nav.dart';
import '../utils/rut_utils.dart';
import '../utils/toast.dart';
import '../widgets/clinical_list_ui.dart';
import '../widgets/patient_clinical_list_card.dart';
import '../widgets/states.dart';
import 'detalle_persona_screen.dart';

class GestantesListScreen extends StatefulWidget {
  const GestantesListScreen({super.key});

  @override
  State<GestantesListScreen> createState() => _GestantesListScreenState();
}

class _GestantesListScreenState extends State<GestantesListScreen> {
  List<dynamic> gestantes = [];
  bool cargando = true;
  final _qCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarGestantes();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
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

      if (mounted) {
        setState(() {
          gestantes = List<dynamic>.from(data as List);
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        showErr(context, AppMessages.errorCargar);
      }
    }
  }

  bool _pasaBusqueda(Map<String, dynamic> persona, String q) {
    if (q.isEmpty) return true;
    final nombre = (persona['nombre'] ?? '').toString().toLowerCase();
    final rut = (persona['rut'] ?? '').toString().toLowerCase();
    return nombre.contains(q) || rut.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final q = _qCtrl.text.trim().toLowerCase();
    final filtrados = gestantes.where((raw) {
      final g = Map<String, dynamic>.from(raw as Map);
      final persona = Map<String, dynamic>.from(g['persona'] ?? {});
      return _pasaBusqueda(persona, q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestantes registradas')),
      body: cargando
          ? const AppLoading(compact: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Mostrando ${filtrados.length} ${filtrados.length == 1 ? 'gestante' : 'gestantes'}',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClinicalSearchField(
                    controller: _qCtrl,
                    hintText: 'Buscar paciente (nombre o RUT)',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtrados.isEmpty
                      ? AppEmptyState(
                          text: gestantes.isEmpty
                              ? 'No hay gestantes registradas'
                              : 'Sin resultados',
                          subtitle: gestantes.isEmpty
                              ? 'Las gestantes aparecerán aquí al registrarlas.'
                              : 'Prueba otra búsqueda.',
                          icon: Icons.pregnant_woman_outlined,
                          useLottie: true,
                        )
                      : RefreshIndicator(
                          onRefresh: cargarGestantes,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final g =
                                  Map<String, dynamic>.from(filtrados[index] as Map);
                              final persona =
                                  Map<String, dynamic>.from(g['persona'] ?? {});
                              final id = persona['id_persona'];
                              final nombre =
                                  persona['nombre']?.toString() ?? 'Sin nombre';
                              final rutRaw = persona['rut']?.toString().trim() ?? '';
                              final rut = rutRaw.isEmpty
                                  ? null
                                  : RutUtils.formatearParaUI(rutRaw);
                              final dir =
                                  persona['direccion']?.toString().trim() ?? '';
                              final tel =
                                  persona['telefono']?.toString().trim() ?? '';
                              final ing =
                                  g['fecha_ingreso_prenatal']?.toString() ?? '—';
                              final parto =
                                  formatClinicalDay(parseClinicalDate(g['fecha_parto_aprox']));
                              final status =
                                  statusFromPartoAprox(g['fecha_parto_aprox']);

                              return PatientListCard(
                                data: PatientCardData(
                                  name: nombre,
                                  rut: rut,
                                  location: dir.isEmpty ? null : dir,
                                  controlText: 'Ingreso prenatal: $ing',
                                  examText:
                                      'Parto aprox.: $parto${tel.isEmpty ? '' : ' · Tel: $tel'}',
                                  detailRowIcon: Icons.child_care_outlined,
                                  status: status,
                                ),
                                onTap: id == null
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        pushFade(
                                          context,
                                          DetallePersonaScreen(
                                              idPersona: id as int),
                                        );
                                      },
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
