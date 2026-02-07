import 'package:flutter/material.dart';
import '../../core/theme.dart';

class Estimation extends StatelessWidget {
  final double speedPpm;
  final double durationSeconds;
  final double? tolerance;

  const Estimation({
    super.key,
    required this.speedPpm,
    required this.durationSeconds,
    this.tolerance = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatBadge(
          context,
          Icons.speed_rounded,
          "${speedPpm.toStringAsFixed(0)} ppm",
        ),
        if (durationSeconds > 0)
          _buildStatBadge(
            context,
            Icons.schedule_rounded,
            "${durationSeconds.toStringAsFixed(1)}s",
            subLabel: (tolerance != null && tolerance! > 0)
                ? "(±${tolerance!.toStringAsFixed(0)}%)"
                : null,
          ),
      ],
    );
  }

  Widget _buildStatBadge(
    BuildContext context,
    IconData icon,
    String label, {
    String? subLabel,
  }) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.earthLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              children: [
                TextSpan(text: label),
                if (subLabel != null)
                  TextSpan(
                    text: ' $subLabel',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
