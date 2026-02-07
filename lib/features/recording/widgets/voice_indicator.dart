import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/voice_indicator_state.dart';

class VRMVoiceIndicator extends StatelessWidget {
  final VoiceIndicatorState state;
  final Animation<double> pulseAnimation;

  const VRMVoiceIndicator({
    super.key,
    required this.state,
    required this.pulseAnimation,
  });

  // Re-using the colors from the previous implementation
  static const Color _forestAccent = Color(0xFF2DD4BF);
  static const Color _dotColor = Color(0xFF1FA88A);

  @override
  Widget build(BuildContext context) {
    if (state == VoiceIndicatorState.heard) {
      return _buildCommandDetected();
    }
    return _buildListening();
  }

  Widget _buildListening() {
    final bool isDisabled = state == VoiceIndicatorState.disabled;

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 9,
            height: 9,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 6 * pulseAnimation.value,
                      height: 6 * pulseAnimation.value,
                      decoration: BoxDecoration(
                        color: _dotColor.withValues(
                          alpha: 1.0 - (pulseAnimation.value - 1.0),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Text(
                'AGENTE ESCUCHANDO...',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 1.0 - ((pulseAnimation.value - 1.0) * 0.75),
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommandDetected() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2925).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _forestAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _forestAccent.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom Square Check Icon
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF63B032),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'COMANDO DETECTADO: SIGUIENTE',
                style: TextStyle(
                  color: _forestAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  shadows: [Shadow(color: _forestAccent, blurRadius: 10)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
