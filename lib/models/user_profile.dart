class UserProfile {
  final String id;
  String username;
  String bio;
  String? avatarUrl;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.bio,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
    };
  }
}
