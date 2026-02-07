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
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              context.colorScheme.surface,
              context.colorScheme.surface.withValues(alpha: 0.0),
            ],
            stops: const [0.6, 1.0],
          ),
        ),
        child: _buildNavigationButtons(),
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
            fontWeight: FontWeight.w800,
            letterSpacing: 4.0,
            color: context.appColors.textSecondary,
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
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            if (context.isDarkMode)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Icon(icon, color: colors.textPrimary, size: 24),
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
            fontWeight: FontWeight.w600,
            color: context.appColors.textSecondary,
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
    final colors = context.appColors;
    final primaryColor = context.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          if (context.isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          else
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
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.psychology_alt_rounded, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                _currentSegment.direction.tone,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
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

    final colors = context.appColors;
    final isDark = context.isDarkMode;

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
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
              color: isBold
                  ? (isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C))
                  : colors.textPrimary,
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
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 18,
            height: 1.6,
            color: colors.textPrimary,
          ),
          children: spans,
        ),
      ),
    );
  }

  WidgetSpan _buildPauseIcon() {
    final colors = context.appColors;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: colors.earthLight.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.pause_rounded, size: 16, color: colors.textSecondary),
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
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isSecondary
            ? Colors.transparent
            : (isDark ? colors.forestVibrant : context.colorScheme.primary),
        borderRadius: BorderRadius.circular(16),
        border: isSecondary ? Border.all(color: colors.cardBorder) : null,
        boxShadow: !isSecondary && !isDark
            ? [
                BoxShadow(
                  color: context.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: onTap == null ? 0.3 : 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSecondary) Icon(icon, color: colors.textPrimary),
                if (isSecondary) const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isSecondary
                        ? colors.textPrimary
                        : (isDark ? colors.offWhite : Colors.white),
                  ),
                ),
                if (!isSecondary) const SizedBox(width: 8),
                if (!isSecondary)
                  Icon(icon, color: (isDark ? colors.offWhite : Colors.white)),
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
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 12),
      child: Row(
        children: [
          // Acentuar entonación
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Acentuar entonación",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 24),
          // Pequeña pausa
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.earthLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pause_rounded,
              size: 10,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Pequeña pausa",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
