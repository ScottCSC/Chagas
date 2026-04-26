import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_messages.dart';
import '../utils/toast.dart';
import '../widgets/form_actions_row.dart';
import '../widgets/save_button.dart';
import 'crear_persona_screen.dart';
import 'seleccionar_persona_screen.dart';

class CrearAgudoScreen extends StatefulWidget {
  final int? initialIdPersona;
  final int? editId;

  const CrearAgudoScreen({
    super.key,
    this.initialIdPersona,
    this.editId,
  });

  bool get isEdit => editId != null;

  @override
  State<CrearAgudoScreen> createState() => _CrearAgudoScreenState();
}

class _CrearAgudoScreenState extends State<CrearAgudoScreen> {
  int? idPersona;

  DateTime? fechaNotificacion;

  final folioCtrl = TextEditingController();
  final exRnCtrl = TextEditingController();
  final ex2mCtrl = TextEditingController();
  final ex9mCtrl = TextEditingController();
  final observacionCtrl = TextEditingController();

  bool guardando = false;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdPersona != null) idPersona = widget.initialIdPersona;
    if (widget.isEdit) _cargarRegistro();
  }

  String? _formatearFecha(DateTime? f) {
    if (f == null) return null;
    return f.toIso8601String().split("T")[0];
  }

  Future<void> _cargarRegistro() async {
    if (widget.editId == null) return;
    setState(() => cargando = true);
    final supabase = Supabase.instance.client;
    try {
      final row = await supabase
          .from('chagas_agudo')
          .select()
          .eq('id', widget.editId!)
          .single();
      setState(() {
        idPersona = row['id_persona'] as int?;
        folioCtrl.text = (row['folio'] ?? '').toString();
        final fNot = row['fecha_notificacion']?.toString();
        fechaNotificacion =
            fNot == null || fNot.isEmpty ? null : DateTime.tryParse(fNot);
        exRnCtrl.text = (row['ex_rn'] ?? '').toString();
        ex2mCtrl.text = (row['ex_2m'] ?? '').toString();
        ex9mCtrl.text = (row['ex_9m'] ?? '').toString();
        observacionCtrl.text = (row['observacion'] ?? '').toString();
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, AppMessages.errorCargar);
    }
  }

  Future<void> seleccionarFechaNotificacion() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaNotificacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => fechaNotificacion = picked);
    }
  }

  void crearNuevaPersona() async {
    final nuevoId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CrearPersonaScreen()),
    );

    if (nuevoId != null) {
      setState(() => idPersona = int.parse(nuevoId.toString()));
    }
  }

  void seleccionarPersonaExistente() async {
    final seleccionadoId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SeleccionarPersonaScreen()),
    );

    if (seleccionadoId != null) {
      setState(() => idPersona = int.parse(seleccionadoId.toString()));
    }
  }

  Future<void> guardarAgudo() async {
    if (idPersona == null || fechaNotificacion == null) {
      showErr(context, "Debe seleccionar persona y fecha de notificación");
      return;
    }

    setState(() => guardando = true);
    final supabase = Supabase.instance.client;

    try {
      final data = {
        'id_persona': idPersona,
        'folio': folioCtrl.text.isEmpty ? null : folioCtrl.text,
        'fecha_notificacion': _formatearFecha(fechaNotificacion),
        'ex_rn': exRnCtrl.text.isEmpty ? null : exRnCtrl.text,
        'ex_2m': ex2mCtrl.text.isEmpty ? null : ex2mCtrl.text,
        'ex_9m': ex9mCtrl.text.isEmpty ? null : ex9mCtrl.text,
        'observacion':
            observacionCtrl.text.isEmpty ? null : observacionCtrl.text,
      };

      if (widget.isEdit) {
        await supabase
            .from('chagas_agudo')
            .update(data)
            .eq('id', widget.editId!);
      } else {
        await supabase.from('chagas_agudo').insert(data);
      }
      setState(() => guardando = false);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => guardando = false);
      showErr(context, AppMessages.errorGuardar);
    }
  }

  @override
  void dispose() {
    folioCtrl.dispose();
    exRnCtrl.dispose();
    ex2mCtrl.dispose();
    ex9mCtrl.dispose();
    observacionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personaLabel = idPersona == null
        ? "Sin persona seleccionada"
        : "Persona ID: $idPersona";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Editar Chagas agudo" : "Registrar Chagas Agudo"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (widget.initialIdPersona != null)
              ListTile(
                title: Text('Paciente: ${widget.initialIdPersona}'),
                contentPadding: EdgeInsets.zero,
              )
            else ...[
              ListTile(
                title: Text(personaLabel),
                subtitle: const Text(
                    "Puede crear una nueva persona o seleccionar una existente"),
              ),
              FormActionsRow(
                leftText: 'Crear persona',
                rightText: 'Seleccionar existente',
                onLeft: crearNuevaPersona,
                onRight: seleccionarPersonaExistente,
                primaryOnLeft: true,
              ),
            ],
            const Divider(),
            TextField(
              controller: folioCtrl,
              decoration: const InputDecoration(
                labelText: "Folio",
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text("Fecha notificación *"),
              subtitle: Text(
                fechaNotificacion == null
                    ? "Seleccionar fecha"
                    : _formatearFecha(fechaNotificacion!)!,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: seleccionarFechaNotificacion,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: exRnCtrl,
              decoration: const InputDecoration(
                labelText: "Ex RN (resultado / comentario)",
              ),
            ),
            TextField(
              controller: ex2mCtrl,
              decoration: const InputDecoration(
                labelText: "Ex 2 meses",
              ),
            ),
            TextField(
              controller: ex9mCtrl,
              decoration: const InputDecoration(
                labelText: "Ex 9 meses",
              ),
            ),
            TextField(
              controller: observacionCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Observación",
              ),
            ),
            const SizedBox(height: 20),
            SaveButton(
              onPressed: guardarAgudo,
              loading: guardando,
              label: 'Guardar',
            ),
          ],
        ),
      ),
    );
  }
}
