import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import '../../core/theme.dart';
import '../new_project/models/script_analysis.dart';

import 'models/recording_state.dart';
import 'models/voice_indicator_state.dart';
import 'widgets/voice_indicator.dart';
import 'recording_end_page.dart';

class RecordingPage extends StatefulWidget {
  final ScriptAnalysis analysis;
  final int currentFragmentIndex;

  const RecordingPage({
    super.key,
    required this.analysis,
    this.currentFragmentIndex = 0,
  });

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _countdownController;
  late Animation<double> _countdownProgress;

  RecordingState _recordingState = RecordingState.idle;
  late int _activeFragmentIndex;
  final int _currentWordIndex = 0;
  int _countdownValue = 3;
  Timer? _countdownTimer;
  bool _isCommandHeard = false;

  late AnimationController _menuController;
  late Animation<Offset> _menuAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _countdownProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.linear),
    );

    _menuController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _menuAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _menuController, curve: Curves.easeOutCubic),
        );

    _activeFragmentIndex = widget.currentFragmentIndex;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _countdownController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  List<InlineSpan> _buildTextSpans() {
    final segment = widget.analysis.segments[_activeFragmentIndex];
    final text = segment.text;
    final emphasisRefs = _parseReferences(segment.direction.emphasis);
    final pauseRefs = _parseReferences(segment.direction.pauses);

    // Identificar rangos de énfasis (negrita)
    List<RangeValues> emphasisRanges = [];
    for (var ref in emphasisRefs) {
      int start = 0;
      while ((start = text.indexOf(ref, start)) != -1) {
        emphasisRanges.add(
          RangeValues(start.toDouble(), (start + ref.length).toDouble()),
        );
        start += ref.length;
      }
    }

    // Identificar puntos de pausa
    List<int> pausePoints = [];
    final punctuationRegex = RegExp(r'[.,;:!?]');
    for (var ref in pauseRefs) {
      int start = 0;
      while ((start = text.indexOf(ref, start)) != -1) {
        int endOfRef = start + ref.length;
        if (endOfRef < text.length &&
            punctuationRegex.hasMatch(text[endOfRef])) {
          pausePoints.add(endOfRef + 1);
        } else {
          pausePoints.add(endOfRef);
        }
        start += ref.length;
      }
    }
    pausePoints = pausePoints.toSet().toList()..sort();

    // Construir los marcadores
    final Set<int> markers = {0, text.length};
    for (var r in emphasisRanges) {
      markers.add(r.start.toInt());
      markers.add(r.end.toInt());
    }
    for (var p in pausePoints) {
      markers.add(p);
    }

    final List<int> sortedMarkers = markers.toList()..sort();
    final List<InlineSpan> spans = [];

    // Lógica de progreso de lectura (simular palabra actual)
    int charsToShow = _currentWordIndex * 10; // Aproximación simple

    for (int i = 0; i < sortedMarkers.length - 1; i++) {
      int start = sortedMarkers[i];
      int end = sortedMarkers[i + 1];

      if (pausePoints.contains(start)) {
        spans.add(_buildPauseIcon());
      }

      if (start < end) {
        String chunk = text.substring(start, end);
        bool isBold = emphasisRanges.any(
          (r) => start >= r.start && end <= r.end,
        );

        // Determinar si este chunk ya fue "leído"
        bool isRead = start < charsToShow;

        final colors = context.appColors;

        Color textColor;
        if (isRead) {
          textColor = isBold
              ? const Color(0xFFFB923C).withValues(alpha: 0.3)
              : (context.isDarkMode ? colors.textPrimary : Colors.white)
                    .withValues(alpha: 0.3);
        } else if (isBold) {
          textColor = const Color(0xFFFB923C);
        } else {
          textColor = context.isDarkMode ? colors.textPrimary : Colors.white;
        }

        spans.add(
          TextSpan(
            text: chunk,
            style: TextStyle(
              fontSize: 20,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
              height: 1.625,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
        );
      }
    }

    if (pausePoints.contains(text.length)) {
      spans.add(_buildPauseIcon());
    }

    return spans;
  }

  WidgetSpan _buildPauseIcon() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.pause_rounded,
          size: 10,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  List<String> _parseReferences(String input) {
    if (input.isEmpty) return [];
    final regex = RegExp(r"'([^']*)'");
    return regex.allMatches(input).map((m) => m.group(1)!).toList();
  }

  bool get _isRecordingActive =>
      _recordingState == RecordingState.recording ||
      _recordingState == RecordingState.commandRecorded;

  void _startCountdown() {
    setState(() {
      _recordingState = RecordingState.countdown;
      _countdownValue = 3;
    });

    // Start first ring animation
    _countdownController.forward(from: 0.0);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() {
          _countdownValue--;
        });
        // Restart ring animation for next number
        _countdownController.forward(from: 0.0);
      } else {
        timer.cancel();
        _startActualRecording();
      }
    });
  }

  void _startActualRecording() {
    setState(() {
      _recordingState = RecordingState.recording;
    });
    _countdownController.stop();

    // Fase 3: Transición automática a comando grabado tras 5 segundos
    Timer(const Duration(seconds: 5), () {
      if (mounted && _recordingState == RecordingState.recording) {
        setState(() {
          _recordingState = RecordingState.commandRecorded;
          _isCommandHeard = false;
        });

        // Fase 4: A los 2 segundos pasar a 'heard'
        Timer(const Duration(seconds: 2), () {
          if (mounted && _recordingState == RecordingState.commandRecorded) {
            setState(() {
              _isCommandHeard = true;
            });

            // Fase 5: 1 segundo después pasar a idle y siguiente fragmento
            Timer(const Duration(seconds: 1), () {
              if (mounted) {
                final isLastSegment =
                    _activeFragmentIndex >= widget.analysis.segments.length - 1;

                setState(() {
                  if (!isLastSegment) {
                    _activeFragmentIndex++;
                    _recordingState = RecordingState.idle;
                  } else {
                    _recordingState = RecordingState.finished;
                  }
                  _isCommandHeard = false;
                });
              }
            });
          }
        });
      }
    });

    // TODO: Trigger actual audio recording
  }

  void _stopRecording() {
    setState(() {
      _recordingState = RecordingState.idle;
    });
    // TODO: Stop camera and save recording
  }

  Widget _buildCountdownOverlay() {
    return Stack(
      children: [
        // Black overlay (60% opacity)
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.6)),
        ),

        // Countdown center
        Center(
          child: SizedBox(
            width: 256,
            height: 256,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                AnimatedBuilder(
                  animation: _countdownProgress,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(256, 256),
                      painter: CountdownRingPainter(
                        progress: _countdownProgress.value,
                      ),
                    );
                  },
                ),

                // Countdown number with glow
                Text(
                  '$_countdownValue',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalFragments = widget.analysis.segments.length;
    final currentFragment = _activeFragmentIndex + 1;
    final isCountingDown = _recordingState == RecordingState.countdown;

    if (_recordingState == RecordingState.finished) {
      return const RecordingEndPage();
    }

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Stack(
        children: [
          // Background layer (z-0)
          _buildBackground(),

          // Grid overlay (z-10)
          _buildGridOverlay(),

          // UI Elements (z-40) with conditional dimming
          AnimatedOpacity(
            opacity: isCountingDown ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(currentFragment, totalFragments),

                  // Script text card
                  _buildScriptCard(),

                  // Spacer
                  const Spacer(),

                  // Bottom controls
                  _buildBottomControls(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // Countdown overlay (shown only during countdown)
          if (isCountingDown) _buildCountdownOverlay(),

          // Menu overlay (z-50)
          _buildMenuOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Background image
          Image.network(
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&h=1200&fit=crop',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: context.colorScheme.surface);
            },
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.2,
          child: GridView.count(
            crossAxisCount: 3,
            children: List.generate(9, (index) {
              final showRight = (index % 3) != 2;
              final showBottom = index < 6;

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: showRight
                        ? BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : BorderSide.none,
                    bottom: showBottom
                        ? BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : BorderSide.none,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(int current, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          _buildGlassButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).pop(),
            isEnabled: !_isRecordingActive,
          ),

          // Fragment counter
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _recordingState == RecordingState.recording
                      ? const Color(0xFFFF3B30).withValues(alpha: 0.9)
                      : (context.isDarkMode
                            ? context.appColors.cardBackground.withValues(
                                alpha: 0.85,
                              )
                            : Colors.black.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _recordingState == RecordingState.recording
                        ? Colors.white.withValues(alpha: 0.2)
                        : (context.isDarkMode
                              ? context.appColors.cardBorder
                              : Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_recordingState == RecordingState.recording) ...[
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha:
                                    0.5 +
                                    (0.5 * (1.4 - _pulseAnimation.value) / 0.4),
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _recordingState == RecordingState.recording
                          ? 'GRABANDO FRAGMENTO $current / $total'
                          : 'FRAGMENTO $current / $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Camera switch button
          _buildGlassButton(
            icon: Icons.cameraswitch,
            onTap: () {
              // TODO: Implement camera switch
            },
            isEnabled: !_isRecordingActive,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isEnabled ? 1.0 : 0.3,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? context.appColors.cardBackground.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.isDarkMode
                        ? context.appColors.cardBorder
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScriptCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? context.colorScheme.surface.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: context.isDarkMode
                    ? context.appColors.cardBorder.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: _buildTextSpans(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.625,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Voice indicator
          _buildVoiceIndicator(),

          const SizedBox(height: 32),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Grid button
              _buildSideButton(
                icon: Icons.grid_view,
                label: 'GRID',
                onTap: () {
                  // TODO: Toggle grid
                },
                isEnabled: !_isRecordingActive,
              ),

              // Record button
              _buildRecordButton(),

              // Menu button
              _buildSideButton(
                icon: Icons.menu,
                label: 'MENÚ',
                onTap: () {
                  setState(() {
                    _recordingState = RecordingState.menu;
                  });
                  _menuController.forward();
                },
                isEnabled: !_isRecordingActive,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? onTap : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isEnabled ? 1.0 : 0.4,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? context.appColors.cardBackground.withValues(
                              alpha: 0.8,
                            )
                          : Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.isDarkMode
                            ? context.appColors.cardBorder
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceIndicator() {
    VoiceIndicatorState indicatorState;

    if (_recordingState == RecordingState.recording) {
      indicatorState = VoiceIndicatorState.disabled;
    } else if (_recordingState == RecordingState.commandRecorded) {
      indicatorState = _isCommandHeard
          ? VoiceIndicatorState.heard
          : VoiceIndicatorState.listening;
    } else {
      indicatorState = VoiceIndicatorState.listening;
    }

    return VRMVoiceIndicator(
      state: indicatorState,
      pulseAnimation: _pulseAnimation,
    );
  }

  void _closeMenu() {
    _menuController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _recordingState = RecordingState.idle;
        });
      }
    });
  }

  Widget _buildMenuOverlay() {
    return AnimatedBuilder(
      animation: _menuController,
      builder: (context, child) {
        if (_menuController.isDismissed &&
            _recordingState != RecordingState.menu) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Backdrop dimming/tap to close
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _menuController.value,
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),
            ),

            // Bottom Menu Sheet
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _menuAnimation,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.48,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(56),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.white10, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 60,
                        spreadRadius: 20,
                        offset: Offset(0, -20),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top handle
                      const SizedBox(height: 16),
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Header with "Cerrar" and status
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _closeMenu,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.expand_more,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'CERRAR',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '64.2 GB',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.battery_5_bar,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Grid of options
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 48,
                            crossAxisSpacing: 24,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildMenuFeature(
                                icon: Icons.grid_view,
                                label: 'GRILLA',
                                isActive: true,
                              ),
                              _buildMenuFeature(
                                icon: Icons.directions_run,
                                label: 'CALLE',
                                isActive: false,
                              ),
                              _buildMenuFeature(
                                icon: Icons.mic,
                                label: 'VOZ',
                                isActive: true,
                              ),
                              _buildMenuFeature(
                                icon: Icons.auto_fix_high,
                                label: 'FILTROS',
                                isActive: false,
                              ),
                              _buildMenuFeature(
                                icon: Icons.lightbulb,
                                label: 'LUCES',
                                isActive: false,
                              ),
                              _buildMenuFeature(
                                icon: Icons.headphones,
                                label: 'AUDÍFONOS',
                                isActive: false,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pagination dots
                      Padding(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ...List.generate(
                              3,
                              (index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuFeature({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final colors = context.appColors;
    final primaryColor = context.colorScheme.primary;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isActive
                ? colors.cardBackground
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? primaryColor : colors.cardBorder,
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: isActive
                ? primaryColor
                : Colors.white.withValues(alpha: 0.9),
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    final isCountingDown = _recordingState == RecordingState.countdown;
    final isRecording = _recordingState == RecordingState.recording;
    final isCommandRecorded = _recordingState == RecordingState.commandRecorded;
    final colors = context.appColors;
    final primaryColor = context.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        if (_recordingState == RecordingState.idle) {
          _startCountdown();
        } else if (_recordingState == RecordingState.recording ||
            _recordingState == RecordingState.commandRecorded) {
          _stopRecording();
        }
      },
      child: SizedBox(
        width: 108,
        height: 108,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer border
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCommandRecorded
                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.5)
                      : (isRecording
                            ? Colors.white.withValues(alpha: 0.2)
                            : (context.isDarkMode
                                  ? colors.cardBorder.withValues(
                                      alpha: isCountingDown ? 0.05 : 0.2,
                                    )
                                  : Colors.white.withValues(alpha: 0.1))),
                  width: isCommandRecorded ? 2 : 1,
                ),
              ),
            ),

            // White circle with shadow
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isCommandRecorded
                    ? primaryColor.withValues(alpha: 0.1)
                    : Colors.white.withValues(
                        alpha: isCountingDown ? 0.2 : 1.0,
                      ),
                shape: BoxShape.circle,
                boxShadow: isCountingDown
                    ? []
                    : [
                        BoxShadow(
                          color: isCommandRecorded
                              ? const Color(0xFF2DD4BF).withValues(alpha: 0.4)
                              : (isRecording
                                    ? const Color(
                                        0xFFFF3B30,
                                      ).withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.3)),
                          blurRadius: isCommandRecorded
                              ? 40
                              : (isRecording ? 20 : 30),
                          spreadRadius: isCommandRecorded ? 10 : 0,
                        ),
                      ],
              ),
            ),

            // Inner circle/square
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isCommandRecorded ? 80 : (isRecording ? 40 : 32),
              height: isCommandRecorded ? 80 : (isRecording ? 40 : 32),
              decoration: BoxDecoration(
                color: isCommandRecorded
                    ? const Color(0xFF2DD4BF)
                    : (isRecording
                          ? const Color(0xFFFF3B30)
                          : (isCountingDown
                                ? (context.isDarkMode
                                          ? colors.cardBackground
                                          : Colors.black)
                                      .withValues(alpha: 0.5)
                                : primaryColor)),
                shape: isCommandRecorded ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCommandRecorded
                    ? null
                    : BorderRadius.circular(isRecording ? 8 : 6),
              ),
              child: isCommandRecorded
                  ? Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCommandRecorded
                              ? const Color(0xFF2D4B44)
                              : (context.isDarkMode
                                    ? colors.cardBackground
                                    : Colors.black),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for countdown ring
class CountdownRingPainter extends CustomPainter {
  final double progress;

  CountdownRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
