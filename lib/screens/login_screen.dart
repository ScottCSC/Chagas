import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool cargando = false;

  Future<void> _iniciarSesion() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
      showErr(context, 'Por favor ingresa email y contraseña');
      return;
    }

    setState(() => cargando = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );
      // Si llega aquí, el login fue exitoso
      // El StreamBuilder en main.dart detectará el cambio y navegará a HomeScreen
    } catch (e) {
      setState(() => cargando = false);
      showErr(context, 'Error al iniciar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Chagas App",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),

              const SizedBox(height: 30),

              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: cargando ? null : _iniciarSesion,
                child: cargando
                    ? const CircularProgressIndicator()
                    : const Text("Ingresar"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}
