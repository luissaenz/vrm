import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_app/features/social_accounts/domain/social_platform.dart';
import 'package:vrm_app/features/social_accounts/social_account_manager.dart';

void main() {
  test(
    'SocialAccountManager should manage accounts and simulate sharing',
    () async {
      final manager = SocialAccountManager();

      // Initial state
      expect(manager.accounts.isEmpty, true);

      // Connect some accounts (simulated)
      await manager.connectAccount(SocialPlatform.facebook);
      await manager.connectAccount(SocialPlatform.instagram);
      await manager.connectAccount(SocialPlatform.tiktok);

      expect(manager.accounts.length, 3);
      expect(
        manager.accounts.any((a) => a.platform == SocialPlatform.facebook),
        true,
      );

      // Simulate sharing
      final fakeFile = File('dummy_video.mp4');
      final success = await manager.shareToAll(
        fakeFile,
        'Check out my new video!',
      );
      expect(success, true);

      // Disconnect an account
      final accountToDisconnect = manager.accounts.first;
      await manager.disconnectAccount(accountToDisconnect);
      expect(manager.accounts.length, 2);
    },
  );
}
