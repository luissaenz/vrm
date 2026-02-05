import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widget_estimation.dart';
import '../new_project/models/script_analysis.dart';

class DirectorsCardPage extends StatefulWidget {
  final ScriptAnalysis analysis;
  final int initialIndex;

  const DirectorsCardPage({
    super.key,
    required this.analysis,
    required this.initialIndex,
  });

  @override
  State<DirectorsCardPage> createState() => _DirectorsCardPageState();
}

class _DirectorsCardPageState extends State<DirectorsCardPage> {
  late int _currentIndex;

  ScriptSegment get _currentSegment => widget.analysis.segments[_currentIndex];
  int get _totalSegments => widget.analysis.segments.length;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildFragmentInfo(l10n),
              const SizedBox(height: 24),
              _buildIntentionCard(),
              const SizedBox(height: 16),
              _buildScriptPreviewCard(),
              _buildScriptPreviewLegend(),
              const SizedBox(height: 32),
              Estimation(
                speedPpm: _currentSegment.editMetadata.wpm,
                durationSeconds: _currentSegment.editMetadata.durationSeconds,
                tolerance: 0,
              ),
              const SizedBox(height: 48),
              _buildNavigationButtons(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCircularButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.pop(context),
        ),
        Text(
          "FRAGMENT DETAIL",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: const Color(0xFF94A3B8), // slate 400
          ),
        ),
        const SizedBox(width: 40), // Espacio equilibrado
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF1F5F9)), // slate 100
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF475569),
          size: 24,
        ), // slate 600
      ),
    );
  }

  Widget _buildFragmentInfo(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Fragmento ${_currentIndex + 1} / $_totalSegments",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8), // slate 400
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getTypeColor(_currentSegment.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            _currentSegment.type.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: _getTypeColor(_currentSegment.type),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntentionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "INTENCIÓN:",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: AppTheme.earth,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.psychology_alt_rounded,
                color: AppTheme.forest,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _currentSegment.direction.tone,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScriptPreviewCard() {
    final text = _currentSegment.text;
    final emphasisRefs = _parseReferences(_currentSegment.direction.emphasis);
    final pauseRefs = _parseReferences(_currentSegment.direction.pauses);

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
        // Si inmediatamente después hay puntuación, la pausa va después del signo
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

    // Construir los spans usando marcadores
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

    for (int i = 0; i < sortedMarkers.length - 1; i++) {
      int start = sortedMarkers[i];
      int end = sortedMarkers[i + 1];

      // El ícono de pausa va antes del siguiente bloque de texto
      if (pausePoints.contains(start)) {
        spans.add(_buildPauseIcon());
      }

      if (start < end) {
        String chunk = text.substring(start, end);
        bool isBold = emphasisRanges.any(
          (r) => start >= r.start && end <= r.end,
        );

        spans.add(
          TextSpan(
            text: chunk,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFFC2410C) : const Color(0xFF475569),
            ),
          ),
        );
      }
    }

    // Verificar pausa al final
    if (pausePoints.contains(text.length)) {
      spans.add(_buildPauseIcon());
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 18, height: 1.6),
          children: spans,
        ),
      ),
    );
  }

  WidgetSpan _buildPauseIcon() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // slate 100
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.pause_rounded,
          size: 16,
          color: const Color(0xFF94A3B8), // slate 400
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final bool hasPrevious = _currentIndex > 0;
    final bool hasNext = _currentIndex < _totalSegments - 1;

    return Row(
      children: [
        Expanded(
          child: _buildNavButton(
            label: "ANTERIOR",
            icon: Icons.chevron_left_rounded,
            onTap: hasPrevious
                ? () {
                    setState(() {
                      _currentIndex--;
                    });
                  }
                : null,
            isSecondary: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildNavButton(
            label: hasNext ? "SIGUIENTE" : "FINALIZAR",
            icon: hasNext ? Icons.chevron_right_rounded : Icons.check_rounded,
            onTap: () {
              if (hasNext) {
                setState(() {
                  _currentIndex++;
                });
              } else {
                Navigator.pop(context);
              }
            },
            isSecondary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isSecondary,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isSecondary ? Colors.transparent : AppTheme.forestDark,
        borderRadius: BorderRadius.circular(16),
        border: isSecondary ? Border.all(color: const Color(0xFFE2E8F0)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: onTap == null ? 0.4 : 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSecondary) Icon(icon, color: const Color(0xFF475569)),
                if (isSecondary) const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isSecondary ? const Color(0xFF475569) : Colors.white,
                  ),
                ),
                if (!isSecondary) const SizedBox(width: 8),
                if (!isSecondary) Icon(icon, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hook':
        return Colors.blue.shade600;
      case 'development':
      case 'context':
        return Colors.purple.shade600;
      case 'cta':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  List<String> _parseReferences(String input) {
    if (input.isEmpty) return [];
    final regex = RegExp(r"'([^']*)'");
    return regex.allMatches(input).map((m) => m.group(1)!).toList();
  }

  Widget _buildScriptPreviewLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 12),
      child: Row(
        children: [
          // Acentuar entonación
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFC2410C),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "Acentuar entonación",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B), // slate 500
            ),
          ),
          const SizedBox(width: 24),
          // Pequeña pausa
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9), // slate 100
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pause_rounded,
              size: 10,
              color: Color(0xFF94A3B8), // slate 400
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "Pequeña pausa",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
