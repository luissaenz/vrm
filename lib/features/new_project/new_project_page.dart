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
import '../../shared/widgets/widget_progress.dart';

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
            WidgetProgress(
              title: "Dividiendo en fragmentos",
              subtitle: "El agente IA está procesando el guión.",
              description:
                  "Dividir el guión en bloques facilitará la retencion de los mismos mejorando la expresividad y la calidad del video generado.",
              progress:
                  0.0, // Podemos hacerlo dinámico si el backend enviara progreso
              duration: const Duration(seconds: 40),
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
        VRMScriptEditor.actionIcon(
          onPressed: () {},
          icon: Icons.mic_none_outlined,
        ),
      ],
      trailing: VRMScriptEditor.actionButton(
        onPressed: _isLoading ? () {} : () => _optimizeScript(),
        icon: Icons.auto_awesome,
        label: _isLoading ? "Cargando..." : "Asistente AI",
        foregroundColor: AppTheme.forest,
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    final words = _scriptController.text
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;

    final seconds = (words / _segmentRateWpm * 60).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatBadge(
            icon: Icons.speed_rounded,
            label: "Velocidad",
            value: "${_segmentRateWpm.toInt()} ppm",
          ),
          if (_scriptController.text.trim().isNotEmpty)
            _buildStatBadge(
              icon: Icons.access_time_rounded,
              label: "Estimación",
              value: "$seconds s",
              extra: "(±5%)",
            ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    String? extra,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Slate 50
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFF1F5F9), // Slate 100
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF334155), // Slate 700
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B), // Slate 800
              letterSpacing: -0.2,
            ),
          ),
          if (extra != null) ...[
            const SizedBox(width: 4),
            Text(
              extra,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B), // Slate 500
              ),
            ),
          ],
        ],
      ),
    );
  }
}
