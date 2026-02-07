import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VRMProjectCard extends StatelessWidget {
  final String title;
  final String time;
  final double progress;
  final String statusText;
  final String badgeText;
  final IconData icon;
  final Color badgeBg;
  final Color badgeTextCol;
  final String progressLabel;
  final VoidCallback? onTap;

  const VRMProjectCard({
    super.key,
    required this.title,
    required this.time,
    required this.progress,
    required this.statusText,
    required this.badgeText,
    required this.icon,
    required this.badgeBg,
    required this.badgeTextCol,
    required this.progressLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primaryColor = context.colorScheme.primary;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            if (isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  // Added missing Container widget
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.offWhite.withValues(alpha: 0.6)
                        : colors.earthLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: isDark
                        ? Border.all(color: colors.cardBorder)
                        : null,
                  ),
                  child: Icon(icon, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? badgeTextCol.withValues(alpha: 0.1)
                                  : badgeBg,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: badgeTextCol.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              badgeText.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeTextCol,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progressLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0
                        ? const Color(0xFF10B981)
                        : primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? colors.offWhite : colors.earthLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 ? const Color(0xFF10B981) : primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
