import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  /// Verifica si el usuario actual es administrador
  static Future<bool> esAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    print("AUTH user: ${user?.email} id=${user?.id}");

    if (user == null) return false;

    final row = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    print("profiles row: $row");

    return row?['role'] == 'admin';
  }
}
