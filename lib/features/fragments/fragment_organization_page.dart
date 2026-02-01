import 'package:flutter/material.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
import '../preparation/directors_card_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';

import '../new_project/models/script_analysis.dart';

class Fragment {
  final String id;
  final String number;
  final double duration;
  final String content;

  Fragment({
    required this.id,
    required this.number,
    required this.duration,
    required this.content,
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
      backgroundColor: AppTheme.backgroundLight,
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppTheme.backgroundLight,
              AppTheme.backgroundLight.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DirectorsCardPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppTheme.forest.withValues(alpha: 0.3),
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
          index: index,
          number: fragment.number,
          timeRange: fragment.timeRange,
          content: fragment.content,
        );
      }),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String duration,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMain),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.speed_rounded,
                  size: 14,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 6),
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
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
    required int index,
    required String number,
    required String timeRange,
    required String content,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
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
                  timeRange,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"$content"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
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
    );
  }
}
