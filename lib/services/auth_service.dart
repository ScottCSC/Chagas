import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  /// Verifica si el usuario actual es administrador
  static Future<bool> esAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return false;

    final row = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return row?['role'] == 'admin';
  }
}
