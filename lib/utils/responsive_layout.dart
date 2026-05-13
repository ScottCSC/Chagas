import 'package:flutter/material.dart';

/// Umbral para layout tipo panel web (NavigationRail, grillas).
const double kDesktopBreakpoint = 900;

/// Ancho máximo recomendado para contenido principal en escritorio.
const double kContentMaxWidth = 1180;

/// Ancho máximo para formularios centrados en escritorio.
const double kFormMaxWidth = 900;

/// Ancho máximo para tarjetas CTA destacadas en escritorio.
const double kCtaMaxWidth = 520;

/// Ancho fijo aproximado para tarjetas KPI en grillas de escritorio.
const double kKpiCardWidth = 260;

bool isDesktopWidth(double width) => width >= kDesktopBreakpoint;

/// Centra el hijo y limita el ancho en pantallas anchas.
Widget responsiveContentShell({
  required Widget child,
  double maxWidth = kContentMaxWidth,
}) {
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
