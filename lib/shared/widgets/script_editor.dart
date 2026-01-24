import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VRMScriptEditor extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final List<Widget> actions;
  final Widget? trailing;

  const VRMScriptEditor({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines = 8,
    this.actions = const [],
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1), // Slate 300
                  fontSize: 16,
                  fontStyle: FontStyle.normal,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF334155), // Slate 700
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...actions.map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: action,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget actionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foregroundColor ?? AppTheme.forest),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor ?? AppTheme.forest,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget actionIcon({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      ),
    );
  }
}
