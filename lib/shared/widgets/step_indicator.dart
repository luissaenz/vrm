import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VRMStepIndicator extends StatelessWidget {
  final String stepNumber;
  final String title;

  const VRMStepIndicator({
    super.key,
    required this.stepNumber,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (stepNumber.isNotEmpty) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: context.appColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
