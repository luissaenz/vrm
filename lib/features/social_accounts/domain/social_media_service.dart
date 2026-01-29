import 'social_account.dart';
import 'dart:io';

abstract class SocialMediaService {
  Future<SocialAccount?> authorize();
  Future<void> logout(SocialAccount account);
  Future<bool> postVideo(
    SocialAccount account,
    File videoFile,
    String description,
  );
  Future<bool> refreshToken(SocialAccount account);
}
