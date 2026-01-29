import 'dart:io';
import 'package:flutter/foundation.dart';
import 'domain/social_account.dart';
import 'domain/social_media_service.dart';
import 'domain/social_platform.dart';
import 'data/platform_services.dart';

class SocialAccountManager {
  static final SocialAccountManager _instance =
      SocialAccountManager._internal();
  factory SocialAccountManager() => _instance;
  SocialAccountManager._internal();

  final List<SocialAccount> _accounts = [];
  List<SocialAccount> get accounts => List.unmodifiable(_accounts);

  final Map<SocialPlatform, SocialMediaService> _services = {
    SocialPlatform.facebook: FacebookService(),
    SocialPlatform.instagram: InstagramService(),
    SocialPlatform.tiktok: TikTokService(),
    SocialPlatform.youtube: YouTubeService(),
    SocialPlatform.twitter: TwitterService(),
  };

  Future<void> connectAccount(SocialPlatform platform) async {
    final service = _services[platform];
    if (service != null) {
      final account = await service.authorize();
      if (account != null) {
        _accounts.add(account);
        debugPrint(
          'Account connected: ${account.name} on ${platform.displayName}',
        );
      }
    }
  }

  Future<void> disconnectAccount(SocialAccount account) async {
    final service = _services[account.platform];
    if (service != null) {
      await service.logout(account);
      _accounts.removeWhere((a) => a.id == account.id);
      debugPrint('Account disconnected: ${account.name}');
    }
  }

  Future<bool> shareToAll(File videoFile, String description) async {
    if (_accounts.isEmpty) return false;

    final results = await Future.wait(
      _accounts.map(
        (account) => _services[account.platform]!.postVideo(
          account,
          videoFile,
          description,
        ),
      ),
    );

    return results.every((success) => success);
  }

  Future<bool> shareToAccount(
    SocialAccount account,
    File videoFile,
    String description,
  ) async {
    final service = _services[account.platform];
    if (service != null) {
      return await service.postVideo(account, videoFile, description);
    }
    return false;
  }
}
