import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/network_service.dart';

class _SupabaseConfig {
  const _SupabaseConfig({required this.url, required this.anonKey});
  final String url;
  final String anonKey;
}

Future<_SupabaseConfig?> _loadSupabaseConfig() async {
  const isDemo = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
  const urlDefine = String.fromEnvironment('SUPABASE_URL');
  const keyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (urlDefine.isNotEmpty && keyDefine.isNotEmpty) {
    return _SupabaseConfig(url: urlDefine, anonKey: keyDefine);
  }

  try {
    await dotenv.load(fileName: isDemo ? '.env.demo' : '.env');
  } catch (_) {
    // Web local sin asset .env: usar --dart-define-from-file=.env
  }

  String? envVar(String key) {
    if (!dotenv.isInitialized) return null;
    final v = dotenv.env[key]?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  final url = envVar('SUPABASE_URL');
  final key = envVar('SUPABASE_ANON_KEY');
  if (url == null || key == null) return null;
  return _SupabaseConfig(url: url, anonKey: key);
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.settings_outlined,
                        size: 48, color: Colors.grey.shade600),
                    const SizedBox(height: 16),
                    Text(
                      'Falta configuración de Supabase',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'En desarrollo local, ejecuta la app con tu archivo .env '
                      '(no se sube a GitHub):',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SelectableText(
                        'flutter run -d edge --dart-define-from-file=.env',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'O en PowerShell: .\\scripts\\run-web.ps1',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await _loadSupabaseConfig();
  if (config == null) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: config.url,
    anonKey: config.anonKey,
  );

  await NetworkService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: const _AuthGate(),
    );
  }
}

/// Decide entre login y home según la sesión, reaccionando a cambios de auth.
/// El splash animado se muestra únicamente como antesala del login; si ya hay
/// sesión activa, se entra directo a la app sin splash.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const SplashScreen(nextScreen: LoginScreen());
        }
        return const MainShell();
      },
    );
  }
}
