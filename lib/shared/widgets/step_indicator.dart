import 'package:flutter/material.dart';

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
        Container(
          width: 24, // Reducido de 32 a 24
          height: 24, // Reducido de 32 a 24
          decoration: const BoxDecoration(
            color: Color(0xFF2A4844),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11, // Reducido acorde al círculo
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.brown[300],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
