import 'package:supabase_flutter/supabase_flutter.dart';

import '../profile_repository.dart';

class ProfileRepositorySupabase implements ProfileRepository {
  final _sb = Supabase.instance.client;

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _sb.auth.currentUser;
    if (user == null) return null;

    final row = await _sb
        .from('profiles')
        .select('display_name, role')
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));

    return UserProfile(
      displayName: row?['display_name']?.toString(),
      role: row?['role']?.toString(),
    );
  }
}
