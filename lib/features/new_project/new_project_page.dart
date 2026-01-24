import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
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
                  // TODO: Proceed to split
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _scriptController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '...',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white, // Fondo blanco puro
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                _buildToolbarButton(
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _scriptController.text = data!.text!;
                    }
                  },
                  icon: Icons.paste_outlined,
                  label: l10n.paste,
                ),
                const SizedBox(width: 8), // Espacio reducido entre botones
                _buildToolbarIcon(
                  onPressed: () {},
                  icon: Icons.file_upload_outlined,
                ),
                const SizedBox(width: 8), // Espacio reducido entre botones
                _buildToolbarIcon(
                  onPressed: () {},
                  icon: Icons.mic_none_outlined,
                ),
                const Spacer(),
                _buildActionButton(
                  onPressed: () {},
                  icon: Icons.auto_awesome,
                  label: l10n.assistant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // Gris muy claro para el botón Pegar
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF2A4844)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2A4844),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarIcon({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.transparent, // Fondo transparente
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF2A4844)),
      ),
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

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF2A4844)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2A4844),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
