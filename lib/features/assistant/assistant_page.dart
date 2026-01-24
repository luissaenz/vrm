import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/script_editor.dart';
import '../../l10n/app_localizations.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _ideaController = TextEditingController();

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
      backgroundColor: const Color(0xFFF9FAFB),
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      l10n.defineIdea,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildIdeaInput(l10n),
                    const SizedBox(height: 12),
                    Text(
                      l10n.iaHelperText,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildStructuresHeader(l10n),
                    const SizedBox(height: 16),
                    _buildStructureCard(
                      icon: Icons.electric_bolt_rounded,
                      iconColor: Colors.green,
                      title: l10n.hookTitle,
                      description: l10n.hookDesc,
                      imageUrl:
                          'C:/Users/ld_sa/.gemini/antigravity/brain/a2d98ace-2e64-4e4e-9c9b-fbff12c8d4cb/hook_image_1769278067595.png',
                    ),
                    _buildStructureCard(
                      icon: Icons.segment_rounded,
                      iconColor: Colors.green[300]!,
                      title: l10n.valueTitle,
                      description: l10n.valueDesc,
                      imageUrl:
                          'C:/Users/ld_sa/.gemini/antigravity/brain/a2d98ace-2e64-4e4e-9c9b-fbff12c8d4cb/value_development_v2_1769278166639.png',
                    ),
                    _buildStructureCard(
                      icon: Icons.ads_click_rounded,
                      iconColor: Colors.green[400]!,
                      title: l10n.ctaTitle,
                      description: l10n.ctaDesc,
                      imageUrl:
                          'C:/Users/ld_sa/.gemini/antigravity/brain/a2d98ace-2e64-4e4e-9c9b-fbff12c8d4cb/cta_image_1769278096023.png',
                    ),
                    const SizedBox(height: 120), // Space for bottom button
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
            ElevatedButton.icon(
              onPressed: _ideaController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context), // Volver para llenar el guion
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: Text(l10n.generateFullScript),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2421),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaInput(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.videoIdeaLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500, // No negrita
            color: Colors.grey[400],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        VRMScriptEditor(
          controller: _ideaController,
          hintText: l10n.videoIdeaPlaceholder,
          maxLines: 4,
          actions: [
            VRMScriptEditor.actionButton(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  _ideaController.text = data!.text!;
                }
              },
              icon: Icons.paste_outlined,
              label: l10n.paste,
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
            fontSize: 15, // Más pequeño
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n.premiumAi,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10B981),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStructureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12), // Reducido de 16 a 12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
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
                    Icon(icon, size: 16, color: iconColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 70, // Ligeramente más pequeño
            height: 52, // Ligeramente más pequeño
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
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
