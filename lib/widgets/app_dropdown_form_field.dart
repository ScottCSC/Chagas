import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dropdown de formulario con estilo web consistente (bordes 14, fondo claro).
class AppDropdownFormField<T> extends StatelessWidget {
  final String label;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final double menuMaxHeight;
  final String? hint;
  /// Texto de ayuda bajo el campo (p. ej. “Campo obligatorio”).
  final String? helperText;
  final Color? helperColor;
  /// Borde cuando el campo está habilitado y sin error de validación (p. ej. advertencia suave).
  final Color? enabledBorderColor;
  final double enabledBorderWidth;
  final Color? prefixIconColor;
  /// Color del label; si es null se usa el estilo por defecto.
  final Color? labelColor;
  final FontWeight labelWeight;

  const AppDropdownFormField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.items,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.menuMaxHeight = 320,
    this.hint,
    this.helperText,
    this.helperColor,
    this.enabledBorderColor,
    this.enabledBorderWidth = 1,
    this.prefixIconColor,
    this.labelColor,
    this.labelWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabledSide = enabledBorderColor ?? Colors.grey.shade300;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: enabledSide, width: enabledBorderWidth),
    );
    final iconColor = prefixIconColor ?? Colors.grey.shade600;
    final labelCol = labelColor ?? const Color(0xFF1B1B24);
    final helpColor = helperColor ?? Colors.grey.shade700;

    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      isExpanded: true,
      borderRadius: BorderRadius.circular(14),
      menuMaxHeight: menuMaxHeight,
      style: GoogleFonts.inter(
        fontSize: 16,
        color: const Color(0xFF1B1B24),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.35),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 22, color: iconColor),
        suffixIcon: suffixIcon,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: labelWeight,
          color: labelCol,
        ),
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: GoogleFonts.inter(
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: helpColor,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.grey.shade600,
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
