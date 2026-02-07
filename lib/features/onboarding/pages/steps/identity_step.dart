import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme.dart';
import '../../data/user_profile.dart'; // Assuming UserIdentity.none is defined here or will be.

class IdentityStep extends StatefulWidget {
  final Function(UserIdentity) onSelected;
  const IdentityStep({super.key, required this.onSelected});

  @override
  State<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends State<IdentityStep> {
  late PageController _pageController;
  int _currentPage = 0;
  final List<UserIdentity> _identities = [
    UserIdentity.leader,
    UserIdentity.influencer,
    UserIdentity.seller,
  ];

  @override
  void initState() {
    super.initState();
    // Start with influencer (middle) if possible, or just the first one.
    _currentPage = 1;
    _pageController = PageController(
      viewportFraction: 0.55, // Show significantly more of side cards
      initialPage: _currentPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64), // More space since header is gone
            _buildHeadline(),
            const Spacer(),
            _buildCardsSection(),
            const Spacer(),
            _buildActionButtons(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.identityHeadline,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.identitySubheadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    return SizedBox(
      height: 460,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: _identities.length,
          itemBuilder: (context, index) {
            final identity = _identities[index];
            double scale = _currentPage == index ? 1.0 : 0.82;
            double opacity = _currentPage == index ? 1.0 : 0.5;

            return TweenAnimationBuilder(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: scale, end: scale),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: opacity,
                    child: _buildIdentityCard(
                      _getTitle(identity),
                      _getTag(identity),
                      _getQuote(identity),
                      _getImageUrl(identity),
                      identity,
                      index == _currentPage,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _getTitle(UserIdentity identity) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.profileLeaderTitle;
      case UserIdentity.influencer:
        return l10n.profileInfluencerTitle;
      case UserIdentity.seller:
        return l10n.profileSellerTitle;
      default:
        return '';
    }
  }

  String _getTag(UserIdentity identity) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.profileLeaderTag;
      case UserIdentity.influencer:
        return l10n.profileInfluencerTag;
      case UserIdentity.seller:
        return l10n.profileSellerTag;
      default:
        return '';
    }
  }

  String _getQuote(UserIdentity identity) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.profileLeaderQuote;
      case UserIdentity.influencer:
        return l10n.profileInfluencerQuote;
      case UserIdentity.seller:
        return l10n.profileSellerQuote;
      default:
        return '';
    }
  }

  String _getImageUrl(UserIdentity identity) {
    final l10n = AppLocalizations.of(context)!;
    switch (identity) {
      case UserIdentity.leader:
        return l10n.profileLeaderImage;
      case UserIdentity.influencer:
        return l10n.profileInfluencerImage;
      case UserIdentity.seller:
        return l10n.profileSellerImage;
      default:
        return '';
    }
  }

  Widget _buildIdentityCard(
    String title,
    String tag,
    String quote,
    String imageUrl,
    UserIdentity identity,
    bool isSelected,
  ) {
    final colors = context.appColors;
    final primaryColor = context.colorScheme.primary;
    final isDark = context.isDarkMode;

    return Center(
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: colors.cardBackground,
          border: Border.all(
            color: isSelected && isDark ? primaryColor : colors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isDark)
              BoxShadow(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: isSelected ? 30 : 15,
                spreadRadius: isSelected ? -2 : 0,
              )
            else
              BoxShadow(
                color: isSelected
                    ? context.colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: isSelected ? 25 : 15,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            30,
          ), // Smaller than container due to border
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imageUrl, fit: BoxFit.cover),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Text(
                              quote,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF4A5568),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    return Column(
      children: [
        Text(
          _getTag(_identities[_currentPage]).toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.0,
            color: context.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: ElevatedButton(
            onPressed: () => widget.onSelected(_identities[_currentPage]),
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? context.appColors.forestVibrant
                      : context.colorScheme.primary,
                  foregroundColor: isDark
                      ? context.appColors.offWhite
                      : Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: isDark ? 0 : 4,
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(
                    Colors.white.withValues(alpha: 0.1),
                  ),
                ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.identityConfirm.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
