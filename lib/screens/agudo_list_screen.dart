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

class AgudoListScreen extends StatefulWidget {
  const AgudoListScreen({super.key});

  @override
  State<AgudoListScreen> createState() => _AgudoListScreenState();
}

class _AgudoListScreenState extends State<AgudoListScreen> {
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

  PatientVisualStatus _statusAgudo(Map<String, dynamic> r) {
    final notif = parseClinicalDate(r['fecha_notificacion']);
    if (notif == null) return PatientVisualStatus.upToDate;
    final days = DateTime.now().difference(notif).inDays;
    if (days > 365) return PatientVisualStatus.upcoming;
    return PatientVisualStatus.upToDate;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Casos de Chagas agudo')),
      body: cargando
          ? const AppLoading(compact: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Mostrando ${filtrados.length} ${filtrados.length == 1 ? 'caso' : 'casos'}',
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
                          text: registros.isEmpty
                              ? 'No hay casos agudos registrados'
                              : 'Sin resultados',
                          subtitle: registros.isEmpty
                              ? 'Los casos aparecerán aquí al registrarlos.'
                              : 'Prueba otra búsqueda.',
                          icon: Icons.warning_amber_outlined,
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
                              final notif =
                                  r['fecha_notificacion']?.toString() ?? '—';
                              final folio = r['folio']?.toString();
                              final obs =
                                  (r['observacion']?.toString().trim() ?? '');
                              final ex = 'RN: ${r['ex_rn'] ?? '—'} · 2m: ${r['ex_2m'] ?? '—'} · 9m: ${r['ex_9m'] ?? '—'}';

                              return PatientListCard(
                                data: PatientCardData(
                                  name: nombre,
                                  rut: rut,
                                  location: dir.isEmpty ? null : dir,
                                  controlText:
                                      'Notificado: $notif${folio != null && folio.isNotEmpty ? ' · Folio $folio' : ''}',
                                  examText: obs.isEmpty
                                      ? (tel.isEmpty ? ex : 'Tel: $tel · $ex')
                                      : '$ex · Obs: ${obs.length > 40 ? '${obs.substring(0, 40)}…' : obs}',
                                  detailRowIcon: Icons.biotech_outlined,
                                  status: _statusAgudo(r),
                                  statusLabelOverride: _statusAgudo(r) ==
                                          PatientVisualStatus.upcoming
                                      ? 'Seguimiento'
                                      : null,
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
