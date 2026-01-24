import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
import '../../shared/widgets/script_editor.dart';
import '../assistant/assistant_page.dart';
import '../fragments/fragment_organization_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';

class NewProjectPage extends StatefulWidget {
  const NewProjectPage({super.key});

  @override
  State<NewProjectPage> createState() => _NewProjectPageState();
}

class _NewProjectPageState extends State<NewProjectPage> {
  final TextEditingController _scriptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scriptController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scriptController.dispose();
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
              title: l10n.newProjectTitle,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VRMStepIndicator(stepNumber: '1', title: l10n.step1Title),
                    const SizedBox(height: 20),
                    _buildScriptInput(l10n),
                    const SizedBox(height: 20),
                    _buildStatsRow(l10n),
                    const SizedBox(height: 40),
                    _buildPreviewHeader(l10n),
                    const SizedBox(height: 16),
                    _buildFragmentsPreview(l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
          onPressed: _scriptController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FragmentOrganizationPage(),
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
              const Icon(Icons.content_cut, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.splitIntoFragments.toUpperCase(),
                style: const TextStyle(
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

  Widget _buildScriptInput(AppLocalizations l10n) {
    return VRMScriptEditor(
      controller: _scriptController,
      hintText:
          'Pega o escribe aquí tu guion para dividirlo en fragmentos de grabación...',
      actions: [
        VRMScriptEditor.actionButton(
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) {
              _scriptController.text = data!.text!;
            }
          },
          icon: Icons.paste_outlined,
          label: "Pegar",
          backgroundColor: const Color(
            0xFFF1F5F9,
          ), // Gris azulado muy claro (Slate 100)
          foregroundColor: const Color(0xFF64748B), // Gris medio (Slate 500)
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
      trailing: VRMScriptEditor.actionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssistantPage()),
          );
        },
        icon: Icons.auto_awesome,
        label: "Optimizar",
        foregroundColor: AppTheme.forest,
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    final words = _scriptController.text
        .split(' ')
        .where((s) => s.isNotEmpty)
        .length;
    final seconds = (words / 2.5).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        "${_scriptController.text.length} caracteres • ~$seconds s total"
            .toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8), // Slate 400
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "VISTA PREVIA DE FRAGMENTOS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.earth,
              letterSpacing: 1.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.forest.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              "3 BLOQUES",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.forest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFragmentsPreview(AppLocalizations l10n) {
    return Column(
      children: [
        _buildFragmentItem(
          "01",
          "00:00 - 00:08",
          "8s",
          "En este video te voy a mostrar cómo configurar tu espacio de trabajo para ser más productivo.",
        ),
        const SizedBox(height: 12),
        _buildFragmentItem(
          "02",
          "00:08 - 00:15",
          "7s",
          "Primero, hablemos de la iluminación natural. Luego, pasaremos a la organización del escritorio...",
        ),
        const SizedBox(height: 12),
        _buildFragmentItem(
          "03",
          "00:15 - 00:22",
          "7s",
          "...y por último, la importancia de las pausas activas.",
        ),
      ],
    );
  }

  Widget _buildFragmentItem(
    String number,
    String time,
    String duration,
    String content,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forest,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forest,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "($duration)",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.forest.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.drag_indicator,
                      color: Color(0xFFCBD5E1),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "\"$content\"",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569), // Slate 600
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
