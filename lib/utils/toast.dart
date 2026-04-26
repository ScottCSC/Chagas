import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Duration _kSnackOk = Duration(seconds: 3);
const Duration _kSnackErr = Duration(seconds: 4);

void showOk(BuildContext context, String msg) {
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: _kSnackOk,
    ),
  );
}

void showErr(BuildContext context, String msg) {
  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade800,
      duration: _kSnackErr,
    ),
  );
}

/// Error con acción (p. ej. Reintentar).
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
      backgroundColor: Colors.red.shade800,
      duration: _kSnackErr,
      action: SnackBarAction(
        label: actionLabel,
        textColor: Colors.white,
        onPressed: onAction,
      ),
    ),
  );
}
