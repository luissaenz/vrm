import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile.dart';

class OnboardingRepository {
  static const String _keyIdentity = 'user_identity';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyMinTime = 'segment_min_time';
  static const String _keyMaxTime = 'segment_max_time';
  static const String _keyRateWpm = 'segment_rate_wpm';

  Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final identityIndex = prefs.getInt(_keyIdentity) ?? UserIdentity.none.index;
    final completed = prefs.getBool(_keyOnboardingCompleted) ?? false;

    return UserProfile(
      identity: UserIdentity.values[identityIndex],
      onboardingCompleted:
          completed && identityIndex != UserIdentity.none.index,
      segmentMinTime: prefs.getDouble(_keyMinTime) ?? 3.0,
      segmentMaxTime: prefs.getDouble(_keyMaxTime) ?? 10.0,
      segmentRateWpm: prefs.getDouble(_keyRateWpm) ?? 160.0,
    );
  }

  Future<void> saveProfile(
    UserIdentity identity, {
    double minTime = 3.0,
    double maxTime = 10.0,
    double rateWpm = 160.0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIdentity, identity.index);
    await prefs.setBool(_keyOnboardingCompleted, true);
    await prefs.setDouble(_keyMinTime, minTime);
    await prefs.setDouble(_keyMaxTime, maxTime);
    await prefs.setDouble(_keyRateWpm, rateWpm);
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIdentity);
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keyMinTime);
    await prefs.remove(_keyMaxTime);
    await prefs.remove(_keyRateWpm);
  }
}
