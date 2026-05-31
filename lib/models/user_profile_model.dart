class UserProfileModel {
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String? avatarPath; // Local file path from image_picker

  const UserProfileModel({
    this.name = 'Your Name',
    this.email = '',
    this.phone = '',
    this.bio = '',
    this.avatarPath,
  });

  /// First letter of name for avatar initials
  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  UserProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }

  Map<String, String> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'bio': bio,
        if (avatarPath != null) 'avatarPath': avatarPath!,
      };

  factory UserProfileModel.fromMap(Map<String, String?> map) {
    return UserProfileModel(
      name: map['name'] ?? 'Your Name',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      avatarPath: map['avatarPath'],
    );
  }
}
