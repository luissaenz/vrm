import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VRMSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final IconData? icon;

  const VRMSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMain,
            inherit: true,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionPressed,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentTealDark,
                inherit: true,
              ),
            ),
          )
        else if (icon != null)
          Icon(icon, color: AppTheme.textMuted, size: 20),
      ],
    );
  }
}
