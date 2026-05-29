class AppUser {
  final int userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? googleId;
  final DateTime? createdAt;

  AppUser({
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.googleId,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['user_id'],
      fullName: json['full_name'] ?? 'Người dùng',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      googleId: json['google_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'google_id': googleId,
    };
  }

  /// Lấy chữ cái đầu của tên để hiển thị avatar fallback
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
