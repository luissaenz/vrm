import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

class DirectorsCardPage extends StatefulWidget {
  const DirectorsCardPage({super.key});

  @override
  State<DirectorsCardPage> createState() => _DirectorsCardPageState();
}

class _DirectorsCardPageState extends State<DirectorsCardPage> {
  final TextEditingController _scriptController = TextEditingController(
    text:
        'Y el posicionamiento genera confianza. [pausa] Ahora, el tercer pilar es el que paga las cuentas: Venta. [pausa] Acá el contenido no vende en el post.',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildFragmentInfo(l10n),
              const SizedBox(height: 24),
              _buildIntentionCard(),
              const SizedBox(height: 16),
              _buildScriptPreviewCard(),
              const SizedBox(height: 32),
              _buildEditorSection(l10n),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 40),
              _buildListenButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCircularButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.pop(context),
        ),
        Text(
          "DIRECTOR'S CARD",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: const Color(0xFF94A3B8), // slate 400
          ),
        ),
        _buildCircularButton(icon: Icons.more_horiz_rounded, onTap: () {}),
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF1F5F9)), // slate 100
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF475569),
          size: 24,
        ), // slate 600
      ),
    );
  }

  Widget _buildFragmentInfo(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Fragmento 5 / 12",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8), // slate 400
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            "DESARROLLO",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.blue.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntentionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "INTENCIÓN:",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: AppTheme.earth,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.psychology_alt_rounded,
                color: AppTheme.forest,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                "Persuasivo y práctico",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.forest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScriptPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 18,
            height: 1.6,
            color: const Color(0xFF475569), // slate 600
          ),
          children: [
            const TextSpan(text: 'Y el posicionamiento genera '),
            const TextSpan(
              text: 'confianza',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.forest,
              ),
            ),
            const TextSpan(text: '. '),
            _buildPauseIcon(),
            const TextSpan(text: ' Ahora, el tercer pilar es el que '),
            const TextSpan(
              text: 'paga las cuentas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.forest,
              ),
            ),
            const TextSpan(text: ': Venta. '),
            _buildPauseIcon(),
            const TextSpan(text: ' Acá el contenido '),
            const TextSpan(
              text: 'no vende en el post',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.forest,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  WidgetSpan _buildPauseIcon() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // slate 100
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.pause_rounded,
          size: 14,
          color: const Color(0xFF94A3B8), // slate 400
        ),
      ),
    );
  }

  Widget _buildEditorSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "EDICIÓN DE GUION",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: const Color(0xFF94A3B8), // slate 400
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)), // slate 100
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: TextField(
                  controller: _scriptController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: const Color(0xFF475569), // slate 600
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                alignment: Alignment.centerRight,
                child: Text(
                  "TELEPROMPTER VIEW",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: const Color(0xFFCBD5E1), // slate 300
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatBadge(Icons.schedule_rounded, "7.5s"),
        const SizedBox(width: 8),
        _buildStatBadge(Icons.speed_rounded, "160 ppm"),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.5), // slate 100
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
        ), // slate 200
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF475569)), // slate 600
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569), // slate 600
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListenButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 2,
        ), // slate 100
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volume_up_rounded, color: AppTheme.forest),
              const SizedBox(width: 12),
              Text(
                "ESCUCHAR TONO",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.forest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
