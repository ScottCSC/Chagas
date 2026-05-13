import 'package:flutter/material.dart';

import 'direccion_ubicacion_picker.dart';

/// Validador de correo: vacío OK; si no vacío debe tener @ y un . después.
String? validatorCorreo(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
  return ok ? null : 'Correo inválido';
}

/// Form reutilizable: dirección (OSM + GPS), teléfono y correo.
/// Datos de contacto / ubicación (flujo alta persona en operativos).
class ContactoUbicacionForm extends StatelessWidget {
  final TextEditingController direccionCtrl;
  final TextEditingController comunaCtrl;
  final TextEditingController provinciaCtrl;
  final TextEditingController telefonoCtrl;
  final TextEditingController emailCtrl;
  final double? latitud;
  final double? longitud;
  final void Function(double? lat, double? lng) onLatLngChanged;
  /// Título de la sección; si null no se muestra.
  final String? sectionTitle;
  /// Validador para el campo correo; si null no se valida.
  final String? Function(String?)? correoValidator;

  const ContactoUbicacionForm({
    super.key,
    required this.direccionCtrl,
    required this.comunaCtrl,
    required this.provinciaCtrl,
    required this.telefonoCtrl,
    required this.emailCtrl,
    required this.latitud,
    required this.longitud,
    required this.onLatLngChanged,
    this.sectionTitle = 'Contacto y ubicación',
    this.correoValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sectionTitle != null && sectionTitle!.isNotEmpty) ...[
          Text(
            sectionTitle!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
        ],
        DireccionUbicacionPicker(
          direccionCtrl: direccionCtrl,
          comunaCtrl: comunaCtrl,
          provinciaCtrl: provinciaCtrl,
          latitud: latitud,
          longitud: longitud,
          onLatLngChanged: onLatLngChanged,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: telefonoCtrl,
          decoration: const InputDecoration(labelText: 'Teléfono'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Correo',
            hintText: 'ejemplo@correo.cl',
          ),
          keyboardType: TextInputType.emailAddress,
          validator: correoValidator,
        ),
      ],
    );
  }
}
