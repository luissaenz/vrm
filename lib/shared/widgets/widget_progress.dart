import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WidgetProgress extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final double progress; // Initial progress, will be incremented internally
  final Duration duration; // Total duration to reach 100%

  const WidgetProgress({
    super.key,
    this.title = 'Generando Guion',
    this.subtitle = 'Tu asistente IA está estructurando los fragmentos...',
    this.description =
        'El motor atómico está conectando tus ideas clave para crear una narrativa coherente.',
    this.progress = 0.0,
    this.duration = const Duration(seconds: 40),
  });

  @override
  State<WidgetProgress> createState() => _WidgetProgressState();
}

class _WidgetProgressState extends State<WidgetProgress>
    with TickerProviderStateMixin {
  late AnimationController _slowRotateController;
  late AnimationController _reverseRotateController;
  late AnimationController _pulseController;

  double _currentProgress = 0.0;
  Timer? _progressTimer;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.progress;

    _slowRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _reverseRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _startProgressAnimation();
  }

  void _startProgressAnimation() {
    final totalSeconds = widget.duration.inSeconds;
    // Evitar división por cero
    final secondsToComplete = totalSeconds > 0 ? totalSeconds : 40;
    final averageIncrement = 1.0 / secondsToComplete;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        // Pasos aleatorios pequeños basados en la duración total
        // Variación del +/- 30% sobre el promedio
        final variation =
            (averageIncrement * 0.6) * (_random.nextDouble() - 0.5);
        final increment = averageIncrement + variation;

        _currentProgress += increment;

        if (_currentProgress >= 1.0) {
          _currentProgress = 1.0;
          timer.cancel(); // Detener la animación al llegar al final
        }
      });
    });
  }

  @override
  void dispose() {
    _slowRotateController.dispose();
    _reverseRotateController.dispose();
    _pulseController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primaryColor = context.colorScheme.primary;
    final isDark = context.isDarkMode;
    final bgColor = context.colorScheme.surface;

    // Aesthetic update: avoid solid whites in center, use glassy effect
    final centerNodeBg = colors.cardBackground.withValues(alpha: 0.8);

    final textColor = colors.textPrimary;
    final mutedTextColor = colors.textSecondary;

    return Material(
      color: bgColor,
      child: Stack(
        children: [
          // Background Glow
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.1),
                      Colors.transparent,
                      primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Atomic Animation Area
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial Blur background
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 320,
                            height: 320,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(
                                    alpha:
                                        0.05 + (0.05 * _pulseController.value),
                                  ),
                                  blurRadius: 80,
                                  spreadRadius: 20 * _pulseController.value,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Slow rotation (dashed)
                      RotationTransition(
                        turns: _slowRotateController,
                        child: CustomPaint(
                          size: const Size(256, 256),
                          painter: DashedCirclePainter(
                            color: primaryColor.withValues(alpha: 0.2),
                            hasNode: true,
                            nodeColor: primaryColor,
                          ),
                        ),
                      ),

                      // Reverse rotation (dotted)
                      RotationTransition(
                        turns: _reverseRotateController,
                        child: CustomPaint(
                          size: const Size(208, 208),
                          painter: DottedCirclePainter(
                            color: primaryColor.withValues(alpha: 0.3),
                            hasNode: true,
                            nodeColor: primaryColor,
                          ),
                        ),
                      ),

                      // Atomic Nodes and Connections (SVG equivalent)
                      CustomPaint(
                        size: const Size(320, 320),
                        painter: AtomicNodesPainter(color: primaryColor),
                      ),

                      // Center Node - Refined Aesthetics
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: centerNodeBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.15),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.1),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Refined Sweep (No sharp white section)
                            RotationTransition(
                              turns: _slowRotateController,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    center: Alignment.center,
                                    colors: [
                                      primaryColor.withValues(alpha: 0.0),
                                      primaryColor.withValues(alpha: 0.25),
                                      primaryColor.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Inner pulse ring
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: primaryColor.withValues(
                                        alpha: 0.1 * _pulseController.value,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Icon(
                              Icons.auto_awesome,
                              color: primaryColor,
                              size: 44,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Title and Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Progress Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EL AGENTE IA ESTÁ TRABAJANDO",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Progress Bar
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.earthLight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          alignment: Alignment.centerLeft,
                          widthFactor: _currentProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.cardBackground.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.cardBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withValues(
                                    alpha: isDark ? 0.7 : 1.0,
                                  ),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final bool hasNode;
  final Color nodeColor;

  DashedCirclePainter({
    required this.color,
    this.hasNode = false,
    required this.nodeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    var currentAngle = 0.0;
    while (currentAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        dashWidth / radius,
        false,
        paint,
      );
      currentAngle += (dashWidth + dashSpace) / radius;
    }

    if (hasNode) {
      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = nodeColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final nodePos = Offset(center.dx, center.dy - radius);
      canvas.drawCircle(nodePos, 5, glowPaint);
      canvas.drawCircle(nodePos, 4, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DottedCirclePainter extends CustomPainter {
  final Color color;
  final bool hasNode;
  final Color nodeColor;

  DottedCirclePainter({
    required this.color,
    this.hasNode = false,
    required this.nodeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 60; i++) {
      final angle = (i * 6) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }

    if (hasNode) {
      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;

      // Positioned at bottom right 1/4 like in HTML (roughly math.pi * 0.75)
      final nodeAngle = math.pi * 0.75;
      final nodePos = Offset(
        center.dx + radius * math.cos(nodeAngle),
        center.dy + radius * math.sin(nodeAngle),
      );
      canvas.drawCircle(nodePos, 3, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AtomicNodesPainter extends CustomPainter {
  final Color color;

  AtomicNodesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintLine = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    final paintNode = Paint()..style = PaintingStyle.fill;

    // Mapping coordinates from 100x100 SVG to local size
    Offset getOffset(double x, double y) {
      return Offset(size.width * (x / 100), size.height * (y / 100));
    }

    final nodes = [
      {'pos': getOffset(25, 25), 'r': 2.5, 'a': 1.0},
      {'pos': getOffset(75, 20), 'r': 2.0, 'a': 0.6},
      {'pos': getOffset(80, 75), 'r': 3.0, 'a': 1.0},
      {'pos': getOffset(20, 80), 'r': 2.0, 'a': 0.8},
    ];

    for (var node in nodes) {
      final pos = node['pos'] as Offset;
      canvas.drawLine(center, pos, paintLine);
      paintNode.color = color.withValues(alpha: node['a'] as double);
      canvas.drawCircle(pos, node['r'] as double, paintNode);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
