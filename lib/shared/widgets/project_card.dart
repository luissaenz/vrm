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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppTheme.primaryGreen, size: 18),
                ),
                const SizedBox(width: 12),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: AppTheme.textMain,
                                inherit: true,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: badgeTextCol,
                                inherit: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppTheme.textMuted,
                          inherit: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PROGRESO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    inherit: true,
                  ),
                ),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen, // Siempre verde
                    inherit: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: const Color(0xFFF3F4F6),
              color: progress == 1.0
                  ? const Color(0xFF10B981)
                  : AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}
