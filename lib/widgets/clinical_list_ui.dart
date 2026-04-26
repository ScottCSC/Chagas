import 'package:flutter/material.dart';

/// Campo de búsqueda alineado al estilo de Ver pacientes.
class ClinicalSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const ClinicalSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar paciente (nombre o RUT)',
  });

  @override
  State<ClinicalSearchField> createState() => _ClinicalSearchFieldState();
}

class _ClinicalSearchFieldState extends State<ClinicalSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Chips de filtro (mismo estilo que Ver pacientes).
Widget clinicalFilterChip({
  required BuildContext context,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  const purple = Colors.deepPurple;
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      showCheckmark: true,
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: purple.withValues(alpha: 0.15),
      checkmarkColor: purple,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? purple : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide(
        color: selected ? purple.withValues(alpha: 0.35) : Colors.grey.shade300,
      ),
    ),
  );
}

/// Banner informativo (alertas / resumen).
class ClinicalListAlertBanner extends StatelessWidget {
  final String text;

  const ClinicalListAlertBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF6C00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
