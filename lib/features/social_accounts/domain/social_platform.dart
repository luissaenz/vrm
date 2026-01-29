enum SocialPlatform { facebook, instagram, tiktok, youtube, twitter }

extension SocialPlatformExtension on SocialPlatform {
  String get displayName {
    switch (this) {
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.youtube:
        return 'YouTube';
      case SocialPlatform.twitter:
        return 'Twitter';
    }
  }
}
