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
      child: Stack(
        children: [
          SafeArea(
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
          _buildNavigationIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.identityHeadline,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppTheme.earth,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.identitySubheadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
              height: 1.4,
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
    return Center(
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          // Border removed as per user request
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.forest.withValues(alpha: 0.15)
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
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Text(
                              quote,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4A5568),
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
                      Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white70,
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
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: ElevatedButton(
            onPressed: () => widget.onSelected(_identities[_currentPage]),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forest,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.identityConfirm,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward, size: 20, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'EXPERIENCIA INMERSIVA',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
            color: Color(0x664A5568),
          ),
        ),
      ],
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
