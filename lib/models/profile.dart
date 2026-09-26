class Profile {
  final String id;
  final String email;
  final String fullName;
  final String? career;
  final String? phone;
  final String? avatarUrl;
  final DateTime? createdAt;

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    this.career,
    this.phone,
    this.avatarUrl,
    this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Estudiante UCSS',
      career: json['career'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      if (career != null) 'career': career,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }
}
