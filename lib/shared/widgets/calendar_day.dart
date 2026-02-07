import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VRMCalendarDay extends StatelessWidget {
  final String day;
  final String date;
  final bool isSelected;
  final VoidCallback? onTap;

  const VRMCalendarDay({
    super.key,
    required this.day,
    required this.date,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primaryColor = context.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: colors.cardBorder),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              day.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.7)
                    : colors.textSecondary.withValues(alpha: 0.8),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : (isSelected ? Colors.transparent : primaryColor),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
