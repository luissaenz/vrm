import 'package:flutter/material.dart';

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
          Icons.speed_rounded,
          "${speedPpm.toStringAsFixed(0)} ppm",
        ),
        if (durationSeconds > 0)
          _buildStatBadge(
            Icons.schedule_rounded,
            "${durationSeconds.toStringAsFixed(1)}s",
            subLabel: (tolerance != null && tolerance! > 0)
                ? "(±${tolerance!.toStringAsFixed(0)}%)"
                : null,
          ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String label, {String? subLabel}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.5), // slate 100
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.5), // slate 200
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)), // slate 500
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155), // slate 700
              ),
              children: [
                TextSpan(text: label),
                if (subLabel != null)
                  TextSpan(
                    text: ' $subLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8), // slate 400
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
