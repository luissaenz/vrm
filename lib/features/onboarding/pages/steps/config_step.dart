import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme.dart';
import '../../data/user_profile.dart';

class ConfigStep extends StatelessWidget {
  final UserIdentity identity;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  const ConfigStep({
    super.key,
    required this.identity,
    required this.onFinish,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildCoachAvatar(),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _getGreeting(context),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.forest,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'COACH DE VIDEO AI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: AppTheme.earth,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildSummarySection(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _buildFooter(context),
              ],
            ),
          ),
          _buildNavigationIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.earth.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppTheme.forest,
              ),
            ),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.configTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppTheme.forest,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer to compensate for back button
        ],
      ),
    );
  }

  Widget _buildCoachAvatar() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.forest, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const ClipOval(
              child: Image(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCTz3U5Ua2urJ32YX2Rv5_yQwTlDQcyYT6DzIHCqLqpJzl0EyhjhKdu6T9JNyAq9pPm2bRQTjaBOs96MUoayiAxV2dFer7Z5ZynL01zWDcQ16VIDsZCiT0FV0OYuiAlrey62DPND9KsfUggRO9VBfjN3AHgkz2Mtn40iseFp3lr8sYaWRtf-JUCVEVPDCIgUUaQRs4tOpcEoLF2e0qj46jSFxbycDNpYBEqIQ1h4rkMvqQ10qZrp0WNBcGYQQYbAZamTcozC7WP1VIk',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.forest.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.configGreetingLeader;
      case UserIdentity.influencer:
        return l10n.configGreetingInfluencer;
      case UserIdentity.seller:
        return l10n.configGreetingSeller;
      default:
        return l10n.configGreetingDefault;
    }
  }

  Widget _buildSummarySection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.configSummaryLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              color: AppTheme.earth,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildConfigItem(
          Icons.speed,
          _getTeleprompterSpeed(context),
          l10n.configTeleprompterLabel,
        ),
        const SizedBox(height: 16),
        _buildConfigItem(
          Icons.auto_fix_high,
          _getSolutionTitle(context),
          _getSolutionSubtitle(context),
        ),
        const SizedBox(height: 16),
        _buildConfigItem(
          Icons.star_rounded,
          _getPremiumFeatureTitle(context),
          _getPremiumFeatureSubtitle(context),
          isPremium: true,
        ),
      ],
    );
  }

  String _getSolutionTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.configSolutionLeaderTitle;
      case UserIdentity.influencer:
        return l10n.configSolutionInfluencerTitle;
      case UserIdentity.seller:
        return l10n.configSolutionSellerTitle;
      default:
        return l10n.configSolutionDefaultTitle;
    }
  }

  String _getSolutionSubtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.configSolutionLeaderSubtitle;
      case UserIdentity.influencer:
        return l10n.configSolutionInfluencerSubtitle;
      case UserIdentity.seller:
        return l10n.configSolutionSellerSubtitle;
      default:
        return l10n.configSolutionDefaultSubtitle;
    }
  }

  String _getPremiumFeatureTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.configPremiumLeaderTitle;
      case UserIdentity.influencer:
        return l10n.configPremiumInfluencerTitle;
      case UserIdentity.seller:
        return l10n.configPremiumSellerTitle;
      default:
        return l10n.configPremiumDefaultTitle;
    }
  }

  String _getPremiumFeatureSubtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.configPremiumLeaderSubtitle;
      case UserIdentity.influencer:
        return l10n.configPremiumInfluencerSubtitle;
      case UserIdentity.seller:
        return l10n.configPremiumSellerSubtitle;
      default:
        return l10n.configPremiumDefaultSubtitle;
    }
  }

  String _getTeleprompterSpeed(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.profileTeleprompterLeader('150');
      case UserIdentity.influencer:
        return l10n.profileTeleprompterInfluencer('135');
      case UserIdentity.seller:
        return l10n.profileTeleprompterSeller('120');
      default:
        return 'Teleprompter Estándar';
    }
  }

  Widget _buildConfigItem(
    IconData icon,
    String title,
    String subtitle, {
    bool isPremium = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPremium
                  ? AppTheme.forest.withValues(alpha: 0.1)
                  : AppTheme.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.forest, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.forest,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.forest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.earth,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isPremium ? Icons.lock_outline : Icons.check_circle,
            color: AppTheme.forest,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forest,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: AppTheme.forest.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.configCta,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.videocam_outlined, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.configFooterLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: AppTheme.earth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationIndicator() {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 128,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.forest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
