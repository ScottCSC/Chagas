import 'package:flutter/material.dart';

import '../utils/sexo_paciente.dart';

/// Selector de sexo (F / M / NI). Sin entrada de texto.
class SexoSelectorField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final InputDecoration decoration;
  final String? Function(String?)? validator;

  const SexoSelectorField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.decoration = const InputDecoration(labelText: 'Sexo'),
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: _valorValido(value),
      decoration: decoration,
      hint: const Text('Seleccione'),
      isExpanded: true,
      items: SexoPaciente.itemsDropdown,
      onChanged: enabled ? (v) => onChanged(v) : null,
      validator: validator,
    );
  }

  /// Evita valor fuera de la lista (p. ej. datos antiguos en BD).
  static String? _valorValido(String? code) {
    if (code == null) return null;
    return SexoPaciente.etiquetaPorCodigo.containsKey(code) ? code : null;
  }
}
