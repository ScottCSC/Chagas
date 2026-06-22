import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _SplashTokens {
  static const Color primary = Color(0xFF493EE5);
  static const Color bg = Color(0xFFFCF8FF);
  static const Color gradientTop = Color(0xFFF0EEFF);
  static const Color title = Color(0xFF1B1B24);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color track = Color(0xFFC7C4D8);
}

/// Pantalla de bienvenida animada que se muestra únicamente antes del login.
/// Tras la animación revela [nextScreen] sin navegación global, para no
/// interferir con la lógica de autenticación.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.nextScreen});

  /// Pantalla que se revela al terminar la animación (normalmente el login).
  final Widget nextScreen;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _exitController;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nameOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _progressOpacity;
  late final Animation<double> _exitOpacity;

  bool _terminado = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Fase 1 (0 → 400ms): ícono central.
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.333, curve: Curves.easeOutBack),
      ),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.333, curve: Curves.easeIn),
      ),
    );

    // Fase 2 (400 → 700ms): nombre.
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.333, 0.583, curve: Curves.easeOut),
      ),
    );
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.333, 0.583, curve: Curves.easeIn),
      ),
    );

    // Fase 3 (700 → 950ms): subtítulo.
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.583, 0.792, curve: Curves.easeIn),
      ),
    );

    // Fase 4 (950 → 1200ms): barra de progreso.
    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.792, 1.0, curve: Curves.easeIn),
      ),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarSecuencia());
  }

  Future<void> _iniciarSecuencia() async {
    final sinAnimaciones =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (sinAnimaciones) {
      if (mounted) setState(() => _terminado = true);
      return;
    }

    await _controller.forward();
    // Fase 5: mantener la barra visible hasta ~2200ms totales.
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    await _exitController.forward();
    if (!mounted) return;
    setState(() => _terminado = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_terminado) return widget.nextScreen;

    return Scaffold(
      backgroundColor: _SplashTokens.bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _exitController]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    _SplashTokens.gradientTop,
                    _SplashTokens.bg,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 48),
                      Opacity(
                        opacity: _iconOpacity.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: _iconScale.value,
                          child: const Icon(
                            Icons.monitor_heart_outlined,
                            size: 72,
                            color: _SplashTokens.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FractionalTranslation(
                        translation: _nameSlide.value,
                        child: Opacity(
                          opacity: _nameOpacity.value.clamp(0.0, 1.0),
                          child: Text(
                            'Chagas Tracker',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.publicSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _SplashTokens.title,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: _subtitleOpacity.value.clamp(0.0, 1.0),
                        child: Text(
                          'Registro epidemiológico territorial',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _SplashTokens.subtitle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Opacity(
                        opacity: _progressOpacity.value.clamp(0.0, 1.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: const SizedBox(
                              height: 3,
                              child: LinearProgressIndicator(
                                color: _SplashTokens.primary,
                                backgroundColor: _SplashTokens.track,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'v1.0',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _SplashTokens.track,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
