enum UserRole {
  user,
  admin;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.user,
    );
  }
}
