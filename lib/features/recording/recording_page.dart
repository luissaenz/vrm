import 'package:flutter/material.dart';
import 'dart:ui';
import '../new_project/models/script_analysis.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isRecording = false;
  int _currentWordIndex = 0;

  // Theme colors from HTML
  static const Color _forestGreen = Color(0xFF2D4B44);
  static const Color _forestAccent = Color(0xFF2DD4BF);
  static const Color _backgroundDark = Color(0xFF0A0A0A);

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _currentSegmentText {
    if (widget.currentFragmentIndex < widget.analysis.segments.length) {
      return widget.analysis.segments[widget.currentFragmentIndex].text;
    }
    return "Hola a todos, hoy vamos a ver lo increíble que es esto para crear contenido rápido.";
  }

  List<InlineSpan> _buildTextSpans() {
    final segment = widget.analysis.segments[widget.currentFragmentIndex];
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
        bool isCurrent = start <= charsToShow && charsToShow < end;

        Color textColor;
        if (isRead) {
          textColor = Colors.white.withValues(alpha: 0.4);
        } else if (isCurrent) {
          textColor = Colors.white;
        } else {
          textColor = Colors.white;
        }

        spans.add(
          TextSpan(
            text: chunk,
            style: TextStyle(
              fontSize: 20,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              height: 1.625,
              letterSpacing: -0.5,
              color: textColor,
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
        width: 20,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.pause_rounded,
          size: 12,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  List<String> _parseReferences(String input) {
    if (input.isEmpty) return [];
    final regex = RegExp(r"'([^']*)'");
    return regex.allMatches(input).map((m) => m.group(1)!).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalFragments = widget.analysis.segments.length;
    final currentFragment = widget.currentFragmentIndex + 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background layer (z-0)
          _buildBackground(),

          // Grid overlay (z-10)
          _buildGridOverlay(),

          // UI Elements (z-40)
          SafeArea(
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
              return Container(color: _backgroundDark);
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
          ),

          // Fragment counter
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'FRAGMENTO $current / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
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
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
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
              ),

              // Record button
              _buildRecordButton(),

              // Menu button
              _buildSideButton(
                icon: Icons.menu,
                label: 'MENÚ',
                onTap: () {
                  // TODO: Open menu
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceIndicator() {
    // Darker green for the dot
    const Color dotColor = Color(0xFF1FA88A);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing dot with fixed size to prevent layout shifts
        SizedBox(
          width: 9, // 6 * 1.4 = 8.4, rounded up
          height: 9,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse
                  Container(
                    width: 6 * _pulseAnimation.value,
                    height: 6 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      color: dotColor.withValues(
                        alpha: 1.0 - (_pulseAnimation.value - 1.0),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Inner dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(width: 12),

        // "Escuchando" text with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Text(
              'ESCUCHANDO',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha:
                      1.0 -
                      ((_pulseAnimation.value - 1.0) * 0.75), // 1.0 to 0.7
                ),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
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
                onTap: onTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
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

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isRecording = !_isRecording;
        });
      },
      child: SizedBox(
        width: 108, // 96 + 12 (6px on each side)
        height: 108,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),

            // White circle with shadow
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),

            // Inner square/circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _forestGreen,
                borderRadius: BorderRadius.circular(_isRecording ? 4 : 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
