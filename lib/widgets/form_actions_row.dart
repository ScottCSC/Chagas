import 'package:flutter/material.dart';

/// Fila de acciones principales en formularios (patrón Cancelar/Guardar).
///
/// Convención: [leftText] = Outlined, [rightText] = Elevated.
/// Si [primaryOnLeft] es true, se invierte (izq = Elevated, der = Outlined).
/// Ver docs/CONVENCION_UI.md.
class FormActionsRow extends StatelessWidget {
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final String leftText;
  final String rightText;
  /// true = botón principal (Elevated) a la izquierda; false = a la derecha (default).
  final bool primaryOnLeft;

  const FormActionsRow({
    super.key,
    required this.leftText,
    required this.rightText,
    this.onLeft,
    this.onRight,
    this.primaryOnLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    final left = primaryOnLeft
        ? ElevatedButton(onPressed: onLeft, child: Text(leftText))
        : OutlinedButton(onPressed: onLeft, child: Text(leftText));
    final right = primaryOnLeft
        ? OutlinedButton(onPressed: onRight, child: Text(rightText))
        : ElevatedButton(onPressed: onRight, child: Text(rightText));
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}
