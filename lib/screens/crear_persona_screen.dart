import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/confirm_dialog.dart';
import '../utils/rut_input_formatter.dart';
import '../utils/rut_utils.dart';
import '../utils/toast.dart';
import '../widgets/contacto_ubicacion_form.dart';
import '../widgets/save_button.dart';

class CrearPersonaScreen extends StatefulWidget {
  @override
  _CrearPersonaScreenState createState() => _CrearPersonaScreenState();
}

class _CrearPersonaScreenState extends State<CrearPersonaScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nombreCtrl = TextEditingController();
  TextEditingController rutCtrl = TextEditingController();
  TextEditingController edadCtrl = TextEditingController();
  TextEditingController direccionCtrl = TextEditingController();
  TextEditingController comunaCtrl = TextEditingController();
  TextEditingController provinciaCtrl = TextEditingController();
  TextEditingController telefonoCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();

  double? latitud;
  double? longitud;

  bool guardando = false;

  void guardarPersona() async {
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

    // Validar DV del RUT antes de guardar (validación adicional de seguridad)
    final rutClean = RutInputFormatter.clean(rutCtrl.text.trim());
    if (rutClean.isNotEmpty) {
      // Convertir a formato con guion para validar
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

    try {
      final res = await supabase
          .from('persona')
          .insert({
            'nombre': nombreCtrl.text.trim(),
            'rut': rutClean,
            'edad': int.tryParse(edadCtrl.text.trim()),
            'direccion': direccionCtrl.text.trim().isEmpty ? null : direccionCtrl.text.trim(),
            'comuna': comunaCtrl.text.trim().isEmpty ? null : comunaCtrl.text.trim(),
            'provincia': provinciaCtrl.text.trim().isEmpty ? null : provinciaCtrl.text.trim(),
            'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
            'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
            'latitud': latitud,
            'longitud': longitud,
          })
          .select()
          .single(); // devuelve una sola fila

      setState(() => guardando = false);

      // Puedes ver el id_persona si quieres:
      final idPersona = res['id_persona'];
      // print("Nueva persona id = $idPersona");

      // volvemos a la pantalla anterior devolviendo el id
      Navigator.pop(context, idPersona);
    } catch (e) {
      setState(() => guardando = false);
      showErr(context, "Error al guardar persona: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crear Persona")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: InputDecoration(labelText: "Nombre completo"),
                validator: (v) => v!.isEmpty ? "Ingrese nombre" : null,
              ),
              TextFormField(
                controller: rutCtrl,
                keyboardType: TextInputType.text, // IMPORTANTE: para permitir K
                inputFormatters: [
                  // Solo números y K
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9kK]')),
                  // Formateo + límite + K solo al final
                  RutInputFormatter(),
                ],
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "RUT",
                  hintText: '12.345.678-K',
                  helperText: 'Formato: 12.345.678-9',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Ingrese RUT";
                  final rutClean = RutInputFormatter.clean(v);
                  if (rutClean.length < 8 || rutClean.length > 9) {
                    return "RUT incompleto";
                  }
                  // Convertir a formato con guion para validar
                  final rutParaValidar = rutClean.length == 9 
                      ? '${rutClean.substring(0, 8)}-${rutClean.substring(8)}'
                      : v;
                  if (!RutUtils.esValido(rutParaValidar)) {
                    return "RUT inválido. Revisa el dígito verificador.";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: edadCtrl,
                decoration: InputDecoration(labelText: "Edad"),
                keyboardType: TextInputType.number,
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
                onLatLngChanged: (lat, lng) {
                  setState(() {
                    latitud = lat;
                    longitud = lng;
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
