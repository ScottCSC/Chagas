import 'package:flutter/material.dart';

import '../utils/edad_util.dart';

/// Campo solo lectura + `showDatePicker` (sin tecleo libre de fecha).
class FechaNacimientoField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;
  final InputDecoration decoration;

  const FechaNacimientoField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.decoration = const InputDecoration(labelText: 'Fecha de nacimiento'),
  });

  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;
    final now = DateTime.now();
    final initial = value ?? DateTime(now.year - 25, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? DateTime(now.year - 18, now.month, now.day) : initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Seleccionar fecha de nacimiento',
    );
    if (d != null) {
      onChanged(DateTime(d.year, d.month, d.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _pick(context) : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: decoration.copyWith(
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            size: 20,
            color: enabled ? null : Theme.of(context).disabledColor,
          ),
        ),
        child: Text(
          value != null ? EdadUtil.formatoDiaMesAnio(value!) : 'Seleccione',
          style: TextStyle(
            fontSize: 16,
            color: value != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}
