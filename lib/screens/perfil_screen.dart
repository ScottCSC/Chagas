import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Coincide con `pubspec.yaml` → version (sin dependencia package_info).
const String _kAppVersionLabel = '1.0.0+1';

/// Tokens alineados con Home / Login / Ver.
class _PerfilTokens {
  static const Color bg = Color(0xFFFCF8FF);
  static const Color royalBlue = Color(0xFF493EE5);
  static const Color shark = Color(0xFF1B1B24);
  static const Color gunPowder = Color(0xFF464555);
  static const Color blueHaze = Color(0xFFC7C4D8);
  static const Color paleSky = Color(0xFF6B7280);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color privacyFill = Color(0xFFF5F2FF);
}

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _sb = Supabase.instance.client;

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
      if (mounted) setState(() => _cargando = false);
      return;
    }

    try {
      final row = await _sb
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _role = row?['role']?.toString();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  static String _nombreMostrado(User? user) {
    if (user == null) return 'Usuario autenticado';
    final meta = user.userMetadata;
    if (meta != null) {
      for (final key in ['full_name', 'name', 'display_name']) {
        final v = meta[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) return email;
    return 'Usuario autenticado';
  }

  static String _inicialAvatar(User? user) {
    final s = _nombreMostrado(user);
    if (s.isEmpty) return 'U';
    return s.substring(0, 1).toUpperCase();
  }

  static String _rolEtiqueta(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final r = raw.toLowerCase().trim();
    if (r.contains('admin')) return 'Administrador';
    if (r.contains('supervisor')) return 'Supervisor';
    if (r.contains('tens') || r == 'operator' || r.contains('operador')) {
      return 'TENS';
    }
    return raw;
  }

  Future<void> _confirmarYCerrarSesion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _ConfirmLogoutDialog(),
    );
    if (ok != true || !mounted) return;
    await _sb.auth.signOut();
    if (!mounted) return;
    // main.dart: StreamBuilder muestra LoginScreen sin sesión
  }

  void _mostrarAcercaDe() {
    showAboutDialog(
      context: context,
      applicationName: 'Chagas Tracker',
      applicationVersion: _kAppVersionLabel,
      applicationIcon: Icon(Icons.monitor_heart_rounded,
          size: 40, color: _PerfilTokens.royalBlue),
      children: [
        Text(
          'Aplicación para registro epidemiológico anónimo de casos de Chagas '
          'en Monte Patria. Enfoque territorial, sin datos clínicos identificables.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.45),
        ),
      ],
    );
  }

  void _mostrarBuenasPracticas() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Buenas prácticas de registro',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Text(
            '• Registre solo datos epidemiológicos y territoriales.\n'
            '• No ingrese nombres, RUT, teléfonos ni direcciones exactas.\n'
            '• Use el sector territorial y el estado del caso con claridad.\n'
            '• Las observaciones deben ser generales, sin identificar personas.',
            style: GoogleFonts.inter(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _sb.auth.currentUser;

    return Scaffold(
      backgroundColor: _PerfilTokens.bg,
      appBar: AppBar(
        backgroundColor: _PerfilTokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Perfil',
          style: GoogleFonts.publicSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _PerfilTokens.royalBlue,
          ),
        ),
      ),
      body: _cargando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _PerfilTokens.royalBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando perfil…',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: _PerfilTokens.gunPowder,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Configuración de usuario',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 22 / 15,
                            color: _PerfilTokens.gunPowder,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ProfileHeaderCard(
                          inicial: _inicialAvatar(user),
                          nombre: _nombreMostrado(user),
                          rolEtiqueta: _rolEtiqueta(_role),
                        ),
                        const SizedBox(height: 16),
                        _AccountInfoCard(
                          email: user?.email ?? '—',
                          rolEtiqueta: _rolEtiqueta(_role),
                        ),
                        const SizedBox(height: 16),
                        const _PrivacyNoticeCard(),
                        const SizedBox(height: 20),
                        Text(
                          'Aplicación',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: _PerfilTokens.gunPowder,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SettingsOptionTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Acerca de Chagas Tracker',
                          onTap: _mostrarAcercaDe,
                        ),
                        const SizedBox(height: 8),
                        _SettingsOptionTile(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Buenas prácticas de registro',
                          onTap: _mostrarBuenasPracticas,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Versión $_kAppVersionLabel',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _PerfilTokens.paleSky,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _LogoutButton(onPressed: _confirmarYCerrarSesion),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String inicial;
  final String nombre;
  final String rolEtiqueta;

  const _ProfileHeaderCard({
    required this.inicial,
    required this.nombre,
    required this.rolEtiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _PerfilTokens.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PerfilTokens.blueHaze),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: _PerfilTokens.royalBlue.withValues(alpha: 0.12),
            child: Text(
              inicial,
              style: GoogleFonts.publicSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _PerfilTokens.royalBlue,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.publicSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _PerfilTokens.shark,
            ),
          ),
          const SizedBox(height: 8),
          if (rolEtiqueta != '—')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _PerfilTokens.royalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Rol: $rolEtiqueta',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _PerfilTokens.royalBlue,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Acceso autorizado al registro epidemiológico.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: _PerfilTokens.gunPowder,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final String email;
  final String rolEtiqueta;

  const _AccountInfoCard({
    required this.email,
    required this.rolEtiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _PerfilTokens.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PerfilTokens.blueHaze),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuenta',
            style: GoogleFonts.publicSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _PerfilTokens.shark,
            ),
          ),
          const SizedBox(height: 14),
          _AccountRow(
            icon: Icons.alternate_email_rounded,
            label: 'Correo',
            value: email,
          ),
          const SizedBox(height: 12),
          _AccountRow(
            icon: Icons.badge_outlined,
            label: 'Rol',
            value: rolEtiqueta,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _PerfilTokens.paleSky),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _PerfilTokens.paleSky,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: _PerfilTokens.shark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyNoticeCard extends StatelessWidget {
  const _PrivacyNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _PerfilTokens.privacyFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _PerfilTokens.blueHaze),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 22, color: _PerfilTokens.royalBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Privacidad y uso responsable',
                  style: GoogleFonts.publicSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _PerfilTokens.shark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Recuerda no registrar nombres, RUT, teléfonos ni direcciones exactas '
            'en los casos epidemiológicos.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: _PerfilTokens.gunPowder,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _PerfilTokens.cardSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _PerfilTokens.blueHaze),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: _PerfilTokens.royalBlue, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _PerfilTokens.shark,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: _PerfilTokens.paleSky),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.logout_rounded, color: Colors.red.shade700),
        label: Text(
          'Cerrar sesión',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ConfirmLogoutDialog extends StatelessWidget {
  const _ConfirmLogoutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Cerrar sesión',
        style: GoogleFonts.publicSans(fontWeight: FontWeight.w700),
      ),
      content: Text(
        '¿Deseas cerrar sesión?',
        style: GoogleFonts.inter(fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
