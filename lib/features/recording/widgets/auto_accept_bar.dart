import 'package:flutter/material.dart';

/// Widget que muestra la barra de progreso de auto-aceptación.
class AutoAcceptBar extends StatelessWidget {
  final Animation<double> progressAnimation;

  const AutoAcceptBar({super.key, required this.progressAnimation});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 24,
      right: 24,
      child: AnimatedBuilder(
        animation: progressAnimation,
        builder: (context, child) {
          return Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
