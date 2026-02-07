import 'package:flutter/material.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
import '../preparation/directors_card_page.dart';
import '../recording/recording_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';

import '../new_project/models/script_analysis.dart';

class Fragment {
  final String id;
  final String number;
  final double duration;
  final String content;

  final ScriptSegment? segment;

  Fragment({
    required this.id,
    required this.number,
    required this.duration,
    required this.content,
    this.segment,
  });

  String get timeRange => "Duración: ${duration.toStringAsFixed(1)}s";
}

class FragmentOrganizationPage extends StatefulWidget {
  final ScriptAnalysis? analysis;
  const FragmentOrganizationPage({super.key, this.analysis});

  @override
  State<FragmentOrganizationPage> createState() =>
      _FragmentOrganizationPageState();
}

class _FragmentOrganizationPageState extends State<FragmentOrganizationPage> {
  final List<Fragment> _hookFragments = [];
  final List<Fragment> _valueFragments = [];
  final List<Fragment> _ctaFragments = [];

  @override
  void initState() {
    super.initState();
    if (widget.analysis != null) {
      _loadFromAnalysis(widget.analysis!);
    } else {
      _loadHardcodedData();
    }
  }

  void _loadFromAnalysis(ScriptAnalysis analysis) {
    for (var segment in analysis.segments) {
      final fragment = Fragment(
        id: segment.id.toString(),
        number: segment.id.toString().padLeft(2, '0'),
        duration: segment.editMetadata.durationSeconds,
        content: segment.text,
        segment: segment,
      );

      if (segment.type == 'hook') {
        _hookFragments.add(fragment);
      } else if (segment.type == 'development' || segment.type == 'context') {
        _valueFragments.add(fragment);
      } else {
        _ctaFragments.add(fragment);
      }
    }
  }

  String _getSectionTotal(List<Fragment> fragments) {
    final total = fragments.fold<double>(0, (sum, f) => sum + f.duration);
    return "${total.toStringAsFixed(1)}S";
  }

  void _loadHardcodedData() {
    _hookFragments.add(
      Fragment(
        id: 'h1',
        number: '01',
        duration: 7.2,
        content:
            '¿Alguna vez has sentido que tus videos no conectan? El problema no es tu cámara...',
      ),
    );

    _valueFragments.addAll([
      Fragment(
        id: 'v1',
        number: '02',
        duration: 8.0,
        content:
            'Punto 1: Define un solo objetivo por video para no confundir a tu audiencia.',
      ),
      Fragment(
        id: 'v2',
        number: '03',
        duration: 7.5,
        content:
            'Punto 2: Usa subtítulos dinámicos para mantener la atención visual constante.',
      ),
      Fragment(
        id: 'v3',
        number: '04',
        duration: 7.0,
        content:
            'Punto 3: Ilumina tu rostro desde el frente para crear una conexión más humana.',
      ),
    ]);

    _ctaFragments.add(
      Fragment(
        id: 'c1',
        number: '05',
        duration: 6.8,
        content:
            "Si quieres más tips para creadores, dale al botón de seguir y comenta 'GUION'.",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            VRMHeader(
              title: l10n.newProjectTitle,
              onBack: () => Navigator.pop(context),
              icon: Icons.arrow_back_ios_new_rounded,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    VRMStepIndicator(stepNumber: "2", title: l10n.step2Title),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      icon: Icons.electric_bolt_rounded,
                      title: l10n.hookTitle,
                      duration: _getSectionTotal(_hookFragments),
                    ),
                    _buildFixedList(_hookFragments),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      icon: Icons.segment_rounded,
                      title: l10n.valueTitle,
                      duration: _getSectionTotal(_valueFragments),
                    ),
                    _buildFixedList(_valueFragments),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      icon: Icons.ads_click_rounded,
                      title: l10n.ctaTitle,
                      duration: _getSectionTotal(_ctaFragments),
                    ),
                    _buildFixedList(_ctaFragments),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              context.colorScheme.surface,
              context.colorScheme.surface.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                if (widget.analysis == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RecordingPage(analysis: widget.analysis!),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDarkMode
                    ? context.appColors.forestVibrant
                    : context.appColors.forestDark,
                foregroundColor: context.isDarkMode
                    ? context.appColors.offWhite
                    : Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: context.isDarkMode ? 0 : 8,
                shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.next.toUpperCase(),
                    style: const TextStyle(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedList(List<Fragment> fragments) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(fragments.length, (index) {
        final fragment = fragments[index];
        return _buildFragmentCard(
          key: ValueKey(fragment.id),
          fragment: fragment,
          index: index,
        );
      }),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String duration,
  }) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textPrimary),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 14,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFragmentCard({
    required Key key,
    required Fragment fragment,
    required int index,
  }) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (widget.analysis != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DirectorsCardPage(
                  analysis: widget.analysis!,
                  initialIndex: index,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.earthLight.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    fragment.number,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fragment.timeRange,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${fragment.content}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
