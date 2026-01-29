enum UserIdentity { leader, influencer, seller, none }

class UserProfile {
  final UserIdentity identity;
  final bool onboardingCompleted;

  UserProfile({required this.identity, this.onboardingCompleted = false});

  factory UserProfile.empty() => UserProfile(identity: UserIdentity.none);
}
