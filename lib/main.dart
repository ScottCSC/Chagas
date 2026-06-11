import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'services/network_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const isDemo = bool.fromEnvironment('DEMO_MODE', defaultValue: false);
  const supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKeyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrlDefine.isEmpty || supabaseAnonKeyDefine.isEmpty) {
    try {
      await dotenv.load(
        fileName: isDemo ? '.env.demo' : '.env',
      );
    } catch (_) {
      // Sin asset .env (p. ej. build web sin el archivo en pubspec): usar --dart-define.
    }
  }

  String? envVar(String key) {
    if (!dotenv.isInitialized) return null;
    final v = dotenv.env[key]?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  final supabaseUrl =
      supabaseUrlDefine.isNotEmpty ? supabaseUrlDefine : envVar('SUPABASE_URL');
  final supabaseAnonKey = supabaseAnonKeyDefine.isNotEmpty
      ? supabaseAnonKeyDefine
      : envVar('SUPABASE_ANON_KEY');

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty) {
    throw StateError(
      'Configura SUPABASE_URL y SUPABASE_ANON_KEY con --dart-define.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) return const LoginScreen();
          return const MainShell();
        },
      ),
    );
  }
}
