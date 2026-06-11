import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Transición tipo Material Shared Axis (horizontal). Recomendado para ficha/detalle.
Future<T?> pushSharedAxis<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    ),
  );
}
