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

class BajoControlListScreen extends StatefulWidget {
  const BajoControlListScreen({super.key});

  @override
  State<BajoControlListScreen> createState() => _BajoControlListScreenState();
}

class _BajoControlListScreenState extends State<BajoControlListScreen> {
  bool cargando = true;
  List<dynamic> registros = [];
  final _qCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarRegistros();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
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

      if (mounted) {
        setState(() {
          registros = List<dynamic>.from(data as List);
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
    final filtrados = registros.where((raw) {
      final r = Map<String, dynamic>.from(raw as Map);
      final persona = Map<String, dynamic>.from(r['persona'] ?? {});
      return _pasaBusqueda(persona, q);
    }).toList();

    final vencidos = filtrados.where((raw) {
      final r = Map<String, dynamic>.from(raw as Map);
      return statusFromProximoControl(r['proximo_control']) ==
          PatientVisualStatus.overdue;
    }).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Pacientes bajo control')),
      body: cargando
          ? const AppLoading(compact: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Mostrando ${filtrados.length} ${filtrados.length == 1 ? 'paciente' : 'pacientes'}',
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
                ClinicalListAlertBanner(
                  text: vencidos <= 0
                      ? ''
                      : '$vencidos ${vencidos == 1 ? 'paciente con' : 'pacientes con'} próximo control vencido',
                ),
                Expanded(
                  child: filtrados.isEmpty
                      ? AppEmptyState(
                          text: registros.isEmpty
                              ? 'No hay registros bajo control'
                              : 'Sin resultados',
                          subtitle: registros.isEmpty
                              ? 'Los casos aparecerán aquí al registrarlos.'
                              : 'Prueba otra búsqueda.',
                          icon: Icons.monitor_heart_outlined,
                          useLottie: true,
                        )
                      : RefreshIndicator(
                          onRefresh: cargarRegistros,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final r =
                                  Map<String, dynamic>.from(filtrados[index] as Map);
                              final persona =
                                  Map<String, dynamic>.from(r['persona'] ?? {});
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

                              final ult = formatClinicalDay(
                                  parseClinicalDate(r['ultimo_control']));
                              final prox = formatClinicalDay(
                                  parseClinicalDate(r['proximo_control']));
                              final status =
                                  statusFromProximoControl(r['proximo_control']);

                              final notif =
                                  r['fecha_notificacion']?.toString() ?? '—';

                              return PatientListCard(
                                data: PatientCardData(
                                  name: nombre,
                                  rut: rut,
                                  location: dir.isEmpty ? null : dir,
                                  controlText:
                                      'Últ. control: $ult · Próx.: $prox',
                                  examText: tel.isEmpty
                                      ? 'Notificado: $notif'
                                      : 'Tel: $tel · Notif.: $notif',
                                  detailRowIcon: Icons.phone_outlined,
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
