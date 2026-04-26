import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_messages.dart';
import '../utils/toast.dart';
import '../widgets/form_actions_row.dart';
import '../widgets/save_button.dart';
import 'crear_persona_screen.dart';
import 'seleccionar_persona_screen.dart';

class CrearBajoControlScreen extends StatefulWidget {
  /// Si se pasa, se usa este paciente y no se muestra selector de persona (desde ficha).
  final int? initialIdPersona;
  final int? editId;

  const CrearBajoControlScreen({
    super.key,
    this.initialIdPersona,
    this.editId,
  });

  bool get isEdit => editId != null;

  @override
  State<CrearBajoControlScreen> createState() => _CrearBajoControlScreenState();
}

class _CrearBajoControlScreenState extends State<CrearBajoControlScreen> {
  int? idPersona;

  DateTime? fechaNotificacion;
  DateTime? fechaConfirmacion;
  DateTime? ultimoControl;
  DateTime? proximoControl;
  DateTime? fechaExamen;

  final folioCtrl = TextEditingController();
  final profesionalCtrl = TextEditingController();
  final interconsultasCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();
  final examenesPendientesCtrl = TextEditingController();

  bool guardando = false;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdPersona != null) idPersona = widget.initialIdPersona;
    if (widget.isEdit) _cargarRegistro();
  }

  Future<void> seleccionarFecha(
    DateTime? actual,
    void Function(DateTime?) setter,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setter(picked);
    setState(() {});
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
          .from('chagas_bajo_control')
          .select()
          .eq('id', widget.editId!)
          .single();
      setState(() {
        idPersona = row['id_persona'] as int?;
        folioCtrl.text = (row['folio'] ?? '').toString();
        profesionalCtrl.text = (row['profesional_notifica'] ?? '').toString();
        interconsultasCtrl.text = (row['interconsultas'] ?? '').toString();
        observacionesCtrl.text = (row['observaciones'] ?? '').toString();
        examenesPendientesCtrl.text =
            (row['examenes_pendientes'] ?? '').toString();

        DateTime? _p(String key) {
          final v = row[key]?.toString();
          if (v == null || v.isEmpty) return null;
          return DateTime.tryParse(v);
        }

        fechaNotificacion = _p('fecha_notificacion');
        fechaConfirmacion = _p('fecha_confirmacion');
        ultimoControl = _p('ultimo_control');
        proximoControl = _p('proximo_control');
        fechaExamen = _p('fecha_examen');

        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, AppMessages.errorCargar);
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

  Future<void> guardarBajoControl() async {
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
        'profesional_notifica':
            profesionalCtrl.text.isEmpty ? null : profesionalCtrl.text,
        'fecha_confirmacion': _formatearFecha(fechaConfirmacion),
        'ultimo_control': _formatearFecha(ultimoControl),
        'proximo_control': _formatearFecha(proximoControl),
        'interconsultas':
            interconsultasCtrl.text.isEmpty ? null : interconsultasCtrl.text,
        'observaciones':
            observacionesCtrl.text.isEmpty ? null : observacionesCtrl.text,
        'fecha_examen': _formatearFecha(fechaExamen),
        'examenes_pendientes': examenesPendientesCtrl.text.isEmpty
            ? null
            : examenesPendientesCtrl.text,
      };

      if (widget.isEdit) {
        await supabase
            .from('chagas_bajo_control')
            .update(data)
            .eq('id', widget.editId!);
      } else {
        await supabase.from('chagas_bajo_control').insert(data);
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
    profesionalCtrl.dispose();
    interconsultasCtrl.dispose();
    observacionesCtrl.dispose();
    examenesPendientesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personaLabel = idPersona == null
        ? "Sin persona seleccionada"
        : "Persona ID: $idPersona";

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isEdit ? "Editar Bajo control" : "Registrar Bajo Control"),
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
            TextField(
              controller: profesionalCtrl,
              decoration: const InputDecoration(
                labelText: "Profesional que notifica",
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
                onPressed: () =>
                    seleccionarFecha(fechaNotificacion, (f) {
                  fechaNotificacion = f;
                }),
              ),
            ),
            ListTile(
              title: const Text("Fecha confirmación"),
              subtitle: Text(
                fechaConfirmacion == null
                    ? "Seleccionar fecha"
                    : _formatearFecha(fechaConfirmacion!)!,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () =>
                    seleccionarFecha(fechaConfirmacion, (f) {
                  fechaConfirmacion = f;
                }),
              ),
            ),
            ListTile(
              title: const Text("Último control"),
              subtitle: Text(
                ultimoControl == null
                    ? "Seleccionar fecha"
                    : _formatearFecha(ultimoControl!)!,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => seleccionarFecha(ultimoControl, (f) {
                  ultimoControl = f;
                }),
              ),
            ),
            ListTile(
              title: const Text("Próximo control"),
              subtitle: Text(
                proximoControl == null
                    ? "Seleccionar fecha"
                    : _formatearFecha(proximoControl!)!,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => seleccionarFecha(proximoControl, (f) {
                  proximoControl = f;
                }),
              ),
            ),
            ListTile(
              title: const Text("Fecha examen"),
              subtitle: Text(
                fechaExamen == null
                    ? "Seleccionar fecha"
                    : _formatearFecha(fechaExamen!)!,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => seleccionarFecha(fechaExamen, (f) {
                  fechaExamen = f;
                }),
              ),
            ),
            TextField(
              controller: interconsultasCtrl,
              minLines: 1,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: "Interconsultas realizadas"),
            ),
            TextField(
              controller: observacionesCtrl,
              minLines: 1,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: "Observaciones"),
            ),
            TextField(
              controller: examenesPendientesCtrl,
              minLines: 1,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: "Exámenes pendientes"),
            ),
            const SizedBox(height: 20),
            SaveButton(
              onPressed: guardarBajoControl,
              loading: guardando,
              label: 'Guardar',
            ),
          ],
        ),
      ),
    );
  }
}
