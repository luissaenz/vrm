import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme.dart';

class WelcomeStep extends StatefulWidget {
  final VoidCallback onNext;
  const WelcomeStep({super.key, required this.onNext});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildHeadline(context),
                  const SizedBox(height: 32),
                  const Spacer(),
                  _buildCoachContainer(context),
                  const Spacer(),
                  const SizedBox(height: 32),
                  _buildActionFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.welcomeTitle.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 4.0,
            fontSize: 12,
            color: context.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeadline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        AppLocalizations.of(context)!.welcomeHeadline,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: context.appColors.textPrimary,
          height: 1.1,
          letterSpacing: -1,
        ),
      ),
    );
  }

  Widget _buildCoachContainer(BuildContext context) {
    final isDark = context.isDarkMode;
    final primaryColor = context.colorScheme.primary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: context.appColors.cardBackground,
              boxShadow: [
                if (isDark)
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: -5,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    AppLocalizations.of(context)!.welcomeCoachImage,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionFooter(BuildContext context) {
    final isDark = context.isDarkMode;
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: ElevatedButton(
            onPressed: widget.onNext,
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
                  AppLocalizations.of(context)!.welcomeCta.toUpperCase(),
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
        const SizedBox(height: 24),
      ],
    );
  }
}
