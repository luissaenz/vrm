import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VRMActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  final IconData? actionIcon;

  const VRMActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.colorScheme.primary;
    final isDark = context.isDarkMode;
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? colors.cardBackground : primaryColor,
          borderRadius: BorderRadius.circular(24), // Rounded 24 as in HTML
          border: isDark ? Border.all(color: colors.cardBorder) : null,
          boxShadow: [
            BoxShadow(
              color: (isDark ? colors.cardBorder : primaryColor).withValues(
                alpha: 0.15,
              ),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isDark
                          ? colors.forestVibrant
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? colors.forestVibrant
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                actionIcon ?? Icons.add,
                color: isDark ? colors.offWhite : Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
