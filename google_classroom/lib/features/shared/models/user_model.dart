class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"],
      username: json["username"],
      fullName: json["full_name"],
      email: json["email"],
      role: json["role"],
      avatarUrl: json["avatar_url"],
    );
  }
}
