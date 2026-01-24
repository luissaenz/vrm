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
                    const SizedBox(height: 16),
                    _buildStatsRow(l10n),
                    const SizedBox(height: 40),
                    // Vista previa eliminada según requerimiento
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "${_scriptController.text.length} ",
                  style: const TextStyle(color: AppTheme.forest),
                ),
                const TextSpan(text: "CARACTERES"),
              ],
            ),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: "APROXIMADAMENTE "),
                    TextSpan(
                      text: "$seconds S",
                      style: const TextStyle(color: AppTheme.forest),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
