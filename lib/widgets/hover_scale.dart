import 'package:flutter/material.dart';

/// Efecto hover sutil para web/desktop: escala leve + sombra al pasar el cursor.
/// Respeta `MediaQuery.disableAnimations` (queda inmóvil si el usuario pidió
/// reducir animaciones por accesibilidad).
class HoverScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final double radius;

  const HoverScale({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.radius = 14,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final active = _hovering && !reduce;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (_hovering) setState(() => _hovering = false);
      },
      child: AnimatedScale(
        scale: active ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
