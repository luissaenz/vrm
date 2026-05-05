import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../new_project/models/script_analysis.dart';

/// Widget que muestra la superposición de revisión con información del fragmento.
class ReviewOverlay extends StatelessWidget {
  final ScriptAnalysis analysis;
  final int currentFragmentIndex;
  final dynamic recordingManager;

  const ReviewOverlay({
    super.key,
    required this.analysis,
    required this.currentFragmentIndex,
    required this.recordingManager,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalFragments = analysis.segments.length;
    final currentFragment = currentFragmentIndex + 1;
    final scriptText = analysis.segments[currentFragmentIndex].text;

    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.fragmentDisplay(
                      currentFragment.toString(),
                      totalFragments.toString(),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '${l10n.takeLabel} ${recordingManager.sessionData.takesPerChunk[currentFragmentIndex]?.total ?? 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),

              const Spacer(),

              // Script text
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: Text(
                  scriptText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
