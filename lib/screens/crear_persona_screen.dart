import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_messages.dart';
import '../utils/confirm_dialog.dart';
import '../utils/edad_util.dart';
import '../utils/persona_sexo_guardado.dart';
import '../utils/rut_input_formatter.dart';
import '../utils/rut_utils.dart';
import '../utils/sexo_paciente.dart';
import '../utils/toast.dart';
import '../models/selected_location.dart';
import '../widgets/contacto_ubicacion_form.dart';
import '../widgets/fecha_nacimiento_field.dart';
import '../widgets/save_button.dart';
import '../widgets/sexo_selector_field.dart';

class CrearPersonaScreen extends StatefulWidget {
  @override
  _CrearPersonaScreenState createState() => _CrearPersonaScreenState();
}

class _CrearPersonaScreenState extends State<CrearPersonaScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nombreCtrl = TextEditingController();
  TextEditingController apellidoCtrl = TextEditingController();
  TextEditingController rutCtrl = TextEditingController();
  DateTime? fechaNacimiento;
  bool _errorFechaRequerida = false;
  String? sexoCodigo;
  TextEditingController direccionCtrl = TextEditingController();
  TextEditingController comunaCtrl = TextEditingController();
  TextEditingController provinciaCtrl = TextEditingController();
  TextEditingController telefonoCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();

  double? latitud;
  double? longitud;

  bool guardando = false;

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    rutCtrl.dispose();
    direccionCtrl.dispose();
    comunaCtrl.dispose();
    provinciaCtrl.dispose();
    telefonoCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  void guardarPersona() async {
    if (fechaNacimiento == null) {
      setState(() => _errorFechaRequerida = true);
      showErr(context, 'Seleccione la fecha de nacimiento');
      return;
    }
    setState(() => _errorFechaRequerida = false);

    if (!_formKey.currentState!.validate()) return;

    final dirVacia = direccionCtrl.text.trim().isEmpty;
    final sinUbicacion = latitud == null || longitud == null;

    String message;
    if (sinUbicacion && dirVacia) {
      message = 'Se guardará sin dirección ni ubicación. ¿Continuar?';
    } else if (sinUbicacion) {
      message = 'Se guardará la dirección sin ubicación confirmada.';
    } else {
      message = 'Se guardará la dirección y la ubicación confirmada.';
    }

    final ok = await confirm(
      context,
      title: 'Confirmar guardado',
      message: message,
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );
    if (!ok) return;

    setState(() => guardando = true);

    final rutClean = RutInputFormatter.clean(rutCtrl.text.trim());
    if (rutClean.isNotEmpty) {
      final rutParaValidar = rutClean.length == 9
          ? '${rutClean.substring(0, 8)}-${rutClean.substring(8)}'
          : rutCtrl.text.trim();
      if (!RutUtils.esValido(rutParaValidar)) {
        setState(() => guardando = false);
        if (!mounted) return;
        showErr(context, 'RUT inválido. Revisa el dígito verificador.');
        return;
      }
    }

    final supabase = Supabase.instance.client;
    final sexoVal = SexoPaciente.codigoParaPayload(sexoCodigo);
    debugLogSexoEnPayload('crear insert', sexoVal);

    try {
      final res = await supabase
          .from('persona')
          .insert({
            'nombre': nombreCtrl.text.trim(),
            'apellido': apellidoCtrl.text.trim().isEmpty ? null : apellidoCtrl.text.trim(),
            'rut': rutClean,
            'fecha_nacimiento': EdadUtil.aIsoFecha(fechaNacimiento),
            'edad': EdadUtil.calcularEdad(fechaNacimiento!),
            'sexo': sexoVal,
            'direccion': direccionCtrl.text.trim().isEmpty ? null : direccionCtrl.text.trim(),
            'comuna': comunaCtrl.text.trim().isEmpty ? null : comunaCtrl.text.trim(),
            'provincia': provinciaCtrl.text.trim().isEmpty ? null : provinciaCtrl.text.trim(),
            'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
            'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
            'latitud': latitud,
            'longitud': longitud,
          })
          .select()
          .single();

      setState(() => guardando = false);

      final idPersona = res['id_persona'];
      Navigator.pop(context, idPersona);
    } catch (e) {
      setState(() => guardando = false);
      final sexoTry = SexoPaciente.codigoParaPayload(sexoCodigo);
      debugLogErrorPersonaSexo(
        'crear',
        e,
        sexoIntentado: sexoTry,
        payloadParcial: {'sexo': sexoTry},
      );
      if (!mounted) return;
      final extra = sufijoSnackbarSiFalloEnumSexo(e, sexoIntentado: sexoTry);
      showErr(context, '${AppMessages.errorGuardar}${extra ?? ''}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Persona')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingrese nombre' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: apellidoCtrl,
                      decoration: const InputDecoration(labelText: 'Apellido *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingrese apellido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rutCtrl,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
                  RutInputFormatter(),
                ],
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'RUT *',
                  hintText: '12.345.678-K',
                  helperText: 'Formato: 12.345.678-9',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese RUT';
                  final rutClean = RutInputFormatter.clean(v);
                  if (rutClean.length < 8 || rutClean.length > 9) {
                    return 'RUT incompleto';
                  }
                  final rutParaValidar = rutClean.length == 9
                      ? '${rutClean.substring(0, 8)}-${rutClean.substring(8)}'
                      : v;
                  if (!RutUtils.esValido(rutParaValidar)) {
                    return 'RUT inválido. Revisa el dígito verificador.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FechaNacimientoField(
                      value: fechaNacimiento,
                      onChanged: (d) => setState(() {
                        fechaNacimiento = d;
                        _errorFechaRequerida = false;
                      }),
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento *',
                        errorText: _errorFechaRequerida ? 'Seleccione la fecha' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SexoSelectorField(
                      value: sexoCodigo,
                      decoration: const InputDecoration(labelText: 'Sexo'),
                      onChanged: (v) => setState(() => sexoCodigo = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Edad',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  fechaNacimiento != null
                      ? '${EdadUtil.calcularEdad(fechaNacimiento!)} años'
                      : '—',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ContactoUbicacionForm(
                direccionCtrl: direccionCtrl,
                comunaCtrl: comunaCtrl,
                provinciaCtrl: provinciaCtrl,
                telefonoCtrl: telefonoCtrl,
                emailCtrl: emailCtrl,
                latitud: latitud,
                longitud: longitud,
                onLocationChanged: (SelectedLocation loc) {
                  setState(() {
                    direccionCtrl.text = loc.address;
                    comunaCtrl.text = loc.comuna ?? '';
                    provinciaCtrl.text = loc.provincia ?? '';
                    latitud = loc.latitude;
                    longitud = loc.longitude;
                  });
                },
                sectionTitle: 'Contacto y ubicación',
                correoValidator: validatorCorreo,
              ),
              const SizedBox(height: 16),
              SaveButton(
                onPressed: guardarPersona,
                loading: guardando,
                label: 'Guardar',
              )
            ],
          ),
        ),
      ),
    );
  }
}
