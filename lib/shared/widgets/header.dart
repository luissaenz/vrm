import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VRMHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final IconData icon;
  final bool iconOnRight;

  const VRMHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.icon = Icons.close_rounded,
    this.iconOnRight = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconWidget = GestureDetector(
      onTap: onBack,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: context.colorScheme.primary),
      ),
    );

    final titleWidget = Expanded(
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colorScheme.primary,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          if (iconOnRight) const SizedBox(width: 40) else iconWidget,
          titleWidget,
          if (iconOnRight) iconWidget else const SizedBox(width: 40),
        ],
      ),
    );
  }
}
