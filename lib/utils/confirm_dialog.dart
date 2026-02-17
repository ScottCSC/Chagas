import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Muestra un diálogo de confirmación genérico.
/// Útil antes de acciones destructivas (quitar de grupo, eliminar, etc.).
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String cancelText = 'Cancelar',
  String confirmText = 'Confirmar',
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, true);
          },
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return res ?? false;
}
