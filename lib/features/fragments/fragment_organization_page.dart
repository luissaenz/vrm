import 'package:flutter/material.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
import '../preparation/preparation_page.dart';
import '../../l10n/app_localizations.dart';

class Fragment {
  final String id;
  final String number;
  final String timeRange;
  final String content;

  Fragment({
    required this.id,
    required this.number,
    required this.timeRange,
    required this.content,
  });
}

class FragmentOrganizationPage extends StatefulWidget {
  const FragmentOrganizationPage({super.key});

  @override
  State<FragmentOrganizationPage> createState() =>
      _FragmentOrganizationPageState();
}

class _FragmentOrganizationPageState extends State<FragmentOrganizationPage> {
  final List<Fragment> _hookFragments = [
    Fragment(
      id: 'h1',
      number: '01',
      timeRange: '00:00 - 00:07',
      content:
          '¿Alguna vez has sentido que tus videos no conectan? El problema no es tu cámara...',
    ),
  ];

  final List<Fragment> _valueFragments = [
    Fragment(
      id: 'v1',
      number: '02',
      timeRange: '00:07 - 00:15',
      content:
          'Punto 1: Define un solo objetivo por video para no confundir a tu audiencia.',
    ),
    Fragment(
      id: 'v2',
      number: '03',
      timeRange: '00:15 - 00:23',
      content:
          'Punto 2: Usa subtítulos dinámicos para mantener la atención visual constante.',
    ),
    Fragment(
      id: 'v3',
      number: '04',
      timeRange: '00:23 - 00:30',
      content:
          'Punto 3: Ilumina tu rostro desde el frente para crear una conexión más humana.',
    ),
  ];

  final List<Fragment> _ctaFragments = [
    Fragment(
      id: 'c1',
      number: '05',
      timeRange: '00:30 - 00:37',
      content:
          "Si quieres más tips para creadores, dale al botón de seguir y comenta 'GUION'.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                      duration: "7.2S",
                    ),
                    _buildReorderableList(_hookFragments),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      icon: Icons.segment_rounded,
                      title: l10n.valueTitle,
                      duration: "22.5S",
                    ),
                    _buildReorderableList(_valueFragments),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      icon: Icons.ads_click_rounded,
                      title: l10n.ctaTitle,
                      duration: "6.8S",
                    ),
                    _buildReorderableList(_ctaFragments),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        color: const Color(0xFFF9FAFB),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PreparationPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A4844),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
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

  Widget _buildReorderableList(List<Fragment> fragments) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fragments.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = fragments.removeAt(oldIndex);
          fragments.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final fragment = fragments[index];
        return _buildFragmentCard(
          key: ValueKey(fragment.id),
          index: index,
          number: fragment.number,
          timeRange: fragment.timeRange,
          content: fragment.content,
        );
      },
      buildDefaultDragHandles:
          false, // Quita las líneas de arrastre automáticas
      proxyDecorator: (widget, index, animation) {
        return Material(color: Colors.transparent, child: widget);
      },
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
          Icon(icon, size: 18, color: const Color(0xFF111827)),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              duration,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                  color: Color(0xFF374151),
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
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"$content"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ReorderableDragStartListener(
            index: index,
            child: const Icon(
              Icons.grid_view_rounded,
              color: Color(0xFFD1D5DB),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
