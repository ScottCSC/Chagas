import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';
import '../widgets/form_actions_row.dart';
import '../widgets/save_button.dart';
import 'crear_persona_screen.dart';
import 'seleccionar_persona_screen.dart';

class CrearTratamientoScreen extends StatefulWidget {
  final int? initialIdPersona;
  final int? editId;

  const CrearTratamientoScreen({
    super.key,
    this.initialIdPersona,
    this.editId,
  });

  bool get isEdit => editId != null;

  @override
  State<CrearTratamientoScreen> createState() => _CrearTratamientoScreenState();
}

class _CrearTratamientoScreenState extends State<CrearTratamientoScreen> {
  int? idPersona;

  DateTime? fechaInicio;

  final tratamientoCtrl = TextEditingController();
  final lugarCtrl = TextEditingController();
  final medicoCtrl = TextEditingController();
  final observacionCtrl = TextEditingController();

  bool guardando = false;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdPersona != null) idPersona = widget.initialIdPersona;
    if (widget.isEdit) _cargarRegistro();
  }

  Future<void> seleccionarFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => fechaInicio = picked);
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
          .from('chagas_tratamiento')
          .select()
          .eq('id', widget.editId!)
          .single();
      setState(() {
        idPersona = row['id_persona'] as int?;
        final fIni = row['fecha_inicio']?.toString();
        fechaInicio =
            fIni == null || fIni.isEmpty ? null : DateTime.tryParse(fIni);
        tratamientoCtrl.text =
            (row['nombre_tratamiento'] ?? '').toString();
        lugarCtrl.text = (row['lugar_tratamiento'] ?? '').toString();
        medicoCtrl.text = (row['medico_tratante'] ?? '').toString();
        observacionCtrl.text = (row['observacion'] ?? '').toString();
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, "Error cargando tratamiento: $e");
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

  Future<void> guardarTratamiento() async {
    if (idPersona == null || fechaInicio == null || tratamientoCtrl.text.isEmpty) {
      showErr(context, "Debe seleccionar persona, fecha inicio y nombre de tratamiento");
      return;
    }

    setState(() => guardando = true);

    final supabase = Supabase.instance.client;

    try {
      final data = {
        'id_persona': idPersona,
        'fecha_inicio': _formatearFecha(fechaInicio),
        'nombre_tratamiento': tratamientoCtrl.text,
        'lugar_tratamiento': lugarCtrl.text.isEmpty ? null : lugarCtrl.text,
        'medico_tratante': medicoCtrl.text.isEmpty ? null : medicoCtrl.text,
        'observacion':
            observacionCtrl.text.isEmpty ? null : observacionCtrl.text,
      };

      if (widget.isEdit) {
        await supabase
            .from('chagas_tratamiento')
            .update(data)
            .eq('id', widget.editId!);
      } else {
        await supabase.from('chagas_tratamiento').insert(data);
      }

      setState(() => guardando = false);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => guardando = false);
      showErr(context, "Error al guardar tratamiento: $e");
    }
  }

  @override
  void dispose() {
    tratamientoCtrl.dispose();
    lugarCtrl.dispose();
    medicoCtrl.dispose();
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
        title: Text(widget.isEdit ? "Editar Tratamiento" : "Registrar Tratamiento"),
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
              title: const Text("Fecha inicio *"),
              subtitle: Text(
                fechaInicio == null
                    ? "Seleccionar fecha"
                    : _formatearFecha(fechaInicio!)!,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: seleccionarFechaInicio,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tratamientoCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre del tratamiento *",
              ),
            ),
            TextField(
              controller: lugarCtrl,
              decoration: const InputDecoration(
                labelText: "Lugar del tratamiento",
              ),
            ),
            TextField(
              controller: medicoCtrl,
              decoration: const InputDecoration(
                labelText: "Médico tratante",
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
              onPressed: guardarTratamiento,
              loading: guardando,
              label: 'Guardar',
            ),
          ],
        ),
      ),
    );
  }
}
