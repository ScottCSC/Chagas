import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_messages.dart';
import '../utils/toast.dart';
import '../widgets/form_actions_row.dart';
import '../widgets/save_button.dart';
import 'crear_persona_screen.dart';
import 'seleccionar_persona_screen.dart';

class CrearInasistenteScreen extends StatefulWidget {
  final int? initialIdPersona;
  final int? editId; // modo edición

  const CrearInasistenteScreen({
    super.key,
    this.initialIdPersona,
    this.editId,
  });

  bool get isEdit => editId != null;

  @override
  State<CrearInasistenteScreen> createState() => _CrearInasistenteScreenState();
}

class _CrearInasistenteScreenState extends State<CrearInasistenteScreen> {
  int? idPersona;
  DateTime? fechaInasistencia;
  final tipoControlCtrl = TextEditingController();
  bool guardando = false;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdPersona != null) idPersona = widget.initialIdPersona;
    if (widget.isEdit) {
      _cargarRegistro();
    }
  }

  Future<void> seleccionarFechaInasistencia() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaInasistencia ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => fechaInasistencia = picked);
    }
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
          .from('chagas_inasistentes')
          .select()
          .eq('id', widget.editId!)
          .single();

      setState(() {
        idPersona = row['id_persona'] as int?;
        tipoControlCtrl.text = (row['tipo_control'] ?? '').toString();
        final f = row['fecha_inasistencia']?.toString();
        fechaInasistencia =
            f == null || f.isEmpty ? null : DateTime.tryParse(f);
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

  Future<void> guardarInasistente() async {
    if (idPersona == null || fechaInasistencia == null) {
      showErr(context, "Debe seleccionar persona y fecha de inasistencia");
      return;
    }

    setState(() => guardando = true);

    final supabase = Supabase.instance.client;

    try {
      final data = {
        'id_persona': idPersona,
        'fecha_inasistencia': _formatearFecha(fechaInasistencia),
        'tipo_control':
            tipoControlCtrl.text.isEmpty ? null : tipoControlCtrl.text,
      };

      if (widget.isEdit) {
        await supabase
            .from('chagas_inasistentes')
            .update(data)
            .eq('id', widget.editId!);
      } else {
        await supabase.from('chagas_inasistentes').insert(data);
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
    tipoControlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personaLabel = idPersona == null
        ? "Sin persona seleccionada"
        : "Persona ID: $idPersona";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Editar inasistencia" : "Registrar Inasistencia"),
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
                subtitle: const Text("Puede crear una nueva persona o seleccionar una existente"),
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
            ListTile(
              title: const Text("Fecha de inasistencia *"),
              subtitle: Text(
                fechaInasistencia == null
                    ? "Seleccionar fecha"
                    : _formatearFecha(fechaInasistencia!)!,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: seleccionarFechaInasistencia,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tipoControlCtrl,
              decoration: const InputDecoration(
                labelText: "Tipo de control (ej: control médico, control TENS)",
              ),
            ),
            const SizedBox(height: 20),
            SaveButton(
              onPressed: guardarInasistente,
              loading: guardando,
              label: 'Guardar',
            ),
          ],
        ),
      ),
    );
  }
}
