import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showOk(BuildContext context, String msg) {
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );
}

void showErr(BuildContext context, String msg) {
  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red,
    ),
  );
}

/// Error con acción (ej. Reintentar).
void showErrWithAction(
  BuildContext context,
  String msg, {
  required String actionLabel,
  required VoidCallback onAction,
}) {
  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: actionLabel,
        textColor: Colors.white,
        onPressed: onAction,
      ),
    ),
  );
}
