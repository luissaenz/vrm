import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../recording/recording_page.dart';

class PreparationPage extends StatefulWidget {
  const PreparationPage({super.key});

  @override
  State<PreparationPage> createState() => _PreparationPageState();
}

class _PreparationPageState extends State<PreparationPage> {
  // Design Tokens from the provided HTML/Tailwind config
  static const Color forest = Color(0xFF2D4B44);
  static const Color backgroundLight = Color(0xFFF9F8F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  bool _isVoiceControlActive = true;
  int _countdown = 3;
  double _countdownProgress = 0.0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
          _countdownProgress += 0.33;
        } else {
          timer.cancel();
          _countdownProgress = 1.0;
          // Lógica tras completar cuenta regresiva
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header based on HTML
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: forest,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Text(
                    l10n.preparation.toUpperCase(),
                    style: const TextStyle(
                      color: forest,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance for back button
                ],
              ),
            ),

            // Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.fragmentCount("1", "5").toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: forest.withValues(alpha: 0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _isVoiceControlActive
                                  ? forest
                                  : Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (_isVoiceControlActive
                                    ? l10n.listening
                                    : l10n.waiting)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isVoiceControlActive
                                  ? forest
                                  : Colors.grey[400],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value:
                          0.2, // Este es el progreso de grabación, no la cuenta atrás
                      backgroundColor: forest.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(forest),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // Script Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.volume_up,
                          size: 18,
                          color: forest.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.systemReads.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: forest.withValues(alpha: 0.4),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Hola, mi nombre es Juan",
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: forest,
                              height: 1.3,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: " y quiero presentar mi proyecto.",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: forest.withValues(alpha: 0.3),
                              height: 1.3,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Central Card Section
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer phone-like card
                          Container(
                            width: 176, // 44 * 4
                            height: 288, // 72 * 4
                            decoration: BoxDecoration(
                              color: surfaceLight,
                              borderRadius: BorderRadius.circular(40), // 2.5rem
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                  spreadRadius: -15,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: backgroundLight,
                                  borderRadius: BorderRadius.circular(
                                    35,
                                  ), // 2.2rem
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    // Notch handle
                                    Positioned(
                                      top: 16,
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Waves placeholder (opacity 10 in CSS)
                                    Positioned(
                                      bottom: 40,
                                      child: Opacity(
                                        opacity: 0.1,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            _buildWaveBar(16),
                                            const SizedBox(width: 4),
                                            _buildWaveBar(32),
                                            const SizedBox(width: 4),
                                            _buildWaveBar(24),
                                            const SizedBox(width: 4),
                                            _buildWaveBar(12),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Countdown Overlay
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 128,
                                    height: 128,
                                    child: CircularProgressIndicator(
                                      value: _countdownProgress,
                                      strokeWidth: 2,
                                      backgroundColor: forest.withValues(
                                        alpha: 0.1,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            forest,
                                          ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Text(
                                    "$_countdown",
                                    style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: forest,
                                      letterSpacing: -2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.getReady.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: forest.withValues(alpha: 0.4),
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Glass Footer
            Container(
              decoration: BoxDecoration(
                color: surfaceLight.withValues(alpha: 0.8),
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Voice control badge
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isVoiceControlActive = !_isVoiceControlActive;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isVoiceControlActive
                                  ? forest.withValues(alpha: 0.05)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _isVoiceControlActive
                                    ? forest.withValues(alpha: 0.1)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isVoiceControlActive
                                      ? Icons.mic
                                      : Icons.mic_off,
                                  size: 14,
                                  color: _isVoiceControlActive
                                      ? forest
                                      : Colors.grey[500],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (_isVoiceControlActive
                                          ? l10n.voiceControlActive
                                          : l10n.voiceControlDisabled)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _isVoiceControlActive
                                        ? forest.withValues(alpha: 0.6)
                                        : Colors.grey[500],
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildControlBtn(Icons.replay, l10n.repeat, 56),
                            _buildRecordBtn(l10n.record),
                            _buildControlBtn(Icons.skip_next, l10n.next, 56),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: forest,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildControlBtn(IconData icon, String label, double size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: surfaceLight,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {},
              child: Icon(icon, color: forest.withValues(alpha: 0.4), size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"$label"'.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: forest.withValues(alpha: 0.3),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordBtn(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: forest,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: forest.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecordingPage(),
                  ),
                );
              },
              child: const Icon(
                Icons.fiber_manual_record,
                color: surfaceLight,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '"$label"'.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: forest,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
