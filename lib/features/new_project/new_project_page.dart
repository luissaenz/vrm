import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/header.dart';
import '../../shared/widgets/step_indicator.dart';
import '../../shared/widgets/script_editor.dart';
import '../fragments/fragment_organization_page.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../onboarding/data/onboarding_repository.dart';
import './models/script_analysis.dart';

class NewProjectPage extends StatefulWidget {
  const NewProjectPage({super.key});

  @override
  State<NewProjectPage> createState() => _NewProjectPageState();
}

class _NewProjectPageState extends State<NewProjectPage> {
  final TextEditingController _scriptController = TextEditingController();
  final OnboardingRepository _repository = OnboardingRepository();
  bool _isLoading = false;

  // Parámetros de ritmo dinámicos
  double _segmentMinTime = 3.0;
  double _segmentMaxTime = 10.0;
  double _segmentRateWpm = 160.0;

  @override
  void initState() {
    super.initState();
    _scriptController.addListener(() => setState(() {}));
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final profile = await _repository.getUserProfile();
    if (mounted) {
      setState(() {
        _segmentMinTime = profile.segmentMinTime;
        _segmentMaxTime = profile.segmentMaxTime;
        _segmentRateWpm = profile.segmentRateWpm;
      });
    }
  }

  @override
  void dispose() {
    _scriptController.dispose();
    super.dispose();
  }

  Future<void> _optimizeScript() async {
    if (_scriptController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Obtener la identidad del usuario
      final profile = await _repository.getUserProfile();
      final profileId = ApiService.mapIdentityToProfileId(profile.identity);

      // 2. Llamar al backend
      final response = await ApiService.callPrompt(
        category: 'tasks',
        name: 'SCRIPT_ANALYZER',
        payload: {
          "profile_id": profileId,
          "SCRIPT": _scriptController.text,
          "segment_minTime": _segmentMinTime,
          "segment_maxTime": _segmentMaxTime,
          "segment_RateWpm": _segmentRateWpm,
          "send_to_ai": true,
        },
      );

      // 3. Procesar respuesta
      if (response['ai_response'] != null &&
          response['ai_response']['content'] != null) {
        final analysisJson = response['ai_response']['content'];
        // Tip: El backend a veces devuelve el JSON como string, lo parseamos
        final decodedAnalysis = analysisJson is String
            ? Map<String, dynamic>.from(jsonDecode(analysisJson))
            : Map<String, dynamic>.from(analysisJson);

        final analysis = ScriptAnalysis.fromJson(decodedAnalysis);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FragmentOrganizationPage(analysis: analysis),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al optimizar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
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
                        VRMStepIndicator(
                          stepNumber: '1',
                          title: l10n.step1Title,
                        ),
                        const SizedBox(height: 20),
                        _buildScriptInput(l10n),
                        const SizedBox(height: 16),
                        _buildStatsRow(l10n),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.forest),
                    SizedBox(height: 16),
                    Text(
                      "Optimizando con IA...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
          onPressed: _scriptController.text.trim().isEmpty || _isLoading
              ? null
              : () => _optimizeScript(),
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
        onPressed: _isLoading ? () {} : () => _optimizeScript(),
        icon: Icons.auto_awesome,
        label: _isLoading ? "Cargando..." : "Optimizar",
        foregroundColor: AppTheme.forest,
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    final words = _scriptController.text
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;

    // Calculamos los segundos basados en el ritmo (WPM)
    // segundos = (palabras / WPM) * 60
    final seconds = (words / _segmentRateWpm * 60).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: "Velocidad "),
                TextSpan(
                  text: "${_segmentRateWpm.toInt()} ",
                  style: const TextStyle(color: AppTheme.forest),
                ),
                const TextSpan(text: "PPM"),
              ],
            ),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          if (_scriptController.text.trim().isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: "Estimación "),
                      TextSpan(
                        text: "$seconds S",
                        style: const TextStyle(color: AppTheme.forest),
                      ),
                      const TextSpan(text: " (±5%)"),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
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
