import 'social_platform.dart';

class SocialAccount {
  final String id;
  final String name;
  final String? profileImageUrl;
  final SocialPlatform platform;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  SocialAccount({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.platform,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'platform': platform.index,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    return SocialAccount(
      id: json['id'],
      name: json['name'],
      profileImageUrl: json['profileImageUrl'],
      platform: SocialPlatform.values[json['platform']],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }
}
