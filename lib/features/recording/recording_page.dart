import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage>
    with SingleTickerProviderStateMixin {
  bool _isGridActive = true;
  bool _isGhostActive = false;
  late AnimationController _voiceBarController;

  @override
  void initState() {
    super.initState();
    _voiceBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _voiceBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Placeholder / Background Image
          _buildCameraPlaceholder(),

          // Grid Overlay
          if (_isGridActive) _buildGridOverlay(),

          // Ghost Overlay Placeholder
          if (_isGhostActive) _buildGhostOverlay(),

          // Main UI Layer
          SafeArea(
            child: Column(
              children: [
                _buildHeader(l10n),
                const Spacer(),
                _buildScriptDisplay(l10n),
                const Spacer(),
                _buildBottomControls(l10n),
                _buildVoiceStatusIndicator(l10n),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCL9dX83u1D_SXYW2N8R_Ucyk65smO7Bfs2tSpBIvic_sGgaEbOxpatjkiPmJi9HHiCEq2Kjt9-qsDxuEkokpWlep477_ICd15Asg_LSnmkZ0NzOiJh6P1jfGpNGMAkioVWTg6poYl9S1-GVHu7QRpE124-VNuHHLQEwfB-5FszKeHIm2bBkO4KmMFtLmxjxnOqJihZ1Y-eG5N3yl9QsDaP1R2NgOTG0yEvSQzyDdgD2eSWGAvsgVEgTfpDS30peMYFAwIcDergpfop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: GridPainter())),
    );
  }

  Widget _buildGhostOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.15,
          child: Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC4dL64or0D3JzuWVy1ie7G-w5fu9E8ZVh9sjXIb2St7zSSMb5_N_WJUjqiUkKumAKe1t7bQ-3tNbtBbSIwzBbdNK_uRTole55y0YoNBuwtPPv8h9-2qasnexFIgiEsfiilfdwXtuxkQJxBbIiFQlQakSsA1gz0av21EWckih62rRryTttviTqgIojyC2-fCcDlPGuyjHMEkmtS6rbHKgOcQ2tuSEAO2YBfUvwECGgiLd3PTjuSgT8I9g3z5pDk9vupDsFG33Hbj20p',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleBtn(Icons.close_rounded, () => Navigator.pop(context)),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.forest.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  l10n.recordingStatus.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Fragmento 2 de 5", // Placeholder
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          _buildCircleBtn(Icons.cameraswitch_rounded, () {}),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildScriptDisplay(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Large background number
          Text(
            "2",
            style: TextStyle(
              fontSize: 220,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.05),
              height: 1,
            ),
          ),
          // Glass script card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      height: 1.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: "Hola a todos, ",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const TextSpan(
                        text: "hoy vamos a ver ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.forest,
                          decorationThickness: 2,
                        ),
                      ),
                      const TextSpan(
                        text:
                            "lo increíble que es esto para crear contenido rápido.",
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          // Voice bars animation
          AnimatedBuilder(
            animation: _voiceBarController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final height = 10 + (10 * _voiceBarController.value);
                  return Container(
                    width: 4,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == 2 || index == 3
                          ? AppTheme.forest
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 32),
          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildToggleControl(
                    icon: Icons.grid_3x3_rounded,
                    label: l10n.gridLabel,
                    isActive: _isGridActive,
                    onTap: () => setState(() => _isGridActive = !_isGridActive),
                  ),
                  const SizedBox(width: 16),
                  _buildToggleControl(
                    icon: Icons.blur_on_rounded,
                    label: l10n.ghostLabel,
                    isActive: _isGhostActive,
                    onTap: () =>
                        setState(() => _isGhostActive = !_isGhostActive),
                  ),
                ],
              ),
              // Stop/Record Button
              _buildStopButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleControl({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.forest
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.forest.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.forest,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceStatusIndicator(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const StatusPulse(),
        const SizedBox(width: 8),
        Text(
          l10n.listeningToAdvance,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    // Vertical lines
    canvas.drawLine(
      Offset(cellWidth, 0),
      Offset(cellWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(cellWidth * 2, 0),
      Offset(cellWidth * 2, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, cellHeight),
      Offset(size.width, cellHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, cellHeight * 2),
      Offset(size.width, cellHeight * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class StatusPulse extends StatefulWidget {
  const StatusPulse({super.key});

  @override
  State<StatusPulse> createState() => _StatusPulseState();
}

class _StatusPulseState extends State<StatusPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.forest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.forest.withValues(
                  alpha: 0.7 * _controller.value,
                ),
                blurRadius: 6 * _controller.value,
                spreadRadius: 4 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
