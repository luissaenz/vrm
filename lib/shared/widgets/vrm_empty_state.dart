import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VRMEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const VRMEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.auto_stories_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with soft glow
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.forest.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.forest.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(icon, size: 64, color: colors.forest),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              title.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  actionLabel!.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
