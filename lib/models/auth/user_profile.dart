class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    username: json['username'],
    email: json['email'],
    phone: json['phone'],
    avatarUrl: json['avatar_url'],
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'phone': phone,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };
}
