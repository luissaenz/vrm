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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white.withOpacity(0.7)
                    : AppTheme.textMuted,
                inherit: true,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              date,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textMain,
                inherit: true,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
