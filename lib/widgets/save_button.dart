import 'package:flutter/material.dart';

/// Botón principal de guardar con altura fija y estado loading sin saltos de layout.
/// Duración corta (200ms) para el AnimatedSwitcher.
class SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final String? loadingLabel;
  final double? width;
  final double height;
  final IconData? icon;

  const SaveButton({
    super.key,
    required this.onPressed,
    required this.loading,
    this.label = 'Guardar',
    this.loadingLabel,
    this.width,
    this.height = 46,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = loading ? (loadingLabel ?? label) : label;
    final spinner = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );

    Widget child;
    if (icon != null) {
      child = ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading ? spinner : Icon(icon, size: 20),
        label: Text(displayLabel),
      );
    } else {
      child = ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loading
              ? spinner
              : Text(displayLabel, key: const ValueKey(false)),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: child,
    );
  }
}
