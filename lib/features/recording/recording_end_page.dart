import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'package:vrm_app/l10n/app_localizations.dart';

class RecordingEndPage extends StatelessWidget {
  const RecordingEndPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: isDark
          ? context.colorScheme.surface
          : const Color(0xFFF9FAF9),
      body: Stack(
        children: [
          // Background soft glow
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.forest.withValues(alpha: isDark ? 0.08 : 0.04),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(context, l10n),
                  _buildSummarySection(context, l10n),
                  _buildStatsGrid(context, l10n),
                  _buildPreviewSection(context, l10n),
                ],
              ),
            ),
          ),
          _buildBottomAction(context, l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              size: 24,
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : context.appColors.forest.withValues(alpha: 0.6),
            ),
          ),
          Text(
            l10n.performanceSummary.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: context.appColors.forest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 48), // Spacer to center the title
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            // Progress Circle using SVG-like CustomPaint
            SizedBox(
              width: 208,
              height: 208,
              child: CustomPaint(
                painter: _ProgressPainter(
                  progress: 0.75,
                  color: context.appColors.forest,
                  backgroundColor: context.appColors.forest.withValues(
                    alpha: 0.05,
                  ),
                  strokeWidthOuter: 6,
                  strokeWidthInner: 10,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "42",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: context.appColors.forest,
                          letterSpacing: -1.5,
                        ),
                      ),
                      TextSpan(
                        text: "m",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.forest.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.savedLabel.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: context.appColors.forest.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                l10n.timeSavedTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.forest,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.timeSavedDescription("42", "12"),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: context.appColors.forest.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  context,
                  icon: Icons.speed_rounded,
                  label: l10n.ritmoLabel,
                  value: "145",
                  unit: "ppm",
                  badge: l10n.perfectoLabel,
                  color: context.appColors.forest,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatTile(
                  context,
                  icon: Icons.graphic_eq_rounded,
                  label: l10n.fillerWordsLabel,
                  value: l10n.lowStatus,
                  badge: l10n.detectedLabel("3"),
                  color: const Color(0xFF936639),
                  isEarth: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFullWidthStatTile(
            context,
            icon: Icons.content_cut_rounded,
            label: l10n.pausesLabel,
            value: "4s",
            subtext: l10n.removedLabel,
            progress: 0.25,
            color: context.appColors.forest,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? unit,
    required String badge,
    required Color color,
    bool isEarth = false,
  }) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.forest.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isEarth ? 0.1 : 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isEarth ? 0.1 : 0.05),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isEarth ? color : context.appColors.forestLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.forest.withValues(alpha: 0.4),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.forest,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.forest.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthStatTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required double progress,
    required Color color,
  }) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.forest.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.forest.withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colors.forest,
                        ),
                      ),
                      TextSpan(
                        text: " $subtext",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.forest.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 96,
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.previewTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.forest,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  l10n.editManually,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.forestLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: context.appColors.forest.withValues(alpha: 0.05),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAkNwjAe5DxGHmB5DkyeysYvofLj9IhXPZG2E4aE3ipqAP49jklm0bKiNrUr9AaRFteHE6r5AHbEnDK_RsZAs-Stx3Uig8umuQweWNviKffOx64k7b1x1kDAFx5rAknPnDsj0_kz8vZFMmjdTp6uIWSfZaTiIIlr7KYmISCYRBazGL7YuI2J4g5iBVLH9Sh4Nvy76qR8Uqbca8MYmvCC9909ndWkzECJWkjwoAcWfOo0NNNWWnLVe-6i2IY7t1KqGBnQGs9m8Ar0KCY',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Container(color: Colors.black.withValues(alpha: 0.1)),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: context.appColors.forest,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.forest.withValues(
                            alpha: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "02:14",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, AppLocalizations l10n) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              context.colorScheme.surface,
              context.colorScheme.surface.withValues(alpha: 0.9),
              context.colorScheme.surface.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.forest,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 10,
            shadowColor: context.appColors.forest.withValues(alpha: 0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.exportVideo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.ios_share_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidthOuter;
  final double strokeWidthInner;

  _ProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidthOuter,
    required this.strokeWidthInner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthOuter;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthInner
      ..strokeCap = StrokeCap.round;

    // Drawing progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
