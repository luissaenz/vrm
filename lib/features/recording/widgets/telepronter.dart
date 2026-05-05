import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/theme.dart';
import '../../new_project/models/script_analysis.dart';

class Telepronter extends StatefulWidget {
  final ScriptAnalysis analysis;
  final int activeFragmentIndex;
  final int currentWordIndex;
  final double fontSize;
  final double readingSpeed; // Palabras Por Minuto (PPM)
  final bool isScrolling;

  const Telepronter({
    super.key,
    required this.analysis,
    required this.activeFragmentIndex,
    this.currentWordIndex = 0,
    this.fontSize = 24.0,
    this.readingSpeed = 180.0,
    this.isScrolling = false,
  });

  @override
  State<Telepronter> createState() => _TelepronterState();
}

class _TelepronterState extends State<Telepronter> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.isScrolling) {
      _startScrolling();
    }
  }

  @override
  void didUpdateWidget(Telepronter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScrolling != oldWidget.isScrolling) {
      if (widget.isScrolling) {
        _startScrolling();
      } else {
        _scrollTimer?.cancel();
      }
    }
    if (widget.activeFragmentIndex != oldWidget.activeFragmentIndex) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !widget.isScrolling) {
        timer.cancel();
        return;
      }

      if (_scrollController.hasClients) {
        // SUPUESTO: Estimamos el avance de píxeles basado en PPM.
        // A 180 PPM (3 palabras/seg), el scroll debe ser fluido.
        // Factor 0.45 ajustado empíricamente para fontSize estándar.
        final pixelsPerSecond =
            (widget.readingSpeed / 60.0) * (widget.fontSize * 0.45);
        final delta = pixelsPerSecond * 0.05; // tick de 50ms

        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        if (currentScroll < maxScroll) {
          _scrollController.animateTo(
            currentScroll + delta,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
          ), // Optimizado para performance
          child: Container(
            height: 200, // Altura fija para permitir el scroll interno
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  (context.isDarkMode
                          ? context.colorScheme.surface
                          : Colors.black)
                      .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: context.isDarkMode
                    ? context.appColors.cardBorder.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics:
                  const NeverScrollableScrollPhysics(), // Controlamos el scroll por Timer
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: _buildTextSpans(context),
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.625,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(BuildContext context) {
    final segment = widget.analysis.segments[widget.activeFragmentIndex];
    final text = segment.text;
    final emphasisRefs = _parseReferences(segment.direction.emphasis);
    final pauseRefs = _parseReferences(segment.direction.pauses);

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

    int charsToShow = widget.currentWordIndex * 10;

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
}
