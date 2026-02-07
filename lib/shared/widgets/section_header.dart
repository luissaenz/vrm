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
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionPressed,
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primary,
              ),
            ),
          )
        else if (icon != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(color: colors.cardBorder),
            ),
            child: Icon(icon, color: colors.forest, size: 20),
          ),
      ],
    );
  }
}
