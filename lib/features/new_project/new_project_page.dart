import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
import '../../shared/widgets/script_editor.dart';
import '../assistant/assistant_page.dart';
import '../fragments/fragment_organization_page.dart';
import '../../l10n/app_localizations.dart';

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
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            VRMHeader(
              title: l10n.newProjectTitle,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    VRMStepIndicator(stepNumber: '1', title: l10n.step1Title),
                    const SizedBox(height: 20),
                    _buildScriptInput(l10n),
                    const SizedBox(height: 16),
                    _buildActionButtons(l10n),
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
        child: ElevatedButton.icon(
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
          icon: const Icon(Icons.auto_awesome_mosaic_outlined, size: 20),
          label: Text(l10n.splitIntoFragments),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A4844),
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScriptInput(AppLocalizations l10n) {
    return VRMScriptEditor(
      controller: _scriptController,
      hintText: '...',
      actions: [
        VRMScriptEditor.actionButton(
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) {
              _scriptController.text = data!.text!;
            }
          },
          icon: Icons.paste_outlined,
          label: l10n.paste,
        ),
        VRMScriptEditor.actionIcon(
          onPressed: () {},
          icon: Icons.file_upload_outlined,
        ),
        VRMScriptEditor.actionIcon(
          onPressed: () {},
          icon: Icons.mic_none_outlined,
        ),
        VRMScriptEditor.actionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssistantPage()),
            );
          },
          icon: Icons.auto_awesome,
          label: l10n.assistant,
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.charactersCount(_scriptController.text.length.toString()),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[400],
            fontFamily: 'monospace',
          ),
        ),
        Text(
          l10n.totalTimeEstimate(
            l10n.secondsAbbreviation(
              (_scriptController.text
                          .split(' ')
                          .where((s) => s.isNotEmpty)
                          .length /
                      2.5)
                  .toStringAsFixed(1),
            ),
          ),
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      ],
    );
  }
}
