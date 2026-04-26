import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Rutas de animaciones (mantener pocas, tono clínico / sobrio).
abstract final class AppLottieAssets {
  static const String loading = 'assets/lottie/loading.json';
  static const String empty = 'assets/lottie/empty.json';
}

/// Carga global: Lottie discreto o fallback a [CircularProgressIndicator].
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.compact = false,
    this.useLottie = true,
  });

  /// Menos altura (p. ej. bloque KPI en Home).
  final bool compact;

  /// Si es false, solo spinner (útil si falla el asset en tests).
  final bool useLottie;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final h = compact ? 72.0 : 120.0;

    if (!useLottie) {
      return Center(
        child: SizedBox(
          width: compact ? 28 : 36,
          height: compact ? 28 : 36,
          child: CircularProgressIndicator(
            strokeWidth: compact ? 2.5 : 3,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Center(
      child: Semantics(
        label: 'Cargando',
        child: Lottie.asset(
          AppLottieAssets.loading,
          height: h,
          fit: BoxFit.contain,
          repeat: true,
          frameRate: FrameRate.max,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: compact ? 32 : 40,
              height: compact ? 32 : 40,
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          },
        ),
      ),
    );
  }
}

/// Lista o sección sin datos: mensaje claro; Lottie opcional y muy contenido.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.text,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
    this.useLottie = false,
  });

  final String text;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  /// Si hay `assets/lottie/empty.json` válido, muestra animación sutil encima del texto.
  final bool useLottie;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useLottie)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Lottie.asset(
                  AppLottieAssets.empty,
                  height: 100,
                  fit: BoxFit.contain,
                  repeat: false,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    icon,
                    size: 56,
                    color: cs.outline,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 52,
                color: cs.outline,
              ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionText ?? 'Acción'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error de red o servidor: mensaje + reintento opcional.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.title = 'No se pudo cargar',
    this.onRetry,
    this.retryText = 'Reintentar',
    this.icon = Icons.cloud_off_outlined,
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;
  final String retryText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(retryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
