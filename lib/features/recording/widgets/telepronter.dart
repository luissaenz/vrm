import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/theme.dart';
import '../../new_project/models/script_analysis.dart';

class Telepronter extends StatelessWidget {
  final ScriptAnalysis analysis;
  final int activeFragmentIndex;
  final int currentWordIndex;

  const Telepronter({
    super.key,
    required this.analysis,
    required this.activeFragmentIndex,
    this.currentWordIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
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
                children: _buildTextSpans(context),
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

  List<InlineSpan> _buildTextSpans(BuildContext context) {
    final segment = analysis.segments[activeFragmentIndex];
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
    int charsToShow = currentWordIndex * 10; // Aproximación simple

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
}
