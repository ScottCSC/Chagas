import 'package:flutter/material.dart';

/// Botón principal de guardar con altura fija y estado loading sin saltos de layout.
/// Duración corta (200ms) para el AnimatedSwitcher.
class SaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  const SaveButton({
    super.key,
    required this.onPressed,
    required this.loading,
    this.label = 'Guardar',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loading
              ? const SizedBox(
                  key: ValueKey(true),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label, key: const ValueKey(false)),
        ),
      ),
    );
  }
}
