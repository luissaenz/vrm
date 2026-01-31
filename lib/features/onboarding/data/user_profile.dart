enum UserIdentity { leader, influencer, seller, none }

class UserProfile {
  final UserIdentity identity;
  final bool onboardingCompleted;
  final double segmentMinTime;
  final double segmentMaxTime;
  final double segmentRateWpm;

  UserProfile({
    required this.identity,
    this.onboardingCompleted = false,
    this.segmentMinTime = 3.0,
    this.segmentMaxTime = 10.0,
    this.segmentRateWpm = 160.0,
  });

  factory UserProfile.empty() => UserProfile(identity: UserIdentity.none);
}
