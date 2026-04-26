import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _sb = Supabase.instance.client;

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool _cargando = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final row = await _sb.from('profiles').select('role').eq('id', user.id).maybeSingle();
      if (!mounted) return;
      setState(() {
        _role = row?['role']?.toString();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _logout() async {
    await _sb.auth.signOut();
    if (!mounted) return;
    // El StreamBuilder en main.dart muestra LoginScreen al quedar sin sesión
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _sb.auth.currentUser;

    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              child: Text(
                (user?.email ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(user?.email ?? 'Sin sesión'),
                subtitle: Text(
                  _role == null
                      ? 'Rol: —'
                      : (_role == 'admin'
                          ? 'Rol: administrador'
                          : 'Rol: ${_role!}'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre (opcional)'),
              enabled: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoCtrl,
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
              keyboardType: TextInputType.phone,
              enabled: false,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
