import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VRMStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const VRMStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16), // Reducido de 20
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // Más redondeado
          border: Border.all(color: AppTheme.border), // Borde sólido de 1px
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14), // Reducido de 16
            ),
            const SizedBox(height: 12), // Reducido de 16
            Text(
              value,
              style: const TextStyle(
                fontSize: 18, // Reducido de 20
                fontWeight: FontWeight.w900,
                color: AppTheme.textMain,
                height: 1.1,
                inherit: true,
              ),
            ),
            const SizedBox(height: 1), // Mínimo espacio
            Text(
              label,
              style: const TextStyle(
                fontSize: 7.5, // Reducido de 8
                color: AppTheme.textMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                height: 1.2,
                inherit: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
