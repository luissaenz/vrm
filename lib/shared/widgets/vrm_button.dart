import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Un botón premium con micro-animaciones de escala y glow.
class VRMButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool isSecondary;
  final bool isLoading;

  const VRMButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.isSecondary = false,
    this.isLoading = false,
  });

  @override
  State<VRMButton> createState() => _VRMButtonState();
}

class _VRMButtonState extends State<VRMButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appColors;
    final primaryColor = widget.color ?? theme.forestVibrant;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: widget.isSecondary 
                  ? Colors.transparent 
                  : (widget.onPressed == null ? Colors.grey : primaryColor),
              borderRadius: BorderRadius.circular(16),
              border: widget.isSecondary 
                  ? Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5)
                  : null,
              boxShadow: [
                if (!widget.isSecondary && widget.onPressed != null)
                  BoxShadow(
                    color: primaryColor.withValues(alpha: _isHovered ? 0.4 : 0.2),
                    blurRadius: _isHovered ? 20 : 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isSecondary ? primaryColor : Colors.white,
                      ),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.isSecondary ? primaryColor : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      color: widget.isSecondary ? primaryColor : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
