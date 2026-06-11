class UserProfile {
  final String? displayName;
  final String? role;

  const UserProfile({
    this.displayName,
    this.role,
  });
}

abstract class ProfileRepository {
  Future<UserProfile?> getCurrentUserProfile();
}
