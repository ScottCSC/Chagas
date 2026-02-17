import 'package:flutter/material.dart';

enum StatusTone { success, warning, danger, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final bool outlined;
  final IconData? icon;
  final double? fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.outlined = true,
    this.icon,
    this.fontSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  Color _fg(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (tone) {
      case StatusTone.success:
        return Colors.green.shade700;
      case StatusTone.warning:
        return Colors.orange.shade700;
      case StatusTone.danger:
        return Colors.red.shade700;
      case StatusTone.neutral:
        return scheme.onSurface.withOpacity(0.75);
    }
  }

  Color _bg(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (tone) {
      case StatusTone.success:
        return Colors.green.shade50;
      case StatusTone.warning:
        return Colors.orange.shade50;
      case StatusTone.danger:
        return Colors.red.shade50;
      case StatusTone.neutral:
        return scheme.surfaceContainerHighest.withOpacity(0.6);
    }
  }

  Color _border(BuildContext context) => _fg(context).withOpacity(0.75);

  @override
  Widget build(BuildContext context) {
    final fg = _fg(context);
    final bg = _bg(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: outlined ? _border(context) : Colors.transparent),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize ?? 12.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
