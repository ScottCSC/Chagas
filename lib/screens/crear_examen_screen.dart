import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';
import '../widgets/form_actions_row.dart';
import '../widgets/save_button.dart';
import 'crear_persona_screen.dart';
import 'seleccionar_persona_screen.dart';

class CrearExamenScreen extends StatefulWidget {
  final int? initialIdPersona;

  const CrearExamenScreen({super.key, this.initialIdPersona});

  @override
  State<CrearExamenScreen> createState() => _CrearExamenScreenState();
}

class _CrearExamenScreenState extends State<CrearExamenScreen> {
  int? idPersona;
  DateTime? fechaExamen;

  final tipoCtrl = TextEditingController();
  String resultadoSeleccionado = 'Pendiente';
  final laboratorioCtrl = TextEditingController();
  final observacionCtrl = TextEditingController();

  bool guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdPersona != null) idPersona = widget.initialIdPersona;
  }

  @override
  void dispose() {
    tipoCtrl.dispose();
    laboratorioCtrl.dispose();
    observacionCtrl.dispose();
    super.dispose();
  }

  String? _formatearFecha(DateTime? f) {
    if (f == null) return null;
    return f.toIso8601String().split("T")[0];
  }

  Future<void> seleccionarFechaExamen() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaExamen ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => fechaExamen = picked);
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

  Future<void> guardarExamen() async {
    if (idPersona == null || fechaExamen == null || tipoCtrl.text.isEmpty) {
      showErr(context, "Debe seleccionar persona, fecha del examen y tipo de examen");
      return;
    }

    setState(() => guardando = true);
    final supabase = Supabase.instance.client;

    try {
      final data = {
        'id_persona': idPersona,
        'fecha_examen': _formatearFecha(fechaExamen),
        'tipo_examen': tipoCtrl.text,
        'resultado': resultadoSeleccionado,
        'laboratorio':
            laboratorioCtrl.text.isEmpty ? null : laboratorioCtrl.text,
        'observacion':
            observacionCtrl.text.isEmpty ? null : observacionCtrl.text,
      };

      await supabase.from('examen_chagas').insert(data);

      setState(() => guardando = false);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => guardando = false);
      showErr(context, "Error al guardar examen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final personaLabel = idPersona == null
        ? "Sin persona seleccionada"
        : "Persona ID: $idPersona";

    return Scaffold(
      appBar: AppBar(title: const Text("Registrar examen")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Persona
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

            // Fecha examen
            ListTile(
              title: const Text("Fecha del examen *"),
              subtitle: Text(
                fechaExamen == null
                    ? "Seleccionar fecha"
                    : _formatearFecha(fechaExamen!)!,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: seleccionarFechaExamen,
              ),
            ),
            const SizedBox(height: 12),

            // Tipo de examen
            TextField(
              controller: tipoCtrl,
              decoration: const InputDecoration(
                labelText: "Tipo de examen * (Ej: ELISA, PCR, IFI)",
              ),
            ),
            const SizedBox(height: 12),

            // Resultado (selector rápido)
            const Text("Resultado"),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: resultadoSeleccionado,
              items: const [
                DropdownMenuItem(
                  value: 'Pendiente',
                  child: Text('Pendiente'),
                ),
                DropdownMenuItem(
                  value: 'Positivo',
                  child: Text('Positivo'),
                ),
                DropdownMenuItem(
                  value: 'Negativo',
                  child: Text('Negativo'),
                ),
                DropdownMenuItem(
                  value: 'Indeterminado',
                  child: Text('Indeterminado'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => resultadoSeleccionado = val);
                }
              },
            ),
            const SizedBox(height: 12),

            // Laboratorio
            TextField(
              controller: laboratorioCtrl,
              decoration: const InputDecoration(
                labelText: "Laboratorio / Centro (opcional)",
              ),
            ),

            // Observación
            TextField(
              controller: observacionCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Observación (opcional)",
              ),
            ),

            const SizedBox(height: 20),
            SaveButton(
              onPressed: guardarExamen,
              loading: guardando,
              label: 'Guardar examen',
            ),
          ],
        ),
      ),
    );
  }
}
