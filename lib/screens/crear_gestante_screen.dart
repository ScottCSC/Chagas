import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_messages.dart';
import '../utils/toast.dart';
import '../widgets/form_actions_row.dart';
import '../widgets/save_button.dart';
import 'crear_persona_screen.dart';
import 'seleccionar_persona_screen.dart';

class CrearGestanteScreen extends StatefulWidget {
  final int? initialIdPersona;
  final int? editId;

  const CrearGestanteScreen({
    super.key,
    this.initialIdPersona,
    this.editId,
  });

  bool get isEdit => editId != null;

  @override
  State<CrearGestanteScreen> createState() => _CrearGestanteScreenState();
}

class _CrearGestanteScreenState extends State<CrearGestanteScreen> {
  int? idPersona;
  DateTime? ingresoPrenatal;
  DateTime? partoAprox;

  bool guardando = false;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdPersona != null) idPersona = widget.initialIdPersona;
    if (widget.isEdit) _cargarRegistro();
  }

  Future<void> _cargarRegistro() async {
    if (widget.editId == null) return;
    setState(() => cargando = true);
    final supabase = Supabase.instance.client;
    try {
      final row = await supabase
          .from('chagas_gestantes')
          .select()
          .eq('id', widget.editId!)
          .single();
      setState(() {
        idPersona = row['id_persona'] as int?;
        final fIng = row['fecha_ingreso_prenatal']?.toString();
        final fPar = row['fecha_parto_aprox']?.toString();
        ingresoPrenatal =
            fIng == null || fIng.isEmpty ? null : DateTime.tryParse(fIng);
        partoAprox =
            fPar == null || fPar.isEmpty ? null : DateTime.tryParse(fPar);
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, AppMessages.errorCargar);
    }
  }

  void seleccionarFechaIngreso() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => ingresoPrenatal = picked);
  }

  void seleccionarFechaParto() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => partoAprox = picked);
  }

  void guardarGestante() async {
    if (idPersona == null || ingresoPrenatal == null) {
      showErr(context, "Faltan datos obligatorios");
      return;
    }

    setState(() => guardando = true);

    final supabase = Supabase.instance.client;

    try {
      final data = {
        'id_persona': idPersona,
        'fecha_ingreso_prenatal':
            ingresoPrenatal!.toIso8601String().split("T")[0],
        'fecha_parto_aprox': partoAprox?.toIso8601String().split("T")[0],
      };

      if (widget.isEdit) {
        await supabase
            .from('chagas_gestantes')
            .update(data)
            .eq('id', widget.editId!);
      } else {
        await supabase.from('chagas_gestantes').insert(data);
      }

      setState(() => guardando = false);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => guardando = false);
      showErr(context, AppMessages.errorGuardar);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Editar gestante" : "Registrar Gestante"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            if (widget.initialIdPersona != null)
              ListTile(
                title: Text('Paciente: ${widget.initialIdPersona}'),
                contentPadding: EdgeInsets.zero,
              )
            else ...[
              ListTile(
                title: Text(idPersona == null
                    ? "Sin persona seleccionada"
                    : "Persona ID: $idPersona"),
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

            ListTile(
              title: Text("Ingreso prenatal"),
              subtitle: Text(
                ingresoPrenatal == null
                    ? "Seleccionar fecha"
                    : ingresoPrenatal.toString().split(" ")[0],
              ),
              trailing: IconButton(
                icon: Icon(Icons.calendar_month),
                onPressed: seleccionarFechaIngreso,
              ),
            ),

            ListTile(
              title: Text("Parto aproximado"),
              subtitle: Text(
                partoAprox == null
                    ? "Seleccionar fecha"
                    : partoAprox.toString().split(" ")[0],
              ),
              trailing: IconButton(
                icon: Icon(Icons.calendar_month),
                onPressed: seleccionarFechaParto,
              ),
            ),

            const SizedBox(height: 20),
            SaveButton(
              onPressed: guardarGestante,
              loading: guardando,
              label: 'Guardar',
            )
          ],
        ),
      ),
    );
  }
}
