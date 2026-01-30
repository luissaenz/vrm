import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/script_editor.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _ideaController = TextEditingController();

  // Using AppTheme colors for consistency

  @override
  void initState() {
    super.initState();
    _ideaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
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
              title: l10n.scriptAssistantTitle,
              onBack: () => Navigator.pop(context),
              icon: Icons.arrow_back_ios_new_rounded,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.defineIdea,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildIdeaInput(l10n),
                    const SizedBox(height: 12),
                    Text(
                      l10n.iaHelperText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.earth,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildStructuresHeader(l10n),
                    const SizedBox(height: 16),
                    _buildStructureCard(
                      icon: Icons.flash_on_rounded,
                      title: l10n.hookTitle,
                      description: l10n.hookDesc,
                      imageUrl:
                          'C:/Users/ld_sa/.gemini/antigravity/brain/a2d98ace-2e64-4e4e-9c9b-fbff12c8d4cb/hook_image_1769278067595.png',
                    ),
                    _buildStructureCard(
                      icon: Icons.segment_rounded,
                      title: l10n.valueTitle,
                      description: l10n.valueDesc,
                      imageUrl:
                          'C:/Users/ld_sa/.gemini/antigravity/brain/a2d98ace-2e64-4e4e-9c9b-fbff12c8d4cb/value_development_v2_1769278166639.png',
                    ),
                    _buildStructureCard(
                      icon: Icons.ads_click_rounded,
                      title: l10n.ctaTitle,
                      description: l10n.ctaDesc,
                      imageUrl:
                          'C:/Users/ld_sa/.gemini/antigravity/brain/a2d98ace-2e64-4e4e-9c9b-fbff12c8d4cb/cta_image_1769278096023.png',
                    ),
                    const SizedBox(height: 140), // Space for bottom button
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
        child: ElevatedButton(
          onPressed: _ideaController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context),
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
              const Icon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 12),
              Text(
                l10n.generateFullScript.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdeaInput(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l10n.videoIdeaLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.earth,
              letterSpacing: 0.5,
            ),
          ),
        ),
        VRMScriptEditor(
          controller: _ideaController,
          hintText: l10n.videoIdeaPlaceholder,
          maxLines: 5,
          actions: [
            VRMScriptEditor.actionButton(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  _ideaController.text = data!.text!;
                }
              },
              icon: Icons.paste_outlined,
              label: "Pegar",
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            VRMScriptEditor.actionIcon(
              onPressed: () {},
              icon: Icons.file_upload_outlined,
            ),
            VRMScriptEditor.actionIcon(
              onPressed: () {},
              icon: Icons.mic_none_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStructuresHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.suggestedStructures,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.forestDark,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.forestVibrant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            l10n.premiumAi,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.forestVibrant,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStructureCard({
    required IconData icon,
    required String title,
    required String description,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.earth.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppTheme.forestVibrant),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.earth,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 96, // 24 * 4
            height: 64, // 16 * 4
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.earth.withValues(alpha: 0.05)),
              image: DecorationImage(
                image: imageUrl.startsWith('http')
                    ? NetworkImage(imageUrl) as ImageProvider
                    : FileImage(File(imageUrl)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
