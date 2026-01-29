import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile.dart';

class OnboardingRepository {
  static const String _keyIdentity = 'user_identity';
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final identityIndex = prefs.getInt(_keyIdentity) ?? UserIdentity.none.index;
    final completed = prefs.getBool(_keyOnboardingCompleted) ?? false;

    return UserProfile(
      identity: UserIdentity.values[identityIndex],
      onboardingCompleted:
          completed && identityIndex != UserIdentity.none.index,
    );
  }

  Future<void> saveProfile(UserIdentity identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIdentity, identity.index);
    await prefs.setBool(_keyOnboardingCompleted, true);
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIdentity);
    await prefs.remove(_keyOnboardingCompleted);
  }
}
