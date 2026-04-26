import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool cargando = false;
  String? _errorText;

  void _limpiarErrorAlEscribir() {
    if (_errorText != null && mounted) {
      setState(() => _errorText = null);
    }
  }

  /// Errores de red sin depender de `dart:io` (compatible con todas las plataformas).
  static bool _esErrorRed(Object e) {
    if (e is AuthUnknownException) {
      return _esErrorRed(e.originalError);
    }
    final s = e.toString().toLowerCase();
    if (s.contains('socketexception')) return true;
    if (s.contains('failed host lookup')) return true;
    if (s.contains('network is unreachable')) return true;
    if (s.contains('connection refused')) return true;
    if (s.contains('connection reset')) return true;
    if (s.contains('clientexception')) return true;
    if (s.contains('connection timed out')) return true;
    if (s.contains('handshakeexception')) return true;
    if (s.contains('networkerror')) return true;
    if (s.contains('no address associated with hostname')) return true;
    return false;
  }

  static String _mensajeLogin(Object e) {
    if (_esErrorRed(e)) {
      return 'Sin conexión a internet. Intente nuevamente.';
    }
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      final apiCode = (e.code ?? '').toLowerCase();
      if (apiCode == 'invalid_credentials' ||
          msg.contains('invalid login') ||
          msg.contains('invalid email or password') ||
          msg.contains('invalid credentials')) {
        return 'Correo o contraseña incorrectos';
      }
    }
    return 'No se pudo iniciar sesión en este momento';
  }

  Future<void> _iniciarSesion() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'Ingrese su correo');
      return;
    }
    if (passCtrl.text.isEmpty) {
      setState(() => _errorText = 'Ingrese su contraseña');
      return;
    }

    setState(() {
      _errorText = null;
      cargando = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: passCtrl.text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cargando = false;
        _errorText = _mensajeLogin(e);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    emailCtrl.addListener(_limpiarErrorAlEscribir);
    passCtrl.addListener(_limpiarErrorAlEscribir);
  }

  @override
  Widget build(BuildContext context) {
    final errColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Chagas App',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !cargando,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!cargando) _iniciarSesion();
                },
                enabled: !cargando,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: TextStyle(color: errColor, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: cargando ? null : _iniciarSesion,
                child: cargando
                    ? const CircularProgressIndicator()
                    : const Text('Ingresar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.removeListener(_limpiarErrorAlEscribir);
    passCtrl.removeListener(_limpiarErrorAlEscribir);
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}
