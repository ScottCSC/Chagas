import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';

/// Colores y medidas alineados al frame de login en Figma (node 3346:927).
class _LoginTokens {
  static const Color bg = Color(0xFFFCF8FF);
  static const Color royalBlue = Color(0xFF493EE5);
  static const Color cta = Color(0xFF635BFF);
  static const Color gunPowder = Color(0xFF464555);
  static const Color shark = Color(0xFF1B1B24);
  static const Color paleSky = Color(0xFF6B7280);
  static const Color blueHaze = Color(0xFFC7C4D8);
  static const Color buttonLabel = Color(0xFFFCF8FF);

  static const double maxContentWidth = 448;
  static const double sectionGap = 31.5;
  static const double cardRadius = 12;
  static const double fieldRadius = 8;
  static const double cardPadding = 25;
  static const double formFieldGap = 24;
  static const double labelFieldGap = 8;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passFocus = FocusNode();

  bool cargando = false;
  bool obscurePass = true;

  @override
  void initState() {
    super.initState();
    emailFocus.addListener(_onFocusChanged);
    passFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  OutlineInputBorder _fieldBorder({required bool focused}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_LoginTokens.fieldRadius),
      borderSide: BorderSide(
        color: focused ? _LoginTokens.royalBlue : _LoginTokens.blueHaze,
        width: focused ? 1.5 : 1,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Widget prefix,
    required bool focused,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _LoginTokens.paleSky,
        height: 1.25,
      ),
      isDense: true,
      filled: true,
      fillColor: _LoginTokens.buttonLabel,
      contentPadding: const EdgeInsets.fromLTRB(0, 11, 9, 11),
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, maxHeight: 48),
      suffixIcon: suffix,
      border: _fieldBorder(focused: false),
      enabledBorder: _fieldBorder(focused: false),
      focusedBorder: _fieldBorder(focused: true),
      errorBorder: _fieldBorder(focused: false),
      focusedErrorBorder: _fieldBorder(focused: true),
    );
  }

  Future<void> _iniciarSesion() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
      showErr(context, 'Por favor ingresa correo y contraseña');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => cargando = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        showErr(context, 'Error al iniciar sesión: $e');
      }
    }
  }

  @override
  void dispose() {
    emailFocus.removeListener(_onFocusChanged);
    passFocus.removeListener(_onFocusChanged);
    emailCtrl.dispose();
    passCtrl.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _LoginTokens.bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 56,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _LoginTokens.maxContentWidth,
                        ),
                        child: AutofillGroup(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Chagas Tracker',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.publicSans(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      height: 38 / 30,
                                      letterSpacing: -0.6,
                                      color: _LoginTokens.royalBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Registro epidemiológico territorial',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      height: 28 / 18,
                                      color: _LoginTokens.gunPowder,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: textScale.scale(_LoginTokens.sectionGap)),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(_LoginTokens.cardRadius),
                                  border: Border.all(color: _LoginTokens.blueHaze),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      offset: const Offset(0, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    _LoginTokens.cardPadding,
                                    _LoginTokens.cardPadding,
                                    _LoginTokens.cardPadding,
                                    41,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Correo',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          height: 20 / 14,
                                          letterSpacing: 0.28,
                                          color: _LoginTokens.shark,
                                        ),
                                      ),
                                      const SizedBox(height: _LoginTokens.labelFieldGap),
                                      TextField(
                                        controller: emailCtrl,
                                        focusNode: emailFocus,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [AutofillHints.email],
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: _LoginTokens.shark,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: 'ejemplo@salud.gob.ar',
                                          focused: emailFocus.hasFocus,
                                          prefix: Padding(
                                            padding: const EdgeInsets.only(left: 8, right: 4),
                                            child: Icon(
                                              Icons.mail_outline_rounded,
                                              size: 24,
                                              color: _LoginTokens.paleSky,
                                            ),
                                          ),
                                        ),
                                        onSubmitted: (_) => passFocus.requestFocus(),
                                      ),
                                      const SizedBox(height: _LoginTokens.formFieldGap),
                                      Text(
                                        'Contraseña',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          height: 20 / 14,
                                          letterSpacing: 0.28,
                                          color: _LoginTokens.shark,
                                        ),
                                      ),
                                      const SizedBox(height: _LoginTokens.labelFieldGap),
                                      TextField(
                                        controller: passCtrl,
                                        focusNode: passFocus,
                                        obscureText: obscurePass,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [AutofillHints.password],
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: _LoginTokens.shark,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: '••••••••',
                                          focused: passFocus.hasFocus,
                                          prefix: Padding(
                                            padding: const EdgeInsets.only(left: 8, right: 4),
                                            child: Icon(
                                              Icons.lock_outline_rounded,
                                              size: 24,
                                              color: _LoginTokens.paleSky,
                                            ),
                                          ),
                                          suffix: IconButton(
                                            tooltip: obscurePass
                                                ? 'Mostrar contraseña'
                                                : 'Ocultar contraseña',
                                            onPressed: () =>
                                                setState(() => obscurePass = !obscurePass),
                                            icon: Icon(
                                              obscurePass
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              size: 22,
                                              color: _LoginTokens.paleSky,
                                            ),
                                          ),
                                        ),
                                        onSubmitted: (_) {
                                          if (!cargando) _iniciarSesion();
                                        },
                                      ),
                                      const SizedBox(height: _LoginTokens.formFieldGap),
                                      Semantics(
                                        button: true,
                                        label: 'Ingresar',
                                        child: Material(
                                          color: _LoginTokens.cta,
                                          borderRadius: BorderRadius.circular(_LoginTokens.fieldRadius),
                                          elevation: 0,
                                          shadowColor: Colors.black.withValues(alpha: 0.05),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(_LoginTokens.fieldRadius),
                                            onTap: cargando ? null : _iniciarSesion,
                                            child: Ink(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(_LoginTokens.fieldRadius),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.05),
                                                    offset: const Offset(0, 1),
                                                    blurRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: SizedBox(
                                                height: 52,
                                                child: Center(
                                                  child: cargando
                                                      ? const SizedBox(
                                                          width: 22,
                                                          height: 22,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2.2,
                                                            color: _LoginTokens.buttonLabel,
                                                          ),
                                                        )
                                                      : Text(
                                                          'Ingresar',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            height: 20 / 14,
                                                            letterSpacing: 0.28,
                                                            color: _LoginTokens.buttonLabel,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: textScale.scale(_LoginTokens.sectionGap)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 16,
                                    color: _LoginTokens.paleSky,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Acceso exclusivo para personal autorizado',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 20 / 14,
                                        color: _LoginTokens.gunPowder,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
